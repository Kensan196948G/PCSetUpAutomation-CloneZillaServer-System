# API.psm1
# REST API通信モジュール
# UTF-8 BOM付きで保存

<#
.SYNOPSIS
    DRBL管理サーバーとのREST API通信を行うモジュールです。

.DESCRIPTION
    PC情報の取得、ログ送信、API接続確認等の機能を提供します。
#>

# Logger モジュールのインポート
$ModulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Join-Path -Path $ModulePath -ChildPath "Logger.psm1") -Force

<#
.SYNOPSIS
    API接続をテストします。

.DESCRIPTION
    指定されたAPIサーバーへの接続確認を行います。

.PARAMETER APIServer
    APIサーバーのURL（例: http://192.168.1.100:5000）

.PARAMETER Timeout
    タイムアウト時間（秒）

.EXAMPLE
    Test-APIConnection -APIServer "http://192.168.1.100:5000"

.OUTPUTS
    Boolean - 接続成功時はTrue、失敗時はFalse
#>
function Test-APIConnection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$APIServer,

        [Parameter(Mandatory = $false)]
        [int]$Timeout = 10
    )

    try {
        Write-SetupLog "API接続をテストしています: $APIServer" -Level INFO

        $testUrl = "$APIServer/api/health"

        # TLS 1.2を有効化
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        $response = Invoke-RestMethod -Uri $testUrl -Method Get -TimeoutSec $Timeout -ErrorAction Stop

        Write-SetupLog "API接続テスト成功: $APIServer" -Level INFO
        return $true
    }
    catch [System.Net.WebException] {
        Write-SetupLog "API接続テスト失敗（ネットワークエラー）: $($_.Exception.Message)" -Level ERROR
        return $false
    }
    catch {
        # /api/health エンドポイントが存在しない場合でも、サーバーが応答すればOK
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-SetupLog "API接続テスト成功（サーバー応答確認）: $APIServer" -Level INFO
            return $true
        }

        Write-ErrorLog -ErrorRecord $_ -Context "Test-APIConnection"
        return $false
    }
}

<#
.SYNOPSIS
    APIからPC情報を取得します。

.DESCRIPTION
    Serial番号をキーに、PC名とODJファイルパスを取得します。
    失敗時は指定回数リトライします。

.PARAMETER APIServer
    APIサーバーのURL（例: http://192.168.1.100:5000）

.PARAMETER Serial
    PCのSerial番号

.PARAMETER RetryCount
    リトライ回数（デフォルト: 3）

.PARAMETER RetryDelay
    リトライ間隔（秒、デフォルト: 5）

.PARAMETER Timeout
    タイムアウト時間（秒、デフォルト: 30）

.EXAMPLE
    $pcInfo = Get-PCInfoFromAPI -APIServer "http://192.168.1.100:5000" -Serial "ABC123456"
    if ($pcInfo) {
        Write-Host "PC名: $($pcInfo.pcname)"
        Write-Host "ODJパス: $($pcInfo.odj_path)"
    }

.OUTPUTS
    PSCustomObject - PC情報（pcname, odj_path）
#>
function Get-PCInfoFromAPI {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$APIServer,

        [Parameter(Mandatory = $true)]
        [string]$Serial,

        [Parameter(Mandatory = $false)]
        [int]$RetryCount = 3,

        [Parameter(Mandatory = $false)]
        [int]$RetryDelay = 5,

        [Parameter(Mandatory = $false)]
        [int]$Timeout = 30
    )

    $attempt = 0

    while ($attempt -lt $RetryCount) {
        $attempt++

        try {
            Write-SetupLog "PC情報をAPIから取得中... (試行 $attempt/$RetryCount)" -Level INFO

            # TLS 1.2を有効化
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

            # APIエンドポイント
            $apiUrl = "$APIServer/api/pcinfo?serial=$Serial"

            Write-SetupLog "API URL: $apiUrl" -Level DEBUG

            # API呼び出し
            $response = Invoke-RestMethod -Uri $apiUrl -Method Get -TimeoutSec $Timeout -ErrorAction Stop

            # レスポンス検証
            if ($response -and $response.pcname) {
                Write-SetupLog "PC情報を取得しました: PC名=$($response.pcname), ODJパス=$($response.odj_path)" -Level INFO

                $pcInfo = [PSCustomObject]@{
                    pcname   = $response.pcname
                    odj_path = $response.odj_path
                    serial   = $Serial
                }

                return $pcInfo
            }
            else {
                Write-SetupLog "APIレスポンスが不正です: $response" -Level ERROR

                if ($attempt -lt $RetryCount) {
                    Write-SetupLog "$RetryDelay 秒後にリトライします..." -Level WARNING
                    Start-Sleep -Seconds $RetryDelay
                }
            }
        }
        catch [System.Net.WebException] {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-SetupLog "API呼び出し失敗（HTTPステータス: $statusCode）: $($_.Exception.Message)" -Level ERROR

            if ($statusCode -eq 404) {
                Write-SetupLog "指定されたSerial番号が見つかりません: $Serial" -Level ERROR
                return $null
            }

            if ($attempt -lt $RetryCount) {
                Write-SetupLog "$RetryDelay 秒後にリトライします..." -Level WARNING
                Start-Sleep -Seconds $RetryDelay
            }
        }
        catch {
            Write-ErrorLog -ErrorRecord $_ -Context "Get-PCInfoFromAPI"

            if ($attempt -lt $RetryCount) {
                Write-SetupLog "$RetryDelay 秒後にリトライします..." -Level WARNING
                Start-Sleep -Seconds $RetryDelay
            }
        }
    }

    Write-SetupLog "PC情報の取得に失敗しました（リトライ上限到達）: Serial=$Serial" -Level ERROR
    return $null
}

<#
.SYNOPSIS
    セットアップログをAPIに送信します。

.DESCRIPTION
    セットアップの進捗状況をDRBL管理サーバーに送信します。
    失敗時は指定回数リトライします。

.PARAMETER APIServer
    APIサーバーのURL（例: http://192.168.1.100:5000）

.PARAMETER LogData
    送信するログデータ（PSCustomObject）
    必須フィールド: serial, pcname, status, timestamp

.PARAMETER RetryCount
    リトライ回数（デフォルト: 3）

.PARAMETER RetryDelay
    リトライ間隔（秒、デフォルト: 5）

.PARAMETER Timeout
    タイムアウト時間（秒、デフォルト: 30）

.EXAMPLE
    $logData = @{
        serial = "ABC123456"
        pcname = "20251116M"
        status = "completed"
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        logs = "セットアップが正常に完了しました"
    }
    Send-SetupLog -APIServer "http://192.168.1.100:5000" -LogData $logData

.OUTPUTS
    Boolean - 送信成功時はTrue、失敗時はFalse
#>
function Send-SetupLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$APIServer,

        [Parameter(Mandatory = $true)]
        [hashtable]$LogData,

        [Parameter(Mandatory = $false)]
        [int]$RetryCount = 3,

        [Parameter(Mandatory = $false)]
        [int]$RetryDelay = 5,

        [Parameter(Mandatory = $false)]
        [int]$Timeout = 30
    )

    # 必須フィールドのチェック
    $requiredFields = @('serial', 'pcname', 'status', 'timestamp')
    foreach ($field in $requiredFields) {
        if (-not $LogData.ContainsKey($field)) {
            Write-SetupLog "LogDataに必須フィールドがありません: $field" -Level ERROR
            return $false
        }
    }

    $attempt = 0

    while ($attempt -lt $RetryCount) {
        $attempt++

        try {
            Write-SetupLog "セットアップログをAPIに送信中... (試行 $attempt/$RetryCount)" -Level INFO

            # TLS 1.2を有効化
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

            # APIエンドポイント
            $apiUrl = "$APIServer/api/log"

            # JSON変換
            $jsonData = $LogData | ConvertTo-Json -Depth 10

            Write-SetupLog "送信データ: $jsonData" -Level DEBUG

            # API呼び出し（POST）
            $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $jsonData -ContentType "application/json" -TimeoutSec $Timeout -ErrorAction Stop

            Write-SetupLog "セットアップログの送信に成功しました: $($LogData.status)" -Level INFO
            return $true
        }
        catch [System.Net.WebException] {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-SetupLog "ログ送信失敗（HTTPステータス: $statusCode）: $($_.Exception.Message)" -Level ERROR

            if ($attempt -lt $RetryCount) {
                Write-SetupLog "$RetryDelay 秒後にリトライします..." -Level WARNING
                Start-Sleep -Seconds $RetryDelay
            }
        }
        catch {
            Write-ErrorLog -ErrorRecord $_ -Context "Send-SetupLog"

            if ($attempt -lt $RetryCount) {
                Write-SetupLog "$RetryDelay 秒後にリトライします..." -Level WARNING
                Start-Sleep -Seconds $RetryDelay
            }
        }
    }

    Write-SetupLog "セットアップログの送信に失敗しました（リトライ上限到達）" -Level ERROR
    return $false
}

<#
.SYNOPSIS
    ファイルをAPIサーバーからダウンロードします。

.DESCRIPTION
    指定されたURLからファイルをダウンロードします。
    主にODJファイルのダウンロードに使用します。

.PARAMETER APIServer
    APIサーバーのURL（例: http://192.168.1.100:5000）

.PARAMETER FilePath
    ダウンロード元のファイルパス（サーバー上のパス）

.PARAMETER Destination
    ダウンロード先のローカルパス

.PARAMETER RetryCount
    リトライ回数（デフォルト: 3）

.PARAMETER Timeout
    タイムアウト時間（秒、デフォルト: 60）

.EXAMPLE
    Download-FileFromAPI -APIServer "http://192.168.1.100:5000" -FilePath "/odj/20251116M.txt" -Destination "C:\Setup\odj.txt"

.OUTPUTS
    Boolean - ダウンロード成功時はTrue、失敗時はFalse
#>
function Download-FileFromAPI {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$APIServer,

        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [Parameter(Mandatory = $false)]
        [int]$RetryCount = 3,

        [Parameter(Mandatory = $false)]
        [int]$Timeout = 60
    )

    $attempt = 0

    while ($attempt -lt $RetryCount) {
        $attempt++

        try {
            Write-SetupLog "ファイルをダウンロード中... (試行 $attempt/$RetryCount)" -Level INFO
            Write-SetupLog "URL: $APIServer$FilePath" -Level DEBUG
            Write-SetupLog "保存先: $Destination" -Level DEBUG

            # TLS 1.2を有効化
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

            # ダウンロード先ディレクトリの作成
            $destDir = Split-Path -Parent $Destination
            if (-not (Test-Path -Path $destDir)) {
                New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            }

            # ファイルダウンロード
            $downloadUrl = "$APIServer$FilePath"
            Invoke-WebRequest -Uri $downloadUrl -OutFile $Destination -TimeoutSec $Timeout -ErrorAction Stop

            # ダウンロード確認
            if (Test-Path -Path $Destination) {
                $fileSize = (Get-Item -Path $Destination).Length
                Write-SetupLog "ファイルのダウンロードに成功しました: $Destination ($fileSize bytes)" -Level INFO
                return $true
            }
            else {
                Write-SetupLog "ダウンロードしたファイルが見つかりません: $Destination" -Level ERROR
            }
        }
        catch {
            Write-ErrorLog -ErrorRecord $_ -Context "Download-FileFromAPI"

            if ($attempt -lt $RetryCount) {
                Write-SetupLog "5秒後にリトライします..." -Level WARNING
                Start-Sleep -Seconds 5
            }
        }
    }

    Write-SetupLog "ファイルのダウンロードに失敗しました（リトライ上限到達）" -Level ERROR
    return $false
}

# エクスポート
Export-ModuleMember -Function @(
    'Test-APIConnection',
    'Get-PCInfoFromAPI',
    'Send-SetupLog',
    'Download-FileFromAPI'
)
