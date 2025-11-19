# Logger.psm1
# 共通ログ機能モジュール
# UTF-8 BOM付きで保存

<#
.SYNOPSIS
    セットアップスクリプト用の共通ログ機能を提供します。

.DESCRIPTION
    ログファイルへの書き込み、トランスクリプト管理、ログレベル管理を行います。
    すべてのログは C:\Setup\Logs に出力されます。
#>

# グローバル変数
$script:LogPath = "C:\Setup\Logs"
$script:LogLevel = "INFO"
$script:MaxLogSizeMB = 10

<#
.SYNOPSIS
    ログディレクトリを初期化します。

.DESCRIPTION
    ログ出力先ディレクトリが存在しない場合は作成します。

.PARAMETER Path
    ログディレクトリのパス（デフォルト: C:\Setup\Logs）
#>
function Initialize-LogDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = "C:\Setup\Logs"
    )

    try {
        if (-not (Test-Path -Path $Path)) {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
            Write-Host "ログディレクトリを作成しました: $Path" -ForegroundColor Green
        }
        $script:LogPath = $Path
        return $true
    }
    catch {
        Write-Error "ログディレクトリの作成に失敗しました: $_"
        return $false
    }
}

<#
.SYNOPSIS
    ログファイルに書き込みます。

.DESCRIPTION
    指定されたメッセージをログファイルに書き込みます。
    フォーマット: [YYYY-MM-DD HH:MM:SS] [LEVEL] Message

.PARAMETER Message
    ログメッセージ

.PARAMETER Level
    ログレベル（INFO, WARNING, ERROR, DEBUG）

.PARAMETER NoConsole
    コンソール出力を抑制する場合に指定

.EXAMPLE
    Write-SetupLog "セットアップを開始します" -Level INFO

.EXAMPLE
    Write-SetupLog "API接続に失敗しました" -Level ERROR
#>
function Write-SetupLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO",

        [Parameter(Mandatory = $false)]
        [switch]$NoConsole
    )

    try {
        # ログディレクトリの確認
        if (-not (Test-Path -Path $script:LogPath)) {
            Initialize-LogDirectory -Path $script:LogPath | Out-Null
        }

        # ログファイル名（日付ベース）
        $LogFileName = "setup-$(Get-Date -Format 'yyyyMMdd').log"
        $LogFilePath = Join-Path -Path $script:LogPath -ChildPath $LogFileName

        # タイムスタンプ
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # ログメッセージのフォーマット
        $LogMessage = "[$Timestamp] [$Level] $Message"

        # ファイルへ書き込み
        Add-Content -Path $LogFilePath -Value $LogMessage -Encoding UTF8

        # コンソール出力
        if (-not $NoConsole) {
            switch ($Level) {
                "INFO"    { Write-Host $LogMessage -ForegroundColor Cyan }
                "WARNING" { Write-Host $LogMessage -ForegroundColor Yellow }
                "ERROR"   { Write-Host $LogMessage -ForegroundColor Red }
                "DEBUG"   { Write-Host $LogMessage -ForegroundColor Gray }
            }
        }

        # ログファイルサイズチェック
        Test-LogFileSize -LogFilePath $LogFilePath
    }
    catch {
        Write-Error "ログ書き込みに失敗しました: $_"
    }
}

<#
.SYNOPSIS
    ログファイルのサイズをチェックし、必要に応じてローテーションします。

.PARAMETER LogFilePath
    チェック対象のログファイルパス
#>
function Test-LogFileSize {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogFilePath
    )

    try {
        if (Test-Path -Path $LogFilePath) {
            $LogFile = Get-Item -Path $LogFilePath
            $LogSizeMB = $LogFile.Length / 1MB

            if ($LogSizeMB -gt $script:MaxLogSizeMB) {
                $ArchiveName = "$($LogFile.BaseName)-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
                $ArchivePath = Join-Path -Path $script:LogPath -ChildPath $ArchiveName
                Move-Item -Path $LogFilePath -Destination $ArchivePath -Force
                Write-SetupLog "ログファイルをアーカイブしました: $ArchiveName" -Level INFO
            }
        }
    }
    catch {
        Write-Error "ログファイルサイズチェックに失敗しました: $_"
    }
}

<#
.SYNOPSIS
    PowerShellトランスクリプトを開始します。

.DESCRIPTION
    すべてのPowerShellコマンドと出力を記録します。

.PARAMETER TranscriptPath
    トランスクリプトファイルのパス（省略可）

.EXAMPLE
    Start-SetupTranscript
#>
function Start-SetupTranscript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$TranscriptPath
    )

    try {
        # ログディレクトリの確認
        if (-not (Test-Path -Path $script:LogPath)) {
            Initialize-LogDirectory -Path $script:LogPath | Out-Null
        }

        # トランスクリプトパスの設定
        if (-not $TranscriptPath) {
            $TranscriptFileName = "transcript-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
            $TranscriptPath = Join-Path -Path $script:LogPath -ChildPath $TranscriptFileName
        }

        # トランスクリプト開始
        Start-Transcript -Path $TranscriptPath -Force
        Write-SetupLog "トランスクリプトを開始しました: $TranscriptPath" -Level INFO
        return $TranscriptPath
    }
    catch {
        Write-SetupLog "トランスクリプトの開始に失敗しました: $_" -Level ERROR
        return $null
    }
}

<#
.SYNOPSIS
    PowerShellトランスクリプトを停止します。

.EXAMPLE
    Stop-SetupTranscript
#>
function Stop-SetupTranscript {
    [CmdletBinding()]
    param()

    try {
        Stop-Transcript
        Write-SetupLog "トランスクリプトを停止しました" -Level INFO
    }
    catch {
        Write-SetupLog "トランスクリプトの停止に失敗しました: $_" -Level ERROR
    }
}

<#
.SYNOPSIS
    ログ設定を読み込みます。

.PARAMETER ConfigPath
    設定ファイル（config.json）のパス

.EXAMPLE
    Set-LogConfiguration -ConfigPath "C:\Setup\config\config.json"
#>
function Set-LogConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    try {
        if (-not (Test-Path -Path $ConfigPath)) {
            Write-SetupLog "設定ファイルが見つかりません: $ConfigPath" -Level WARNING
            return $false
        }

        $Config = Get-Content -Path $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json

        if ($Config.logging) {
            if ($Config.logging.path) {
                $script:LogPath = $Config.logging.path
                Initialize-LogDirectory -Path $script:LogPath | Out-Null
            }
            if ($Config.logging.level) {
                $script:LogLevel = $Config.logging.level
            }
            if ($Config.logging.max_size_mb) {
                $script:MaxLogSizeMB = $Config.logging.max_size_mb
            }
        }

        Write-SetupLog "ログ設定を読み込みました: Path=$script:LogPath, Level=$script:LogLevel" -Level INFO
        return $true
    }
    catch {
        Write-SetupLog "ログ設定の読み込みに失敗しました: $_" -Level ERROR
        return $false
    }
}

<#
.SYNOPSIS
    エラー情報を詳細にログ出力します。

.PARAMETER ErrorRecord
    エラーレコード（$_ または $Error[0]）

.PARAMETER Context
    エラーが発生したコンテキスト（関数名等）

.EXAMPLE
    Write-ErrorLog -ErrorRecord $_ -Context "Get-PCInfoFromAPI"
#>
function Write-ErrorLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Mandatory = $false)]
        [string]$Context = "Unknown"
    )

    try {
        $ErrorMessage = @"
エラーが発生しました
コンテキスト: $Context
エラーメッセージ: $($ErrorRecord.Exception.Message)
スクリプト行: $($ErrorRecord.InvocationInfo.ScriptLineNumber)
スクリプト名: $($ErrorRecord.InvocationInfo.ScriptName)
コマンド: $($ErrorRecord.InvocationInfo.Line.Trim())
スタックトレース: $($ErrorRecord.ScriptStackTrace)
"@

        Write-SetupLog $ErrorMessage -Level ERROR
    }
    catch {
        Write-Error "エラーログの出力に失敗しました: $_"
    }
}

# エクスポート
Export-ModuleMember -Function @(
    'Initialize-LogDirectory',
    'Write-SetupLog',
    'Start-SetupTranscript',
    'Stop-SetupTranscript',
    'Set-LogConfiguration',
    'Write-ErrorLog'
)
