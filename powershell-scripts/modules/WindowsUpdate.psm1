# WindowsUpdate.psm1
# Windows Update実行モジュール
# UTF-8 BOM付きで保存

<#
.SYNOPSIS
    Windows Updateを自動実行するモジュールです。

.DESCRIPTION
    PSWindowsUpdateモジュールを使用してWindows Updateを実行します。
    更新がなくなるまで最大5回ループします。
#>

# モジュールのインポート
$ModulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Join-Path -Path $ModulePath -ChildPath "Logger.psm1") -Force

<#
.SYNOPSIS
    PSWindowsUpdateモジュールをインストールします。

.DESCRIPTION
    PSWindowsUpdateモジュールがインストールされていない場合はインストールします。

.EXAMPLE
    Install-PSWindowsUpdateModule

.OUTPUTS
    Boolean - インストール成功時はTrue、失敗時はFalse
#>
function Install-PSWindowsUpdateModule {
    [CmdletBinding()]
    param()

    try {
        Write-SetupLog "PSWindowsUpdateモジュールの確認中..." -Level INFO

        # モジュールの確認
        $module = Get-Module -Name PSWindowsUpdate -ListAvailable

        if ($module) {
            Write-SetupLog "PSWindowsUpdateモジュールは既にインストールされています（バージョン: $($module.Version)）" -Level INFO
            return $true
        }

        Write-SetupLog "PSWindowsUpdateモジュールをインストールします..." -Level INFO

        # NuGetプロバイダーのインストール
        $nuget = Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue
        if (-not $nuget) {
            Write-SetupLog "NuGetプロバイダーをインストールします..." -Level INFO
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop | Out-Null
        }

        # PSGalleryの信頼
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue

        # PSWindowsUpdateモジュールのインストール
        Install-Module -Name PSWindowsUpdate -Force -AllowClobber -ErrorAction Stop

        Write-SetupLog "PSWindowsUpdateモジュールのインストールが完了しました" -Level INFO
        return $true
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Install-PSWindowsUpdateModule"
        return $false
    }
}

<#
.SYNOPSIS
    利用可能な更新プログラムの数を取得します。

.DESCRIPTION
    Windows Updateサービスに接続して、利用可能な更新プログラムの数を取得します。

.PARAMETER Category
    更新カテゴリ（Security, Critical, Definition等）

.EXAMPLE
    $count = Get-UpdateCount

.OUTPUTS
    Int - 利用可能な更新プログラムの数
#>
function Get-UpdateCount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$Category = @("Security Updates", "Critical Updates", "Definition Updates")
    )

    try {
        Write-SetupLog "利用可能な更新プログラムを確認しています..." -Level INFO

        # PSWindowsUpdateモジュールの確認
        if (-not (Get-Module -Name PSWindowsUpdate -ListAvailable)) {
            Write-SetupLog "PSWindowsUpdateモジュールがインストールされていません" -Level ERROR
            return -1
        }

        # モジュールのインポート
        Import-Module PSWindowsUpdate -ErrorAction Stop

        # 更新プログラムの取得
        $updates = Get-WindowsUpdate -MicrosoftUpdate -ErrorAction Stop

        if ($updates) {
            $count = ($updates | Measure-Object).Count
            Write-SetupLog "利用可能な更新プログラム: $count 件" -Level INFO
            return $count
        }
        else {
            Write-SetupLog "利用可能な更新プログラムはありません" -Level INFO
            return 0
        }
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Get-UpdateCount"
        return -1
    }
}

<#
.SYNOPSIS
    更新プログラムが必要かどうかを確認します。

.DESCRIPTION
    利用可能な更新プログラムがあるかどうかを確認します。

.EXAMPLE
    if (Test-UpdatesRequired) {
        Write-Host "更新プログラムがあります"
    }

.OUTPUTS
    Boolean - 更新が必要な場合はTrue、不要な場合はFalse
#>
function Test-UpdatesRequired {
    [CmdletBinding()]
    param()

    try {
        $count = Get-UpdateCount

        if ($count -gt 0) {
            Write-SetupLog "更新プログラムが必要です（$count 件）" -Level INFO
            return $true
        }
        else {
            Write-SetupLog "更新プログラムは必要ありません" -Level INFO
            return $false
        }
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Test-UpdatesRequired"
        return $false
    }
}

<#
.SYNOPSIS
    Windows Updateを実行します。

.DESCRIPTION
    PSWindowsUpdateモジュールを使用してWindows Updateを実行します。
    更新がなくなるまで最大5回ループします。

.PARAMETER MaxIterations
    最大実行回数（デフォルト: 5）

.PARAMETER Category
    更新カテゴリ（Security, Critical, Definition等）

.PARAMETER AutoReboot
    更新後に自動再起動する場合に指定

.EXAMPLE
    Install-WindowsUpdates -MaxIterations 5 -AutoReboot

.OUTPUTS
    Boolean - すべての更新が完了した場合はTrue、失敗または未完了の場合はFalse
#>
function Install-WindowsUpdates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$MaxIterations = 5,

        [Parameter(Mandatory = $false)]
        [string[]]$Category = @("Security Updates", "Critical Updates", "Definition Updates"),

        [Parameter(Mandatory = $false)]
        [switch]$AutoReboot
    )

    try {
        Write-SetupLog "==================== Windows Update開始 ====================" -Level INFO

        # PSWindowsUpdateモジュールのインストール
        if (-not (Install-PSWindowsUpdateModule)) {
            Write-SetupLog "PSWindowsUpdateモジュールのインストールに失敗しました" -Level ERROR
            return $false
        }

        # モジュールのインポート
        Import-Module PSWindowsUpdate -ErrorAction Stop

        $iteration = 0
        $totalUpdates = 0

        while ($iteration -lt $MaxIterations) {
            $iteration++

            Write-SetupLog "==================== 更新ループ $iteration/$MaxIterations ====================" -Level INFO

            # 更新プログラムの確認
            Write-SetupLog "更新プログラムを検索しています..." -Level INFO
            $updates = Get-WindowsUpdate -MicrosoftUpdate -ErrorAction Stop

            if (-not $updates -or ($updates | Measure-Object).Count -eq 0) {
                Write-SetupLog "更新プログラムはありません。Windows Updateが完了しました。" -Level INFO
                break
            }

            $updateCount = ($updates | Measure-Object).Count
            $totalUpdates += $updateCount

            Write-SetupLog "検出された更新プログラム: $updateCount 件" -Level INFO

            # 更新プログラムの一覧表示
            foreach ($update in $updates) {
                Write-SetupLog "  - $($update.Title)" -Level INFO
            }

            # 更新プログラムのインストール
            Write-SetupLog "更新プログラムをインストールしています..." -Level INFO

            try {
                if ($AutoReboot) {
                    Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot -ErrorAction Stop | Out-Null
                }
                else {
                    Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -ErrorAction Stop | Out-Null
                }

                Write-SetupLog "更新プログラムのインストールが完了しました" -Level INFO
            }
            catch {
                Write-ErrorLog -ErrorRecord $_ -Context "Install-WindowsUpdate (Iteration $iteration)"

                # 一部のエラーは無視して続行
                if ($_.Exception.Message -match "0x80240438") {
                    Write-SetupLog "更新プログラムが既にインストールされています" -Level WARNING
                }
                else {
                    Write-SetupLog "更新プログラムのインストール中にエラーが発生しました" -Level ERROR
                    return $false
                }
            }

            # 再起動が必要かチェック
            $rebootRequired = Test-RebootRequired

            if ($rebootRequired) {
                Write-SetupLog "再起動が必要です" -Level WARNING

                if ($AutoReboot) {
                    Write-SetupLog "自動再起動を実行します（60秒後）..." -Level WARNING
                    Start-Sleep -Seconds 10
                    Restart-Computer -Force
                    return $true
                }
                else {
                    Write-SetupLog "手動で再起動してください" -Level WARNING
                }
            }

            # 次のループまで待機
            if ($iteration -lt $MaxIterations) {
                Write-SetupLog "次の更新チェックまで30秒待機します..." -Level INFO
                Start-Sleep -Seconds 30
            }
        }

        Write-SetupLog "==================== Windows Update完了 ====================" -Level INFO
        Write-SetupLog "インストールした更新プログラム: 合計 $totalUpdates 件（$iteration 回のループ）" -Level INFO

        return $true
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Install-WindowsUpdates"
        return $false
    }
}

<#
.SYNOPSIS
    再起動が必要かどうかを確認します。

.DESCRIPTION
    Windows Updateにより再起動が必要かどうかを確認します。

.EXAMPLE
    if (Test-RebootRequired) {
        Write-Host "再起動が必要です"
    }

.OUTPUTS
    Boolean - 再起動が必要な場合はTrue、不要な場合はFalse
#>
function Test-RebootRequired {
    [CmdletBinding()]
    param()

    try {
        # レジストリキーの確認
        $rebootPending = $false

        # Component Based Servicing
        $cbsReboot = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing" -Name "RebootPending" -ErrorAction SilentlyContinue
        if ($cbsReboot) {
            $rebootPending = $true
        }

        # Windows Update
        $wuReboot = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "RebootRequired" -ErrorAction SilentlyContinue
        if ($wuReboot) {
            $rebootPending = $true
        }

        # Pending File Rename Operations
        $pendingFileRename = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue
        if ($pendingFileRename) {
            $rebootPending = $true
        }

        if ($rebootPending) {
            Write-SetupLog "再起動が必要です" -Level WARNING
        }
        else {
            Write-SetupLog "再起動は必要ありません" -Level INFO
        }

        return $rebootPending
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Test-RebootRequired"
        return $false
    }
}

<#
.SYNOPSIS
    Windows Updateの履歴を取得します。

.DESCRIPTION
    最近インストールされた更新プログラムの履歴を取得します。

.PARAMETER MaxRecords
    取得する最大レコード数（デフォルト: 20）

.EXAMPLE
    $history = Get-UpdateHistory -MaxRecords 10

.OUTPUTS
    Array - 更新履歴の配列
#>
function Get-UpdateHistory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$MaxRecords = 20
    )

    try {
        Write-SetupLog "Windows Update履歴を取得しています..." -Level INFO

        $session = New-Object -ComObject Microsoft.Update.Session
        $searcher = $session.CreateUpdateSearcher()
        $historyCount = $searcher.GetTotalHistoryCount()

        if ($historyCount -eq 0) {
            Write-SetupLog "Windows Update履歴はありません" -Level INFO
            return @()
        }

        $recordsToRetrieve = [Math]::Min($MaxRecords, $historyCount)
        $history = $searcher.QueryHistory(0, $recordsToRetrieve)

        $updateHistory = @()
        foreach ($item in $history) {
            $updateInfo = [PSCustomObject]@{
                Title          = $item.Title
                Date           = $item.Date
                Operation      = switch ($item.Operation) {
                    1 { "Installation" }
                    2 { "Uninstallation" }
                    3 { "Other" }
                    default { "Unknown" }
                }
                ResultCode     = switch ($item.ResultCode) {
                    1 { "InProgress" }
                    2 { "Succeeded" }
                    3 { "SucceededWithErrors" }
                    4 { "Failed" }
                    5 { "Aborted" }
                    default { "Unknown" }
                }
            }
            $updateHistory += $updateInfo
        }

        Write-SetupLog "Windows Update履歴を取得しました（$($updateHistory.Count) 件）" -Level INFO
        return $updateHistory
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Get-UpdateHistory"
        return @()
    }
}

# エクスポート
Export-ModuleMember -Function @(
    'Install-PSWindowsUpdateModule',
    'Get-UpdateCount',
    'Test-UpdatesRequired',
    'Install-WindowsUpdates',
    'Test-RebootRequired',
    'Get-UpdateHistory'
)
