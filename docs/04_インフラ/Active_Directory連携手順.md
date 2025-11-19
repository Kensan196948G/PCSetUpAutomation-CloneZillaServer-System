# Active Directory連携手順

## 目次
1. [概要](#概要)
2. [前提条件](#前提条件)
3. [ODJファイル生成手順](#odjファイル生成手順)
4. [ODJファイルアップロード](#odjファイルアップロード)
5. [ODJファイル適用](#odjファイル適用)
6. [ドメインポリシー設定](#ドメインポリシー設定)
7. [グループポリシー適用](#グループポリシー適用)
8. [トラブルシューティング](#トラブルシューティング)

---

## 概要

### Offline Domain Join (ODJ) とは

**Offline Domain Join (ODJ)** は、Active Directoryドメインにオフライン（ネットワーク接続なし）でコンピューターを参加させる技術です。

### メリット
- **自動化**: スクリプトでドメイン参加を自動化
- **効率化**: 大量のPCを一括でドメイン参加
- **セキュリティ**: 管理者資格情報をスクリプトに埋め込む必要がない

### 動作フロー
```
1. ドメインコントローラーでODJファイル生成（djoin.exe /provision）
   ↓
2. ODJファイルをDRBLサーバーにアップロード
   ↓
3. DRBL管理GUIでPC名とODJファイルを紐付け
   ↓
4. クライアントPCがPXEブートでイメージ展開
   ↓
5. Windows起動後、PowerShellスクリプトがODJファイル取得
   ↓
6. djoin.exe /requestODJ でODJファイル適用
   ↓
7. 再起動後、ドメイン参加完了
```

---

## 前提条件

### Active Directory環境
- **ドメインコントローラー**: Windows Server 2012 R2以上
- **ドメイン機能レベル**: Windows Server 2008 R2以上
- **管理者権限**: Domain Adminsまたは委任された権限

### クライアントPC要件
- **OS**: Windows 10/11 Pro/Enterprise
- **エディション**: Homeエディションは不可
- **ネットワーク**: ドメインコントローラーへの通信可能

### 必要な情報
```powershell
# ドメイン情報
$DomainName = "company.local"
$DomainController = "dc01.company.local"

# OU（組織単位）
$TargetOU = "OU=Computers,OU=Kitting,DC=company,DC=local"

# PC命名規則
$PCName = "20251116M"  # YYYYMMDDM形式
```

---

## ODJファイル生成手順

### 1. ドメインコントローラーでの作業

**管理者権限でPowerShellを起動**:
```powershell
# PowerShellを管理者として実行
# Windows Server のドメインコントローラーで実行
```

### 2. 単一PCのODJファイル生成

```powershell
# パラメータ設定
$PCName = "20251116M"
$DomainName = "company.local"
$ODJFilePath = "C:\ODJ\$PCName.txt"
$TargetOU = "OU=Computers,OU=Kitting,DC=company,DC=local"

# ODJファイル生成
djoin.exe `
    /provision `
    /domain $DomainName `
    /machine $PCName `
    /savefile $ODJFilePath `
    /machineou $TargetOU

# 成功時の出力:
# Computer provisioning completed successfully.
```

**パラメータ説明**:
- `/provision`: プロビジョニングモード（ODJファイル生成）
- `/domain`: ドメイン名
- `/machine`: コンピューター名
- `/savefile`: ODJファイルの保存先
- `/machineou`: 配置先OU（オプション）

### 3. 複数PCのODJファイル一括生成

```powershell
# CSVファイルから一括生成
# CSV形式: PCName,OU
# 例: 20251116M,OU=Computers,OU=Kitting,DC=company,DC=local

# CSV読み込み
$PCList = Import-Csv -Path "C:\ODJ\pc_list.csv"

# ODJファイル生成ループ
foreach ($PC in $PCList) {
    $PCName = $PC.PCName
    $TargetOU = $PC.OU
    $ODJFilePath = "C:\ODJ\$PCName.txt"

    Write-Host "生成中: $PCName" -ForegroundColor Green

    try {
        djoin.exe `
            /provision `
            /domain "company.local" `
            /machine $PCName `
            /savefile $ODJFilePath `
            /machineou $TargetOU

        if ($LASTEXITCODE -eq 0) {
            Write-Host "  成功: $ODJFilePath" -ForegroundColor Green
        } else {
            Write-Host "  失敗: $PCName (エラーコード: $LASTEXITCODE)" -ForegroundColor Red
        }

    } catch {
        Write-Host "  エラー: $_" -ForegroundColor Red
    }
}

Write-Host "ODJファイル生成完了" -ForegroundColor Cyan
```

**CSV例** (`pc_list.csv`):
```csv
PCName,OU
20251116M,"OU=Computers,OU=Kitting,DC=company,DC=local"
20251117M,"OU=Computers,OU=Kitting,DC=company,DC=local"
20251118M,"OU=Computers,OU=Kitting,DC=company,DC=local"
```

### 4. ODJファイルの確認

```powershell
# ファイル確認
Get-ChildItem -Path "C:\ODJ\*.txt"

# ファイル内容確認（Base64エンコード）
Get-Content -Path "C:\ODJ\20251116M.txt"

# Active Directoryでコンピューターオブジェクト確認
Get-ADComputer -Filter {Name -eq "20251116M"} | Select-Object Name, DistinguishedName

# 出力例:
# Name        DistinguishedName
# ----        -----------------
# 20251116M   CN=20251116M,OU=Computers,OU=Kitting,DC=company,DC=local
```

### 5. 高度なODJ生成（オプション）

```powershell
# 詳細ログ出力付き
djoin.exe `
    /provision `
    /domain "company.local" `
    /machine "20251116M" `
    /savefile "C:\ODJ\20251116M.txt" `
    /machineou "OU=Computers,OU=Kitting,DC=company,DC=local" `
    /printblob `
    /reuse

# /printblob: Blobデータをコンソールに出力
# /reuse: 既存のコンピューターオブジェクトを再利用
```

---

## ODJファイルアップロード

### 1. DRBLサーバーへの転送

#### 方法1: SCP/SFTP（推奨）

```powershell
# Windows PowerShell から SCP でアップロード
# WinSCPまたはPowerShell 7以上が必要

# WinSCPスクリプト
$Session = New-Object WinSCP.SessionOptions -Property @{
    Protocol = [WinSCP.Protocol]::Sftp
    HostName = "192.168.1.100"
    UserName = "drbl-admin"
    Password = "password"
    SshHostKeyFingerprint = "ssh-rsa 2048 xx:xx:xx:..."
}

$WinSCP = New-Object WinSCP.Session
$WinSCP.Open($Session)

$LocalPath = "C:\ODJ\*.txt"
$RemotePath = "/srv/odj/"

$WinSCP.PutFiles($LocalPath, $RemotePath)
$WinSCP.Dispose()
```

#### 方法2: 共有フォルダ（SMB）

```powershell
# DRBLサーバーで共有フォルダを作成
# Linux側の設定:
```

```bash
# Samba インストール
sudo apt install -y samba

# 共有ディレクトリ作成
sudo mkdir -p /srv/odj
sudo chmod 755 /srv/odj

# Samba設定
sudo tee -a /etc/samba/smb.conf << 'EOF'
[odj]
  path = /srv/odj
  browseable = yes
  writable = yes
  guest ok = no
  valid users = drbl-admin
  create mask = 0644
  directory mask = 0755
EOF

# Sambaユーザー追加
sudo smbpasswd -a drbl-admin

# Samba再起動
sudo systemctl restart smbd
```

**Windows側からアクセス**:
```powershell
# ネットワークドライブとしてマップ
net use Z: \\192.168.1.100\odj /user:drbl-admin password

# ファイルコピー
Copy-Item -Path "C:\ODJ\*.txt" -Destination "Z:\"

# 切断
net use Z: /delete
```

#### 方法3: Webアップロード（Flask管理GUI）

```bash
# Flask管理アプリでファイルアップロード機能を実装
# routes.py

from flask import request, flash, redirect, url_for
from werkzeug.utils import secure_filename
import os

UPLOAD_FOLDER = '/srv/odj'
ALLOWED_EXTENSIONS = {'txt'}

@app.route('/upload_odj', methods=['POST'])
def upload_odj():
    if 'file' not in request.files:
        flash('ファイルが選択されていません')
        return redirect(url_for('index'))

    file = request.files['file']

    if file.filename == '':
        flash('ファイルが選択されていません')
        return redirect(url_for('index'))

    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        file.save(os.path.join(UPLOAD_FOLDER, filename))
        flash(f'ODJファイル {filename} をアップロードしました')
        return redirect(url_for('index'))
```

### 2. ODJファイルの配置と権限設定

```bash
# ODJファイル格納ディレクトリ作成
sudo mkdir -p /srv/odj
sudo chmod 755 /srv/odj

# ファイル権限設定
sudo chmod 644 /srv/odj/*.txt

# 所有者設定
sudo chown -R www-data:www-data /srv/odj

# ファイル確認
ls -l /srv/odj/
```

### 3. DRBL管理GUIでの紐付け

```bash
# データベースにPC情報とODJパスを登録

# SQLiteの場合
sqlite3 /path/to/dev.db << EOF
INSERT INTO pc_master (serial, pcname, odj_path, created_at)
VALUES ('ABC123456', '20251116M', '/srv/odj/20251116M.txt', datetime('now'));
EOF

# または Flask管理GUI経由で登録
curl -X POST http://192.168.1.100:5000/api/pcinfo \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-token" \
  -d '{
    "serial": "ABC123456",
    "pcname": "20251116M",
    "odj_path": "/srv/odj/20251116M.txt"
  }'
```

---

## ODJファイル適用

### 1. クライアントPC側のPowerShellスクリプト

```powershell
<#
.SYNOPSIS
    ODJファイル適用スクリプト
.DESCRIPTION
    DRBL APIからODJファイルパスを取得し、ドメイン参加を実行
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string]$APIBaseUrl = "http://192.168.10.1:5000/api",
    [string]$APIToken = "your-api-token"
)

$ErrorActionPreference = 'Stop'

# ログ関数
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    Write-Host $LogMessage
    Add-Content -Path "C:\Logs\odj-setup.log" -Value $LogMessage
}

try {
    Write-Log "ODJ適用開始"

    # 1. シリアル番号取得
    $Serial = (Get-CimInstance Win32_BIOS).SerialNumber
    Write-Log "シリアル番号: $Serial"

    # 2. PC情報取得（API）
    $Headers = @{
        "Authorization" = "Bearer $APIToken"
    }

    $Response = Invoke-RestMethod `
        -Uri "$APIBaseUrl/pcinfo?serial=$Serial" `
        -Method GET `
        -Headers $Headers

    $PCName = $Response.data.pcname
    $ODJPath = $Response.data.odj_path
    Write-Log "PC名: $PCName"
    Write-Log "ODJパス: $ODJPath"

    # 3. ODJファイルダウンロード
    $LocalODJPath = "C:\Temp\$PCName.txt"
    $ODJFileUrl = "http://192.168.10.1/odj/$PCName.txt"

    Invoke-WebRequest -Uri $ODJFileUrl -OutFile $LocalODJPath
    Write-Log "ODJファイルダウンロード完了: $LocalODJPath"

    # 4. ODJファイル適用
    $DJoinResult = djoin.exe /requestODJ /loadfile $LocalODJPath /windowspath C:\Windows /localos

    if ($LASTEXITCODE -eq 0) {
        Write-Log "ODJ適用成功" "INFO"

        # 5. PC名変更
        Rename-Computer -NewName $PCName -Force
        Write-Log "PC名変更完了: $PCName"

        # 6. 完了ログ送信
        $LogBody = @{
            serial = $Serial
            pcname = $PCName
            status = "odj_completed"
            timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            logs = "ODJ適用完了。再起動後ドメイン参加。"
        } | ConvertTo-Json

        Invoke-RestMethod `
            -Uri "$APIBaseUrl/log" `
            -Method POST `
            -Headers $Headers `
            -Body $LogBody `
            -ContentType "application/json"

        Write-Log "セットアップ完了。再起動します。"
        Start-Sleep -Seconds 5
        Restart-Computer -Force

    } else {
        Write-Log "ODJ適用失敗 (エラーコード: $LASTEXITCODE)" "ERROR"
        throw "ODJ適用エラー"
    }

} catch {
    Write-Log "エラー: $_" "ERROR"
    exit 1
}
```

### 2. djoin.exe コマンド詳細

```powershell
# 基本構文
djoin.exe /requestODJ /loadfile <ODJファイルパス> /windowspath <Windowsパス> /localos

# パラメータ説明:
# /requestODJ     : ODJリクエストモード
# /loadfile       : ODJファイルのパス
# /windowspath    : Windowsディレクトリ（通常 C:\Windows）
# /localos        : ローカルOSに適用
```

**成功時の出力**:
```
This operation is successful.
```

**エラーコード**:
- `0`: 成功
- `5`: アクセス拒否（管理者権限必要）
- `87`: パラメータエラー
- `1326`: ログオン失敗

### 3. 再起動後の確認

```powershell
# ドメイン参加確認
$ComputerSystem = Get-CimInstance Win32_ComputerSystem
$ComputerSystem | Select-Object Name, Domain, PartOfDomain

# 出力例:
# Name        Domain          PartOfDomain
# ----        ------          ------------
# 20251116M   company.local   True
```

---

## ドメインポリシー設定

### 1. ODJ用コンピューターアカウントの管理

```powershell
# Active Directory PowerShellモジュールのインポート
Import-Module ActiveDirectory

# ODJ用OU確認
Get-ADOrganizationalUnit -Filter {Name -eq "Kitting"} |
    Select-Object Name, DistinguishedName

# OU内のコンピューター一覧
Get-ADComputer -Filter * -SearchBase "OU=Computers,OU=Kitting,DC=company,DC=local" |
    Select-Object Name, DistinguishedName

# 古いコンピューターアカウントの削除（90日以上未使用）
$Threshold = (Get-Date).AddDays(-90)
Get-ADComputer -Filter {LastLogonDate -lt $Threshold} -SearchBase "OU=Computers,OU=Kitting,DC=company,DC=local" |
    Remove-ADComputer -Confirm:$false
```

### 2. ODJ用権限委任

```powershell
# ODJ専用管理者ユーザー作成
New-ADUser -Name "ODJ-Admin" `
    -SamAccountName "odj-admin" `
    -UserPrincipalName "odj-admin@company.local" `
    -Path "OU=ServiceAccounts,DC=company,DC=local" `
    -AccountPassword (ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force) `
    -Enabled $true

# 権限委任（OU内でコンピューターオブジェクト作成・削除）
$OU = "OU=Computers,OU=Kitting,DC=company,DC=local"
$User = "odj-admin"

# dsacls コマンドで権限付与
dsacls $OU /I:T /G "${User}:CCDC;computer"

# または Active Directory Users and Computers GUIで設定
# 1. OUを右クリック → プロパティ
# 2. セキュリティタブ → 詳細設定
# 3. 追加 → プリンシパルを選択（odj-admin）
# 4. アクセス許可: コンピューターオブジェクトの作成/削除
```

---

## グループポリシー適用

### 1. キッティング用GPO作成

```powershell
# GPO作成
New-GPO -Name "Kitting-Setup-Policy" -Comment "キッティング時の初期設定"

# OUにリンク
New-GPLink -Name "Kitting-Setup-Policy" -Target "OU=Computers,OU=Kitting,DC=company,DC=local"
```

### 2. GPO設定項目

**コンピューターの構成 → ポリシー → Windowsの設定**:

#### セキュリティ設定
```
- ローカルポリシー → セキュリティオプション
  - ネットワークアクセス: 匿名 SID/名前の変換を許可 → 無効
  - アカウント: Administrator アカウントの名前を変更 → 無効

- ローカルポリシー → ユーザー権利の割り当て
  - ローカルログオンを許可 → Domain Admins, Domain Users

- Windowsファイアウォール
  - ドメインプロファイル → 有効
  - パブリックプロファイル → 有効
```

#### スクリプト
```
- スタートアップスクリプト
  - \\dc01\NETLOGON\kitting-startup.ps1
```

**kitting-startup.ps1 例**:
```powershell
# キッティング完了後の処理
# セキュリティソフトのインストール
# Windows Update強制実行
# ログ送信

Start-Transcript -Path "C:\Logs\gpo-startup.log"

Write-Host "キッティング完了後のGPO実行"

# セキュリティソフトインストール
# msiexec /i \\dc01\Software\SecuritySoft.msi /quiet

# Windows Update
# Install-Module PSWindowsUpdate -Force
# Get-WindowsUpdate -Install -AcceptAll -AutoReboot

Stop-Transcript
```

### 3. GPO適用確認

```powershell
# クライアントPC側でGPO更新
gpupdate /force

# GPO適用状況確認
gpresult /r

# または詳細レポート
gpresult /h C:\Temp\gpresult.html
```

---

## トラブルシューティング

### 問題1: ODJファイル生成エラー

**症状**:
```
Error: The system cannot find the specified path.
```

**解決策**:
```powershell
# ディレクトリが存在するか確認
Test-Path "C:\ODJ"

# 存在しない場合は作成
New-Item -Path "C:\ODJ" -ItemType Directory

# 再実行
djoin.exe /provision /domain "company.local" /machine "20251116M" /savefile "C:\ODJ\20251116M.txt"
```

### 問題2: コンピューター名が既に存在

**症状**:
```
Error: The specified account already exists.
```

**解決策**:
```powershell
# 既存オブジェクトを削除
Remove-ADComputer -Identity "20251116M" -Confirm:$false

# または /reuse オプションで再利用
djoin.exe /provision /domain "company.local" /machine "20251116M" /savefile "C:\ODJ\20251116M.txt" /reuse
```

### 問題3: ODJ適用時にエラー

**症状**:
```powershell
djoin.exe /requestODJ /loadfile C:\Temp\20251116M.txt /windowspath C:\Windows /localos
# エラーコード: 87
```

**解決策**:
```powershell
# 管理者権限で実行されているか確認
# PowerShellを「管理者として実行」で起動

# ODJファイルが存在するか確認
Test-Path "C:\Temp\20251116M.txt"

# ファイル内容確認（Base64エンコードされているか）
Get-Content "C:\Temp\20251116M.txt"

# ファイルを再ダウンロード
```

### 問題4: ドメイン参加できない

**症状**:
再起動後もワークグループのまま

**解決策**:
```powershell
# イベントログ確認
Get-EventLog -LogName System -Source "Microsoft-Windows-OfflineJoin" -Newest 10

# ネットワーク確認
Test-Connection -ComputerName "dc01.company.local" -Count 2

# DNSが正しいか確認
nslookup dc01.company.local

# 手動でドメイン参加テスト
Add-Computer -DomainName "company.local" -Credential (Get-Credential) -Restart
```

### 問題5: グループポリシーが適用されない

**症状**:
`gpresult /r` で対象GPOが表示されない

**解決策**:
```powershell
# GPOリンク確認
Get-GPInheritance -Target "OU=Computers,OU=Kitting,DC=company,DC=local"

# GPOステータス確認
Get-GPO -Name "Kitting-Setup-Policy" | Select-Object DisplayName, GpoStatus

# クライアント側でGPO強制更新
gpupdate /force /target:computer

# 再起動後に確認
Restart-Computer -Force
```

### 問題6: Active Directoryで重複エラー

**症状**:
```
Error: The specified account name is already a member of the group.
```

**解決策**:
```powershell
# Active Directoryで重複確認
Get-ADComputer -Filter {Name -eq "20251116M"} -Properties *

# 複数OUに同名が存在する場合は削除
Get-ADComputer -Filter {Name -eq "20251116M"} | Remove-ADComputer -Confirm:$false

# ごみ箱から完全削除（AD Recycle Bin有効時）
Get-ADObject -Filter {Name -eq "20251116M"} -IncludeDeletedObjects | Remove-ADObject -Confirm:$false
```

---

## セキュリティベストプラクティス

### 1. ODJファイルの暗号化

```powershell
# ODJファイルをZIPで暗号化
Compress-Archive -Path "C:\ODJ\20251116M.txt" -DestinationPath "C:\ODJ\20251116M.zip"
# パスワード保護は7-Zipなどのツールを使用

# または BitLockerでディレクトリ全体を暗号化
Enable-BitLocker -MountPoint "D:" -EncryptionMethod Aes256 -Password (ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force)
```

### 2. ODJファイルのアクセス制限

```bash
# DRBLサーバー側で権限設定
sudo chmod 600 /srv/odj/*.txt
sudo chown www-data:www-data /srv/odj/*.txt

# Nginxで認証付きダウンロード
# /etc/nginx/sites-available/default
location /odj/ {
    auth_basic "ODJ Files";
    auth_basic_user_file /etc/nginx/.htpasswd;
    alias /srv/odj/;
}
```

### 3. 定期的なアカウントクリーンアップ

```powershell
# スケジュールタスクで定期実行
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Scripts\cleanup-odj-accounts.ps1"
$Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 3am
Register-ScheduledTask -TaskName "ODJ Account Cleanup" -Action $Action -Trigger $Trigger -User "SYSTEM"
```

---

## 参考資料

- [Offline Domain Join (Djoin.exe) Step-by-Step Guide](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/dd392267(v=ws.10))
- [Active Directory Domain Services Overview](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview)
- [Group Policy Planning and Deployment Guide](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/group-policy-planning-and-deployment)
