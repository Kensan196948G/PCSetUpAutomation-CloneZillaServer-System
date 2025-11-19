# AppInstall.psm1
# アプリケーションインストールモジュール
# UTF-8 BOM付きで保存

<#
.SYNOPSIS
    会社標準アプリケーションのインストールを行うモジュールです。

.DESCRIPTION
    config.jsonで定義されたアプリケーションをサイレントインストールします。
#>

# モジュールのインポート
$ModulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Join-Path -Path $ModulePath -ChildPath "Logger.psm1") -Force

<#
.SYNOPSIS
    アプリケーションがインストール済みかを確認します。

.DESCRIPTION
    レジストリまたはインストールパスから、アプリケーションのインストール状態を確認します。

.PARAMETER AppName
    アプリケーション名

.PARAMETER CheckPath
    確認用のファイルパス（省略可）

.EXAMPLE
    Test-AppInstalled -AppName "Microsoft 365 Apps"

.OUTPUTS
    Boolean - インストール済みの場合はTrue、未インストールの場合はFalse
#>
function Test-AppInstalled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppName,

        [Parameter(Mandatory = $false)]
        [string]$CheckPath = ""
    )

    try {
        Write-SetupLog "アプリケーションのインストール状態を確認しています: $AppName" -Level INFO

        # ファイルパスによる確認
        if ($CheckPath -and (Test-Path -Path $CheckPath)) {
            Write-SetupLog "アプリケーションは既にインストールされています（パス確認）: $AppName" -Level INFO
            return $true
        }

        # レジストリによる確認（32bit/64bit両方）
        $registryPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )

        foreach ($path in $registryPaths) {
            $apps = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -like "*$AppName*" }

            if ($apps) {
                Write-SetupLog "アプリケーションは既にインストールされています（レジストリ確認）: $AppName" -Level INFO
                return $true
            }
        }

        Write-SetupLog "アプリケーションはインストールされていません: $AppName" -Level INFO
        return $false
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Test-AppInstalled"
        return $false
    }
}

<#
.SYNOPSIS
    単一のアプリケーションをインストールします。

.DESCRIPTION
    指定されたインストーラーを実行してアプリケーションをインストールします。

.PARAMETER AppName
    アプリケーション名

.PARAMETER InstallerPath
    インストーラーのパス

.PARAMETER Arguments
    インストーラーの引数

.PARAMETER Silent
    サイレントインストールを行うかどうか

.PARAMETER Timeout
    タイムアウト時間（秒、デフォルト: 1800 = 30分）

.EXAMPLE
    Install-Application -AppName "Microsoft 365 Apps" -InstallerPath "C:\Setup\Apps\setup.exe" -Arguments "/configure configuration.xml" -Silent

.OUTPUTS
    Boolean - インストール成功時はTrue、失敗時はFalse
#>
function Install-Application {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppName,

        [Parameter(Mandatory = $true)]
        [string]$InstallerPath,

        [Parameter(Mandatory = $false)]
        [string]$Arguments = "",

        [Parameter(Mandatory = $false)]
        [switch]$Silent,

        [Parameter(Mandatory = $false)]
        [int]$Timeout = 1800
    )

    try {
        Write-SetupLog "==================== アプリインストール開始 ====================" -Level INFO
        Write-SetupLog "アプリケーション: $AppName" -Level INFO
        Write-SetupLog "インストーラー: $InstallerPath" -Level INFO
        Write-SetupLog "引数: $Arguments" -Level INFO

        # インストーラーの存在確認
        if (-not (Test-Path -Path $InstallerPath)) {
            Write-SetupLog "インストーラーが見つかりません: $InstallerPath" -Level ERROR
            return $false
        }

        # インストール実行
        Write-SetupLog "インストールを開始します..." -Level INFO

        $processArgs = @{
            FilePath     = $InstallerPath
            Wait         = $true
            NoNewWindow  = $true
            PassThru     = $true
        }

        if ($Arguments) {
            $processArgs.ArgumentList = $Arguments
        }

        $process = Start-Process @processArgs

        # タイムアウト処理
        $process | Wait-Process -Timeout $Timeout -ErrorAction SilentlyContinue

        if (-not $process.HasExited) {
            Write-SetupLog "インストールがタイムアウトしました: $AppName" -Level ERROR
            $process | Stop-Process -Force
            return $false
        }

        # 終了コードの確認
        $exitCode = $process.ExitCode

        # 成功とみなす終了コード（0, 3010=再起動必要）
        if ($exitCode -eq 0 -or $exitCode -eq 3010) {
            Write-SetupLog "インストールが完了しました: $AppName（終了コード: $exitCode）" -Level INFO

            if ($exitCode -eq 3010) {
                Write-SetupLog "再起動が必要です" -Level WARNING
            }

            return $true
        }
        else {
            Write-SetupLog "インストールに失敗しました: $AppName（終了コード: $exitCode）" -Level ERROR
            return $false
        }
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Install-Application"
        return $false
    }
}

<#
.SYNOPSIS
    会社標準アプリケーションをまとめてインストールします。

.DESCRIPTION
    config.jsonで定義されたアプリケーション一覧を読み込み、順次インストールします。

.PARAMETER ConfigPath
    設定ファイル（config.json）のパス

.PARAMETER SkipInstalled
    既にインストール済みのアプリをスキップする場合に指定

.EXAMPLE
    Install-StandardApps -ConfigPath "C:\Setup\config\config.json" -SkipInstalled

.OUTPUTS
    PSCustomObject - インストール結果（成功数、失敗数、スキップ数）
#>
function Install-StandardApps {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,

        [Parameter(Mandatory = $false)]
        [switch]$SkipInstalled
    )

    try {
        Write-SetupLog "==================== 標準アプリインストール開始 ====================" -Level INFO

        # 設定ファイルの読み込み
        if (-not (Test-Path -Path $ConfigPath)) {
            Write-SetupLog "設定ファイルが見つかりません: $ConfigPath" -Level ERROR
            return $null
        }

        $config = Get-Content -Path $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json

        if (-not $config.apps -or -not $config.apps.install_list) {
            Write-SetupLog "設定ファイルにアプリケーション一覧が定義されていません" -Level ERROR
            return $null
        }

        $apps = $config.apps.install_list
        $totalApps = ($apps | Measure-Object).Count

        Write-SetupLog "インストール対象アプリケーション: $totalApps 件" -Level INFO

        # インストール結果の初期化
        $successCount = 0
        $failureCount = 0
        $skipCount = 0

        # 各アプリケーションのインストール
        foreach ($app in $apps) {
            Write-SetupLog "------------------------------------------------" -Level INFO

            $appName = $app.name
            $installer = $app.installer
            $args = $app.args
            $silent = $app.silent
            $checkPath = $app.check_path

            # インストール済みチェック
            if ($SkipInstalled -and (Test-AppInstalled -AppName $appName -CheckPath $checkPath)) {
                Write-SetupLog "スキップします（既にインストール済み）: $appName" -Level INFO
                $skipCount++
                continue
            }

            # インストール実行
            $result = Install-Application -AppName $appName -InstallerPath $installer -Arguments $args -Silent:$silent

            if ($result) {
                $successCount++
                Write-SetupLog "インストール成功: $appName" -Level INFO
            }
            else {
                $failureCount++
                Write-SetupLog "インストール失敗: $appName" -Level ERROR
            }
        }

        Write-SetupLog "==================== 標準アプリインストール完了 ====================" -Level INFO
        Write-SetupLog "成功: $successCount 件 / 失敗: $failureCount 件 / スキップ: $skipCount 件 / 合計: $totalApps 件" -Level INFO

        # 結果を返す
        $result = [PSCustomObject]@{
            Total   = $totalApps
            Success = $successCount
            Failure = $failureCount
            Skip    = $skipCount
        }

        return $result
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Install-StandardApps"
        return $null
    }
}

<#
.SYNOPSIS
    インストール済みアプリケーション一覧を取得します。

.DESCRIPTION
    レジストリから、インストール済みアプリケーションの一覧を取得します。

.EXAMPLE
    $apps = Get-InstalledApplications
    foreach ($app in $apps) {
        Write-Host "$($app.DisplayName) - $($app.Version)"
    }

.OUTPUTS
    Array - インストール済みアプリケーションの配列
#>
function Get-InstalledApplications {
    [CmdletBinding()]
    param()

    try {
        Write-SetupLog "インストール済みアプリケーション一覧を取得しています..." -Level INFO

        $registryPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )

        $apps = @()

        foreach ($path in $registryPaths) {
            $items = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName } |
                Select-Object DisplayName, DisplayVersion, Publisher, InstallDate

            $apps += $items
        }

        # 重複を除去
        $apps = $apps | Sort-Object -Property DisplayName -Unique

        Write-SetupLog "インストール済みアプリケーション: $($apps.Count) 件" -Level INFO
        return $apps
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Get-InstalledApplications"
        return @()
    }
}

<#
.SYNOPSIS
    インストール済みアプリケーションをログに出力します。

.DESCRIPTION
    Get-InstalledApplicationsで取得した情報を読みやすい形式でログに出力します。

.EXAMPLE
    Write-InstalledAppsLog
#>
function Write-InstalledAppsLog {
    [CmdletBinding()]
    param()

    try {
        $apps = Get-InstalledApplications

        if ($apps -and $apps.Count -gt 0) {
            Write-SetupLog "==================== インストール済みアプリケーション ====================" -Level INFO

            foreach ($app in $apps) {
                $version = if ($app.DisplayVersion) { $app.DisplayVersion } else { "不明" }
                $publisher = if ($app.Publisher) { $app.Publisher } else { "不明" }
                Write-SetupLog "$($app.DisplayName) (バージョン: $version, 発行元: $publisher)" -Level INFO
            }

            Write-SetupLog "========================================================================" -Level INFO
        }
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Write-InstalledAppsLog"
    }
}

<#
.SYNOPSIS
    MSIファイルをインストールします。

.DESCRIPTION
    msiexecを使用してMSIファイルをサイレントインストールします。

.PARAMETER MsiPath
    MSIファイルのパス

.PARAMETER Arguments
    追加の引数（省略可）

.EXAMPLE
    Install-MSI -MsiPath "C:\Setup\Apps\app.msi" -Arguments "INSTALLDIR=C:\Program Files\MyApp"

.OUTPUTS
    Boolean - インストール成功時はTrue、失敗時はFalse
#>
function Install-MSI {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MsiPath,

        [Parameter(Mandatory = $false)]
        [string]$Arguments = ""
    )

    try {
        Write-SetupLog "MSIファイルをインストールします: $MsiPath" -Level INFO

        # MSIファイルの存在確認
        if (-not (Test-Path -Path $MsiPath)) {
            Write-SetupLog "MSIファイルが見つかりません: $MsiPath" -Level ERROR
            return $false
        }

        # msiexecコマンドの構築
        $msiArgs = "/i `"$MsiPath`" /qn /norestart"

        if ($Arguments) {
            $msiArgs += " $Arguments"
        }

        Write-SetupLog "コマンド: msiexec.exe $msiArgs" -Level DEBUG

        # msiexec実行
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -NoNewWindow -PassThru

        # 終了コードの確認
        $exitCode = $process.ExitCode

        if ($exitCode -eq 0 -or $exitCode -eq 3010) {
            Write-SetupLog "MSIインストールが完了しました（終了コード: $exitCode）" -Level INFO
            return $true
        }
        else {
            Write-SetupLog "MSIインストールに失敗しました（終了コード: $exitCode）" -Level ERROR
            return $false
        }
    }
    catch {
        Write-ErrorLog -ErrorRecord $_ -Context "Install-MSI"
        return $false
    }
}

# エクスポート
Export-ModuleMember -Function @(
    'Test-AppInstalled',
    'Install-Application',
    'Install-StandardApps',
    'Get-InstalledApplications',
    'Write-InstalledAppsLog',
    'Install-MSI'
)
