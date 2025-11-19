# ポストデプロイスクリプト例：ドメイン参加の自動化
# PowerShell スクリプト
# 使用方法: イメージに含めてWindows起動時に自動実行

# 設定項目（環境に応じて変更）
$DomainName = "company.local"
$OUPath = "OU=Workstations,DC=company,DC=local"
$DomainUser = "admin"  # ドメイン参加権限を持つユーザー
$DomainPasswordFile = "C:\temp\domain_password.txt"  # パスワードファイル（セキュア運用を推奨）

# ログファイル
$LogFile = "C:\Windows\Temp\domain-join.log"

function Write-Log {
    param($Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Out-File -FilePath $LogFile -Append
    Write-Host $Message
}

Write-Log "=========================================="
Write-Log "ドメイン参加スクリプト開始"
Write-Log "=========================================="

# 管理者権限チェック
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "エラー: このスクリプトは管理者権限で実行してください"
    exit 1
}

# 既にドメインに参加しているかチェック
$ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem
if ($ComputerSystem.PartOfDomain) {
    Write-Log "このコンピューターは既にドメインに参加しています: $($ComputerSystem.Domain)"
    exit 0
}

# ネットワーク接続確認
Write-Log "ネットワーク接続を確認中..."
$PingResult = Test-Connection -ComputerName $DomainName -Count 2 -Quiet
if (-not $PingResult) {
    Write-Log "警告: ドメインコントローラーに到達できません"
    Write-Log "ネットワーク接続を確認してください"
    exit 1
}

# 認証情報の準備
Write-Log "認証情報を準備中..."
try {
    if (Test-Path $DomainPasswordFile) {
        $Password = Get-Content $DomainPasswordFile | ConvertTo-SecureString -AsPlainText -Force
        Remove-Item $DomainPasswordFile -Force  # セキュリティのため削除
    } else {
        Write-Log "エラー: パスワードファイルが見つかりません: $DomainPasswordFile"
        exit 1
    }
    
    $Credential = New-Object System.Management.Automation.PSCredential("$DomainName\$DomainUser", $Password)
} catch {
    Write-Log "エラー: 認証情報の準備に失敗しました - $_"
    exit 1
}

# ドメイン参加実行
Write-Log "ドメインに参加中: $DomainName"
try {
    if ($OUPath) {
        Add-Computer -DomainName $DomainName -OUPath $OUPath -Credential $Credential -Force -ErrorAction Stop
        Write-Log "ドメイン参加に成功しました（OU: $OUPath）"
    } else {
        Add-Computer -DomainName $DomainName -Credential $Credential -Force -ErrorAction Stop
        Write-Log "ドメイン参加に成功しました"
    }
    
    # このスクリプトを次回起動時に実行しないようにする
    # （スタートアップから削除など、環境に応じて実装）
    
    Write-Log "30秒後に再起動します..."
    Start-Sleep -Seconds 5
    Restart-Computer -Force -Delay 30
    
} catch {
    Write-Log "エラー: ドメイン参加に失敗しました - $_"
    exit 1
}

Write-Log "=========================================="
Write-Log "ドメイン参加スクリプト完了"
Write-Log "=========================================="
