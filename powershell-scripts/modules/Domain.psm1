# Domain.psm1
# ドメイン参加・PC名設定モジュール
# UTF-8 BOM付きで保存

<#
.SYNOPSIS
    ドメイン参加とPC名設定を行うモジュールです。

.DESCRIPTION
    PC名の設定、ODJファイルのダウンロード・適用、ドメイン参加確認を行います。
#>

# モジュールのインポート
$ModulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Join-Path -Path $ModulePath -ChildPath "Logger.psm1") -Force
Import-Module (Join-Path -Path $ModulePath -ChildPath "API.psm1") -Force

<#
.SYNOPSIS
    PC名の形式を検証します。

.DESCRIPTION
    YYYYMMDDM形式（例: 20251116M）であることを確認します。

.PARAMETER PCName
    検証するPC名

.EXAMPLE
    Test-PCNameFormat -PCName "20251116M"

.OUTPUTS
    Boolean - 形式が正しい場合はTrue、不正な場合はFalse
#>
function Test-PCNameFormat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PCName
    )

    try {
        # YYYYMMDDM形式の正規表現チェック
        # YYYY: 2000-2099
        # MM: 01-12
        # DD: 01-31
        # M: 固定サフィックス
        $pattern = '^20\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])M$'

        if ($PCName -match $pattern) {
            Write-SetupLog "PC名の形式チェックOK: $PCName" -Level INFO
            return $true
        }
        else {
            Write-SetupLog "PC名の形式が不正です: $PCName（期待形式: YYYYMMDDM）" -Level ERROR
            return $false
        }
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Test-PCNameFormat"
        return $false
    }
}

<#
.SYNOPSIS
    PC名を設定します。

.DESCRIPTION
    Rename-Computerコマンドレットを使用してPC名を変更します。
    変更後は再起動が必要です。

.PARAMETER NewName
    新しいPC名（YYYYMMDDM形式）

.PARAMETER Force
    確認なしで実行する場合に指定

.EXAMPLE
    Set-PCName -NewName "20251116M" -Force

.OUTPUTS
    Boolean - 設定成功時はTrue、失敗時はFalse
#>
function Set-PCName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$NewName,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    try {
        Write-SetupLog "PC名を設定します: $NewName" -Level INFO

        # PC名形式の検証
        if (-not (Test-PCNameFormat -PCName $NewName)) {
            Write-SetupLog "PC名の形式が不正なため、設定を中止します" -Level ERROR
            return $false
        }

        # 現在のPC名を取得
        $currentName = $env:COMPUTERNAME
        Write-SetupLog "現在のPC名: $currentName" -Level INFO

        # 既に設定されている場合はスキップ
        if ($currentName -eq $NewName) {
            Write-SetupLog "PC名は既に設定されています: $NewName" -Level INFO
            return $true
        }

        # PC名の変更
        Write-SetupLog "PC名を変更しています: $currentName → $NewName" -Level INFO

        if ($Force) {
            Rename-Computer -NewName $NewName -Force -ErrorAction Stop
        }
        else {
            Rename-Computer -NewName $NewName -ErrorAction Stop
        }

        Write-SetupLog "PC名の変更が完了しました（再起動が必要です）" -Level INFO
        return $true
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Set-PCName"
        return $false
    }
}

<#
.SYNOPSIS
    ODJファイルをダウンロードします。

.DESCRIPTION
    DRBL管理サーバーからODJファイルをダウンロードします。

.PARAMETER APIServer
    APIサーバーのURL（例: http://192.168.1.100:5000）

.PARAMETER ODJPath
    ODJファイルのサーバー側パス（例: /odj/20251116M.txt）

.PARAMETER LocalPath
    ダウンロード先のローカルパス（省略時は C:\Setup\odj.txt）

.EXAMPLE
    Get-ODJFile -APIServer "http://192.168.1.100:5000" -ODJPath "/odj/20251116M.txt"

.OUTPUTS
    String - ダウンロードしたファイルのパス（失敗時は空文字列）
#>
function Get-ODJFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$APIServer,

        [Parameter(Mandatory = $true)]
        [string]$ODJPath,

        [Parameter(Mandatory = $false)]
        [string]$LocalPath = "C:\Setup\odj.txt"
    )

    try {
        Write-SetupLog "ODJファイルをダウンロードします" -Level INFO
        Write-SetupLog "サーバー: $APIServer" -Level INFO
        Write-SetupLog "リモートパス: $ODJPath" -Level INFO
        Write-SetupLog "ローカルパス: $LocalPath" -Level INFO

        # ダウンロード実行
        $result = Download-FileFromAPI -APIServer $APIServer -FilePath $ODJPath -Destination $LocalPath

        if ($result) {
            # ファイルの存在確認
            if (Test-Path -Path $LocalPath) {
                Write-SetupLog "ODJファイルのダウンロードが完了しました: $LocalPath" -Level INFO
                return $LocalPath
            }
            else {
                Write-SetupLog "ODJファイルが見つかりません: $LocalPath" -Level ERROR
                return ""
            }
        }
        else {
            Write-SetupLog "ODJファイルのダウンロードに失敗しました" -Level ERROR
            return ""
        }
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Get-ODJFile"
        return ""
    }
}

<#
.SYNOPSIS
    ODJファイルを適用してドメインに参加します。

.DESCRIPTION
    djoin.exeコマンドを使用してODJファイルを適用します。
    適用後は再起動が必要です。

.PARAMETER ODJFilePath
    ODJファイルのパス

.EXAMPLE
    Apply-ODJ -ODJFilePath "C:\Setup\odj.txt"

.OUTPUTS
    Boolean - 適用成功時はTrue、失敗時はFalse
#>
function Apply-ODJ {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ODJFilePath
    )

    try {
        Write-SetupLog "ODJファイルを適用します: $ODJFilePath" -Level INFO

        # ファイルの存在確認
        if (-not (Test-Path -Path $ODJFilePath)) {
            Write-SetupLog "ODJファイルが見つかりません: $ODJFilePath" -Level ERROR
            return $false
        }

        # djoin.exeのパス
        $djoinPath = "$env:SystemRoot\System32\djoin.exe"

        if (-not (Test-Path -Path $djoinPath)) {
            Write-SetupLog "djoin.exeが見つかりません: $djoinPath" -Level ERROR
            return $false
        }

        # djoinコマンドの実行
        Write-SetupLog "djoinコマンドを実行します..." -Level INFO

        $djoinArgs = "/requestODJ /loadfile `"$ODJFilePath`" /windowspath $env:SystemRoot /localos"

        Write-SetupLog "コマンド: $djoinPath $djoinArgs" -Level DEBUG

        $process = Start-Process -FilePath $djoinPath -ArgumentList $djoinArgs -Wait -NoNewWindow -PassThru

        # 終了コードの確認
        if ($process.ExitCode -eq 0) {
            Write-SetupLog "ODJファイルの適用が完了しました（再起動が必要です）" -Level INFO
            return $true
        }
        else {
            Write-SetupLog "ODJファイルの適用に失敗しました（終了コード: $($process.ExitCode)）" -Level ERROR

            # Windowsイベントログに記録
            Write-EventLog -LogName Application -Source "Setup Script" -EntryType Error -EventId 1001 -Message "ODJ適用失敗: 終了コード $($process.ExitCode)" -ErrorAction SilentlyContinue

            return $false
        }
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Apply-ODJ"

        # Windowsイベントログに記録
        Write-EventLog -LogName Application -Source "Setup Script" -EntryType Error -EventId 1002 -Message "ODJ適用エラー: $($_.Exception.Message)" -ErrorAction SilentlyContinue

        return $false
    }
}

<#
.SYNOPSIS
    ドメイン参加状態を確認します。

.DESCRIPTION
    コンピュータがドメインに参加しているかを確認します。

.EXAMPLE
    $joined = Test-DomainJoin
    if ($joined) {
        Write-Host "ドメインに参加しています"
    }

.OUTPUTS
    Boolean - ドメイン参加済みの場合はTrue、未参加の場合はFalse
#>
function Test-DomainJoin {
    [CmdletBinding()]
    param()

    try {
        Write-SetupLog "ドメイン参加状態を確認しています..." -Level INFO

        $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop

        if ($cs.PartOfDomain) {
            Write-SetupLog "ドメインに参加しています: $($cs.Domain)" -Level INFO
            return $true
        }
        else {
            Write-SetupLog "ドメインに参加していません（ワークグループ: $($cs.Domain)）" -Level INFO
            return $false
        }
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Test-DomainJoin"
        return $false
    }
}

<#
.SYNOPSIS
    ドメイン情報を取得します。

.DESCRIPTION
    現在のドメイン参加状態と詳細情報を取得します。

.EXAMPLE
    $domainInfo = Get-DomainInfo
    Write-Host "ドメイン: $($domainInfo.Domain)"
    Write-Host "参加状態: $($domainInfo.PartOfDomain)"

.OUTPUTS
    PSCustomObject - ドメイン情報
#>
function Get-DomainInfo {
    [CmdletBinding()]
    param()

    try {
        Write-SetupLog "ドメイン情報を取得しています..." -Level INFO

        $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop

        $domainInfo = [PSCustomObject]@{
            ComputerName = $cs.Name
            Domain       = $cs.Domain
            PartOfDomain = $cs.PartOfDomain
            Workgroup    = if (-not $cs.PartOfDomain) { $cs.Domain } else { "" }
        }

        Write-SetupLog "ドメイン情報を取得しました: $($domainInfo.Domain) (参加状態: $($domainInfo.PartOfDomain))" -Level INFO
        return $domainInfo
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Get-DomainInfo"
        return $null
    }
}

<#
.SYNOPSIS
    Windowsイベントログソースを作成します。

.DESCRIPTION
    Setup Script用のイベントログソースを作成します（管理者権限が必要）。

.EXAMPLE
    Initialize-EventLogSource
#>
function Initialize-EventLogSource {
    [CmdletBinding()]
    param()

    try {
        $sourceName = "Setup Script"

        if (-not [System.Diagnostics.EventLog]::SourceExists($sourceName)) {
            New-EventLog -LogName Application -Source $sourceName -ErrorAction Stop
            Write-SetupLog "イベントログソースを作成しました: $sourceName" -Level INFO
        }
    }
    catch {
        Write-SetupLog "イベントログソースの作成に失敗しました: $_" -Level WARNING
    }
}

# エクスポート
Export-ModuleMember -Function @(
    'Test-PCNameFormat',
    'Set-PCName',
    'Get-ODJFile',
    'Apply-ODJ',
    'Test-DomainJoin',
    'Get-DomainInfo',
    'Initialize-EventLogSource'
)
