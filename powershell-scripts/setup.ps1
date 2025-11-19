# setup.ps1
# Windows PC自動セットアップメインスクリプト
# UTF-8 BOM付きで保存

<#
.SYNOPSIS
    Windows PCの完全自動セットアップを実行します。

.DESCRIPTION
    Serial番号取得、API呼び出し、PC名設定、ODJ適用、Windows Update、アプリインストールを順次実行します。
    セットアップ進捗はレジストリで管理され、再起動後も処理を継続します。

.EXAMPLE
    .\setup.ps1

.NOTES
    - 管理者権限が必要です
    - 設定ファイル: C:\Setup\config\config.json
    - ログ出力先: C:\Setup\Logs\
#>

#Requires -RunAsAdministrator

# スクリプトのパス
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulePath = Join-Path -Path $ScriptPath -ChildPath "modules"
$ConfigPath = Join-Path -Path $ScriptPath -ChildPath "config\config.json"

# モジュールのインポート
Import-Module (Join-Path -Path $ModulePath -ChildPath "Logger.psm1") -Force
Import-Module (Join-Path -Path $ModulePath -ChildPath "PCInfo.psm1") -Force
Import-Module (Join-Path -Path $ModulePath -ChildPath "API.psm1") -Force
Import-Module (Join-Path -Path $ModulePath -ChildPath "Domain.psm1") -Force
Import-Module (Join-Path -Path $ModulePath -ChildPath "WindowsUpdate.psm1") -Force
Import-Module (Join-Path -Path $ModulePath -ChildPath "AppInstall.psm1") -Force

# レジストリパス（進捗管理用）
$RegistryPath = "HKLM:\SOFTWARE\CompanySetup"
$ProgressKey = "SetupProgress"
$SerialKey = "Serial"
$PCNameKey = "PCName"

# グローバル変数
$global:Config = $null
$global:APIServer = ""
$global:Serial = ""
$global:PCName = ""

<#
.SYNOPSIS
    管理者権限で実行されているかを確認します。
#>
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

<#
.SYNOPSIS
    設定ファイルを読み込みます。
#>
function Load-Configuration {
    param(
        [string]$Path = $ConfigPath
    )

    try {
        Write-SetupLog "設定ファイルを読み込んでいます: $Path" -Level INFO

        if (-not (Test-Path -Path $Path)) {
            Write-SetupLog "設定ファイルが見つかりません: $Path" -Level ERROR
            return $false
        }

        $global:Config = Get-Content -Path $Path -Raw -Encoding UTF8 | ConvertFrom-Json

        # API設定
        if ($global:Config.api -and $global:Config.api.server) {
            $global:APIServer = $global:Config.api.server
        }
        else {
            Write-SetupLog "設定ファイルにAPI設定がありません" -Level ERROR
            return $false
        }

        Write-SetupLog "設定ファイルの読み込みが完了しました" -Level INFO
        Write-SetupLog "APIサーバー: $global:APIServer" -Level INFO

        return $true
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Load-Configuration"
        return $false
    }
}

<#
.SYNOPSIS
    セットアップ進捗を取得します。
#>
function Get-SetupProgress {
    try {
        if (-not (Test-Path -Path $RegistryPath)) {
            return 0
        }

        $progress = Get-ItemProperty -Path $RegistryPath -Name $ProgressKey -ErrorAction SilentlyContinue

        if ($progress) {
            return $progress.$ProgressKey
        }

        return 0
    }
    catch {
        return 0
    }
}

<#
.SYNOPSIS
    セットアップ進捗を保存します。
#>
function Set-SetupProgress {
    param(
        [int]$Progress
    )

    try {
        if (-not (Test-Path -Path $RegistryPath)) {
            New-Item -Path $RegistryPath -Force | Out-Null
        }

        Set-ItemProperty -Path $RegistryPath -Name $ProgressKey -Value $Progress -Force
        Write-SetupLog "セットアップ進捗を保存しました: ステップ $Progress" -Level INFO
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Set-SetupProgress"
    }
}

<#
.SYNOPSIS
    レジストリから値を取得します。
#>
function Get-RegistryValue {
    param(
        [string]$Name
    )

    try {
        if (-not (Test-Path -Path $RegistryPath)) {
            return ""
        }

        $value = Get-ItemProperty -Path $RegistryPath -Name $Name -ErrorAction SilentlyContinue

        if ($value) {
            return $value.$Name
        }

        return ""
    }
    catch {
        return ""
    }
}

<#
.SYNOPSIS
    レジストリに値を保存します。
#>
function Set-RegistryValue {
    param(
        [string]$Name,
        [string]$Value
    )

    try {
        if (-not (Test-Path -Path $RegistryPath)) {
            New-Item -Path $RegistryPath -Force | Out-Null
        }

        Set-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -Force
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Set-RegistryValue"
    }
}

<#
.SYNOPSIS
    ステップ1: Serial番号取得
#>
function Step1-GetSerial {
    Write-SetupLog "==================== ステップ1: Serial番号取得 ====================" -Level INFO

    try {
        $serial = Get-SerialNumber

        if (-not $serial) {
            Write-SetupLog "Serial番号の取得に失敗しました" -Level ERROR
            Send-ErrorLog -Message "Serial番号取得失敗"
            return $false
        }

        $global:Serial = $serial
        Set-RegistryValue -Name $SerialKey -Value $serial

        Write-SetupLog "Serial番号: $serial" -Level INFO
        return $true
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Step1-GetSerial"
        return $false
    }
}

<#
.SYNOPSIS
    ステップ2: API呼び出し（PC名・ODJ取得）
#>
function Step2-GetPCInfo {
    Write-SetupLog "==================== ステップ2: PC情報取得 ====================" -Level INFO

    try {
        # APIサーバー接続確認
        if (-not (Test-APIConnection -APIServer $global:APIServer)) {
            Write-SetupLog "APIサーバーに接続できません: $global:APIServer" -Level ERROR
            Send-ErrorLog -Message "API接続失敗: $global:APIServer"
            return $false
        }

        # PC情報取得
        $pcInfo = Get-PCInfoFromAPI -APIServer $global:APIServer -Serial $global:Serial

        if (-not $pcInfo) {
            Write-SetupLog "PC情報の取得に失敗しました" -Level ERROR
            Send-ErrorLog -Message "PC情報取得失敗: Serial=$global:Serial"
            return $false
        }

        $global:PCName = $pcInfo.pcname
        Set-RegistryValue -Name $PCNameKey -Value $pcInfo.pcname
        Set-RegistryValue -Name "ODJPath" -Value $pcInfo.odj_path

        Write-SetupLog "PC名: $($pcInfo.pcname)" -Level INFO
        Write-SetupLog "ODJパス: $($pcInfo.odj_path)" -Level INFO

        return $true
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Step2-GetPCInfo"
        return $false
    }
}

<#
.SYNOPSIS
    ステップ3: PC名設定
#>
function Step3-SetPCName {
    Write-SetupLog "==================== ステップ3: PC名設定 ====================" -Level INFO

    try {
        $result = Set-PCName -NewName $global:PCName -Force

        if ($result) {
            Write-SetupLog "PC名の設定が完了しました" -Level INFO
            Send-ProgressLog -Status "pcname_set" -Message "PC名設定完了: $global:PCName"
            return $true
        }
        else {
            Write-SetupLog "PC名の設定に失敗しました" -Level ERROR
            Send-ErrorLog -Message "PC名設定失敗: $global:PCName"
            return $false
        }
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Step3-SetPCName"
        return $false
    }
}

<#
.SYNOPSIS
    ステップ4: ODJ適用
#>
function Step4-ApplyODJ {
    Write-SetupLog "==================== ステップ4: ODJ適用 ====================" -Level INFO

    try {
        $odjPath = Get-RegistryValue -Name "ODJPath"

        if (-not $odjPath) {
            Write-SetupLog "ODJパスが取得できません" -Level ERROR
            return $false
        }

        # ODJファイルダウンロード
        $localODJPath = "C:\Setup\odj.txt"
        $downloadResult = Get-ODJFile -APIServer $global:APIServer -ODJPath $odjPath -LocalPath $localODJPath

        if (-not $downloadResult) {
            Write-SetupLog "ODJファイルのダウンロードに失敗しました" -Level ERROR
            Send-ErrorLog -Message "ODJダウンロード失敗: $odjPath"
            return $false
        }

        # ODJ適用
        $result = Apply-ODJ -ODJFilePath $localODJPath

        if ($result) {
            Write-SetupLog "ODJの適用が完了しました" -Level INFO
            Send-ProgressLog -Status "odj_applied" -Message "ODJ適用完了"
            return $true
        }
        else {
            Write-SetupLog "ODJの適用に失敗しました" -Level ERROR
            Send-ErrorLog -Message "ODJ適用失敗"
            return $false
        }
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Step4-ApplyODJ"
        return $false
    }
}

<#
.SYNOPSIS
    ステップ5: 再起動（1回目）
#>
function Step5-Reboot1 {
    Write-SetupLog "==================== ステップ5: 再起動（1回目） ====================" -Level INFO

    try {
        Write-SetupLog "PC名とODJの適用のため、60秒後に再起動します..." -Level WARNING
        Start-Sleep -Seconds 10

        Restart-Computer -Force
        return $true
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Step5-Reboot1"
        return $false
    }
}

<#
.SYNOPSIS
    ステップ6: Windows Update
#>
function Step6-WindowsUpdate {
    Write-SetupLog "==================== ステップ6: Windows Update ====================" -Level INFO

    try {
        # Windows Update設定の取得
        $maxIterations = 5
        $autoReboot = $false

        if ($global:Config.windows_update) {
            if ($global:Config.windows_update.max_iterations) {
                $maxIterations = $global:Config.windows_update.max_iterations
            }
            if ($global:Config.windows_update.reboot_if_required) {
                $autoReboot = $global:Config.windows_update.reboot_if_required
            }
        }

        # Windows Update実行
        $result = Install-WindowsUpdates -MaxIterations $maxIterations -AutoReboot:$autoReboot

        if ($result) {
            Write-SetupLog "Windows Updateが完了しました" -Level INFO
            Send-ProgressLog -Status "windows_update_completed" -Message "Windows Update完了"
            return $true
        }
        else {
            Write-SetupLog "Windows Updateに失敗しました" -Level ERROR
            Send-ErrorLog -Message "Windows Update失敗"
            return $false
        }
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Step6-WindowsUpdate"
        return $false
    }
}

<#
.SYNOPSIS
    ステップ7: アプリインストール
#>
function Step7-InstallApps {
    Write-SetupLog "==================== ステップ7: アプリインストール ====================" -Level INFO

    try {
        $result = Install-StandardApps -ConfigPath $ConfigPath -SkipInstalled

        if ($result) {
            Write-SetupLog "アプリインストールが完了しました（成功: $($result.Success), 失敗: $($result.Failure), スキップ: $($result.Skip)）" -Level INFO
            Send-ProgressLog -Status "apps_installed" -Message "アプリインストール完了: 成功 $($result.Success) 件"
            return $true
        }
        else {
            Write-SetupLog "アプリインストールに失敗しました" -Level ERROR
            Send-ErrorLog -Message "アプリインストール失敗"
            return $false
        }
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Step7-InstallApps"
        return $false
    }
}

<#
.SYNOPSIS
    ステップ8: 完了ログ送信
#>
function Step8-SendCompletionLog {
    Write-SetupLog "==================== ステップ8: 完了ログ送信 ====================" -Level INFO

    try {
        Send-ProgressLog -Status "completed" -Message "セットアップが正常に完了しました"

        Write-SetupLog "セットアップが正常に完了しました！" -Level INFO
        return $true
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Step8-SendCompletionLog"
        return $false
    }
}

<#
.SYNOPSIS
    進捗ログをAPIに送信します。
#>
function Send-ProgressLog {
    param(
        [string]$Status,
        [string]$Message = ""
    )

    try {
        $logData = @{
            serial    = $global:Serial
            pcname    = $global:PCName
            status    = $Status
            timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            logs      = $Message
        }

        Send-SetupLog -APIServer $global:APIServer -LogData $logData | Out-Null
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Send-ProgressLog"
    }
}

<#
.SYNOPSIS
    エラーログをAPIに送信します。
#>
function Send-ErrorLog {
    param(
        [string]$Message
    )

    try {
        $logData = @{
            serial    = $global:Serial
            pcname    = $global:PCName
            status    = "error"
            timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            logs      = $Message
        }

        Send-SetupLog -APIServer $global:APIServer -LogData $logData | Out-Null
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Send-ErrorLog"
    }
}

<#
.SYNOPSIS
    セットアップのクリーンアップを実行します。
#>
function Cleanup-Setup {
    Write-SetupLog "==================== セットアップのクリーンアップ ====================" -Level INFO

    try {
        # レジストリキーの削除
        if (Test-Path -Path $RegistryPath) {
            Remove-Item -Path $RegistryPath -Recurse -Force
            Write-SetupLog "レジストリキーを削除しました" -Level INFO
        }

        # 一時ファイルの削除
        $tempFiles = @(
            "C:\Setup\odj.txt"
        )

        foreach ($file in $tempFiles) {
            if (Test-Path -Path $file) {
                Remove-Item -Path $file -Force
                Write-SetupLog "一時ファイルを削除しました: $file" -Level INFO
            }
        }

        Write-SetupLog "クリーンアップが完了しました" -Level INFO
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Cleanup-Setup"
    }
}

# ==================== メイン処理 ====================

try {
    # 管理者権限チェック
    if (-not (Test-Administrator)) {
        Write-Host "このスクリプトは管理者権限で実行してください" -ForegroundColor Red
        Exit 1
    }

    # トランスクリプト開始
    Start-SetupTranscript

    Write-SetupLog "==================== Windows PC自動セットアップ開始 ====================" -Level INFO
    Write-SetupLog "スクリプトバージョン: 1.0" -Level INFO
    Write-SetupLog "実行日時: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO

    # イベントログソースの初期化
    Initialize-EventLogSource

    # 設定ファイルの読み込み
    if (-not (Load-Configuration)) {
        Write-SetupLog "設定ファイルの読み込みに失敗しました。セットアップを中止します。" -Level ERROR
        Exit 1
    }

    # ログ設定の適用
    Set-LogConfiguration -ConfigPath $ConfigPath

    # システム情報のログ出力
    Write-SystemInfoLog

    # 進捗の取得
    $currentProgress = Get-SetupProgress

    # レジストリから保存済み情報を復元
    if ($currentProgress -gt 0) {
        $global:Serial = Get-RegistryValue -Name $SerialKey
        $global:PCName = Get-RegistryValue -Name $PCNameKey

        Write-SetupLog "セットアップを再開します（ステップ: $currentProgress）" -Level INFO
        Write-SetupLog "Serial: $global:Serial" -Level INFO
        Write-SetupLog "PC名: $global:PCName" -Level INFO
    }

    # ステップ実行
    switch ($currentProgress) {
        0 {
            # ステップ1: Serial番号取得
            if (-not (Step1-GetSerial)) {
                Write-SetupLog "セットアップを中止します（ステップ1失敗）" -Level ERROR
                Exit 1
            }
            Set-SetupProgress -Progress 1
        }
    }

    if ($currentProgress -le 1) {
        # ステップ2: PC情報取得
        if (-not (Step2-GetPCInfo)) {
            Write-SetupLog "セットアップを中止します（ステップ2失敗）" -Level ERROR
            Exit 1
        }
        Set-SetupProgress -Progress 2
    }

    if ($currentProgress -le 2) {
        # ステップ3: PC名設定
        if (-not (Step3-SetPCName)) {
            Write-SetupLog "セットアップを中止します（ステップ3失敗）" -Level ERROR
            Exit 1
        }
        Set-SetupProgress -Progress 3
    }

    if ($currentProgress -le 3) {
        # ステップ4: ODJ適用
        if (-not (Step4-ApplyODJ)) {
            Write-SetupLog "セットアップを中止します（ステップ4失敗）" -Level ERROR
            Exit 1
        }
        Set-SetupProgress -Progress 4
    }

    if ($currentProgress -le 4) {
        # ステップ5: 再起動
        Set-SetupProgress -Progress 5
        Step5-Reboot1
        Exit 0
    }

    if ($currentProgress -le 5) {
        # ステップ6: Windows Update
        if (-not (Step6-WindowsUpdate)) {
            Write-SetupLog "Windows Updateに失敗しましたが、続行します" -Level WARNING
        }
        Set-SetupProgress -Progress 6
    }

    if ($currentProgress -le 6) {
        # ステップ7: アプリインストール
        if (-not (Step7-InstallApps)) {
            Write-SetupLog "アプリインストールに失敗しましたが、続行します" -Level WARNING
        }
        Set-SetupProgress -Progress 7
    }

    if ($currentProgress -le 7) {
        # ステップ8: 完了ログ送信
        Step8-SendCompletionLog
        Set-SetupProgress -Progress 8
    }

    # クリーンアップ
    Cleanup-Setup

    Write-SetupLog "==================== セットアップ完了 ====================" -Level INFO

    # インストール済みアプリのログ出力
    Write-InstalledAppsLog

    # ドメイン情報のログ出力
    $domainInfo = Get-DomainInfo
    if ($domainInfo) {
        Write-SetupLog "ドメイン参加状態: $($domainInfo.PartOfDomain)" -Level INFO
        Write-SetupLog "ドメイン: $($domainInfo.Domain)" -Level INFO
    }

    # トランスクリプト停止
    Stop-SetupTranscript

    Exit 0
}
catch {
    Write-ErrorLog -ErrorRecord $_ -Context "Main"
    Write-SetupLog "致命的なエラーが発生しました。セットアップを中止します。" -Level ERROR
    Send-ErrorLog -Message "致命的エラー: $($_.Exception.Message)"

    Stop-SetupTranscript
    Exit 1
}
