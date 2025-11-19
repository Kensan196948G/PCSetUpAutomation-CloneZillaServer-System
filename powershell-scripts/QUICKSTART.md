# クイックスタートガイド

Windows PC自動セットアップスクリプトの導入手順を説明します。

## 目次

1. [前提条件](#前提条件)
2. [マスターPCへの組み込み（5ステップ）](#マスターpcへの組み込み5ステップ)
3. [動作確認](#動作確認)
4. [トラブルシューティング](#トラブルシューティング)

---

## 前提条件

### 必要なもの

- [ ] Windows 10/11 Pro 以上（マスターPC）
- [ ] 管理者権限
- [ ] DRBLサーバーの稼働（Flask APIアプリケーション）
- [ ] 社内LANへの接続

### DRBLサーバーの確認

以下のエンドポイントが応答することを確認：

```powershell
# APIサーバーの接続確認
Invoke-RestMethod -Uri "http://192.168.1.100:5000/api/health"

# PC情報取得テスト
Invoke-RestMethod -Uri "http://192.168.1.100:5000/api/pcinfo?serial=TEST123"
```

---

## マスターPCへの組み込み（5ステップ）

### ステップ1: セットアップディレクトリの作成

マスターPC上で管理者権限のPowerShellを開き、以下を実行：

```powershell
# セットアップディレクトリの作成
New-Item -Path "C:\Setup" -ItemType Directory -Force
New-Item -Path "C:\Setup\Apps" -ItemType Directory -Force
New-Item -Path "C:\Setup\Logs" -ItemType Directory -Force

# ディレクトリ確認
Get-ChildItem C:\Setup
```

### ステップ2: スクリプトファイルのコピー

このディレクトリ全体をマスターPCの `C:\Setup` にコピー：

```powershell
# 方法1: ネットワーク経由でコピー（推奨）
Copy-Item -Path "\\file-server\setup-scripts\*" -Destination "C:\Setup\" -Recurse -Force

# 方法2: USBメモリ経由でコピー
Copy-Item -Path "E:\powershell-scripts\*" -Destination "C:\Setup\" -Recurse -Force

# 方法3: GitHubからクローン
cd C:\
git clone https://github.com/your-company/setup-scripts.git Setup
```

**コピー後のディレクトリ構造確認：**

```
C:\Setup\
├── setup.ps1
├── modules\
│   ├── Logger.psm1
│   ├── PCInfo.psm1
│   ├── API.psm1
│   ├── Domain.psm1
│   ├── WindowsUpdate.psm1
│   └── AppInstall.psm1
└── config\
    ├── config.json
    └── unattend.xml
```

### ステップ3: 設定ファイルの編集

`C:\Setup\config\config.json` を編集：

```powershell
# メモ帳で開く
notepad C:\Setup\config\config.json
```

**必須変更項目：**

```json
{
  "api": {
    "server": "http://192.168.1.100:5000"  ← DRBLサーバーのURLに変更
  },
  "domain": {
    "name": "example.com",                 ← 実際のドメイン名に変更
    "ou": "OU=Computers,DC=example,DC=com" ← OUパスに変更
  }
}
```

### ステップ4: アプリインストーラーの配置

会社標準アプリのインストーラーを配置：

```powershell
# インストーラー配置先
C:\Setup\Apps\
├── Microsoft365\
│   ├── setup.exe
│   └── configuration.xml
├── GoogleChromeStandaloneEnterprise64.msi
├── AcroRdrDC.exe
└── 7z-x64.msi
```

**config.jsonのインストーラーパスと一致させること！**

### ステップ5: Sysprep実行

#### 5-1. unattend.xmlの確認

`C:\Setup\config\unattend.xml` を確認：

```powershell
notepad C:\Setup\config\unattend.xml
```

**重要：パスワードの変更**

デフォルトは `Password`（Base64エンコード済み）です。変更する場合：

```powershell
# 新しいパスワードをBase64エンコード
$password = "YourNewPassword"
$bytes = [System.Text.Encoding]::Unicode.GetBytes($password + "Password")
$encoded = [Convert]::ToBase64String($bytes)
Write-Host $encoded
```

#### 5-2. Sysprep実行

```powershell
# Sysprep実行（シャットダウン）
C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown /unattend:C:\Setup\config\unattend.xml
```

**Sysprep実行後は自動的にシャットダウンします。**

#### 5-3. Clonezillaでイメージ化

PCがシャットダウンしたら、Clonezillaで起動してイメージ化：

```bash
# DRBLサーバー上で
sudo /usr/sbin/dcs
# → "savedisk" を選択
# → イメージ名: "win11-master-YYYYMMDD"
```

---

## 動作確認

### テスト1: モジュール単体テスト

```powershell
# 管理者権限のPowerShellで実行
cd C:\Setup

# Loggerモジュールテスト
Import-Module .\modules\Logger.psm1
Write-SetupLog "テストメッセージ" -Level INFO
# → C:\Setup\Logs\setup-YYYYMMDD.log が作成される

# PCInfoモジュールテスト
Import-Module .\modules\PCInfo.psm1
Get-SerialNumber
# → Serial番号が表示される

Get-SystemInfo
# → システム情報が表示される
```

### テスト2: API接続テスト

```powershell
Import-Module .\modules\API.psm1

# API接続確認
Test-APIConnection -APIServer "http://192.168.1.100:5000"
# → True が返ればOK

# PC情報取得テスト（事前にDRBL GUIでテストデータを登録）
$pcInfo = Get-PCInfoFromAPI -APIServer "http://192.168.1.100:5000" -Serial "TEST123"
$pcInfo
# → pcname と odj_path が表示される
```

### テスト3: 設定ファイルの検証

```powershell
# JSON形式チェック
$config = Get-Content C:\Setup\config\config.json | ConvertFrom-Json
$config

# APIサーバーURLの確認
$config.api.server
```

### テスト4: 全体フローのテスト（任意）

**注意：実際にPC名が変更され、再起動されます！**

```powershell
# テスト環境でのみ実行
cd C:\Setup
.\setup.ps1
```

---

## トラブルシューティング

### 問題1: Serial番号が取得できない

**症状：** `Get-SerialNumber` が空文字列を返す

**対処法：**

```powershell
# 手動確認
Get-CimInstance -ClassName Win32_BIOS | Select-Object SerialNumber

# 仮想マシンの場合、Serial番号を設定
# VMware: VM設定 → オプション → 詳細 → 構成パラメータ → serialNumber.reflectHost = FALSE
# VMware: serialNumber = "YOUR_SERIAL_NUMBER"
```

### 問題2: API接続エラー

**症状：** `Test-APIConnection` が `False` を返す

**対処法：**

```powershell
# ネットワーク接続確認
Test-NetConnection -ComputerName 192.168.1.100 -Port 5000

# ファイアウォール確認
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*5000*"}

# DRBLサーバーのログ確認（サーバー側）
tail -f /var/log/flask-app/app.log
```

### 問題3: Sysprep失敗

**症状：** Sysprepが途中で停止する

**対処法：**

```powershell
# Sysprepログを確認
notepad C:\Windows\System32\Sysprep\Panther\setuperr.log

# AppXパッケージの削除（よくある原因）
Get-AppxPackage -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
```

### 問題4: スクリプトが実行されない

**症状：** Windows起動後、スクリプトが自動実行されない

**対処法：**

```powershell
# 実行ポリシー確認
Get-ExecutionPolicy -List

# 実行ポリシー変更
Set-ExecutionPolicy Bypass -Scope LocalMachine -Force

# unattend.xmlのパス確認
Test-Path C:\Setup\setup.ps1
Test-Path C:\Setup\config\unattend.xml

# FirstLogonCommandsのログ確認
# → C:\Windows\Panther\UnattendGC\setupact.log
```

### 問題5: Windows Update失敗

**症状：** Windows Updateが実行されない

**対処法：**

```powershell
# PSWindowsUpdateモジュールの確認
Get-Module -Name PSWindowsUpdate -ListAvailable

# 手動インストール
Install-Module -Name PSWindowsUpdate -Force -AllowClobber

# Windows Updateサービスの確認
Get-Service -Name wuauserv
Start-Service -Name wuauserv
```

### 問題6: セットアップの初期化

**症状：** セットアップが途中で止まった、最初からやり直したい

**対処法：**

```powershell
# 進捗レジストリの削除
Remove-Item -Path "HKLM:\SOFTWARE\CompanySetup" -Recurse -Force

# ログの削除
Remove-Item -Path "C:\Setup\Logs\*" -Force

# 再実行
cd C:\Setup
.\setup.ps1
```

---

## ログの確認方法

### セットアップログ

```powershell
# 最新のログファイルを表示
Get-Content C:\Setup\Logs\setup-$(Get-Date -Format 'yyyyMMdd').log -Tail 50

# エラーのみ抽出
Get-Content C:\Setup\Logs\setup-*.log | Select-String "ERROR"

# 特定のステップのログ抽出
Get-Content C:\Setup\Logs\setup-*.log | Select-String "ステップ3"
```

### トランスクリプトログ

```powershell
# トランスクリプトファイル一覧
Get-ChildItem C:\Setup\Logs\transcript-*.log

# 最新のトランスクリプトを表示
Get-Content (Get-ChildItem C:\Setup\Logs\transcript-*.log | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
```

### Windowsイベントログ

```powershell
# Setup Scriptイベントログ
Get-EventLog -LogName Application -Source "Setup Script" -Newest 10

# エラーイベントのみ
Get-EventLog -LogName Application -Source "Setup Script" -EntryType Error -Newest 10
```

---

## 実運用フロー

### 1. DRBL管理GUIでPC登録

1. DRBL管理GUI（http://192.168.1.100:5000）にアクセス
2. CSVインポートまたは手動でPC情報を登録
   - Serial番号: `ABC123456`
   - PC名: `20251116M`（YYYYMMDDM形式）
3. ODJファイルをアップロード（事前にdjoin.exeで生成）

### 2. PXEブートで展開

1. 新しいPCをLANに接続
2. 電源ON → PXEブートを選択
3. Clonezillaメニューで「win11-master-YYYYMMDD」を選択
4. イメージ展開（約10〜20分）

### 3. 自動セットアップ

1. Windows初回起動（約5分）
2. unattend.xmlによる自動ログオン
3. setup.ps1が自動実行
4. 以下を自動実行：
   - Serial番号取得
   - API呼び出し（PC名・ODJ取得）
   - PC名設定
   - ODJ適用
   - 再起動
   - Windows Update
   - アプリインストール
   - 完了ログ送信
5. セットアップ完了（約60〜90分）

### 4. 完了確認

```powershell
# ドメイン参加確認
(Get-WmiObject Win32_ComputerSystem).PartOfDomain
# → True

# PC名確認
$env:COMPUTERNAME
# → 20251116M

# インストール済みアプリ確認
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Select-Object DisplayName, DisplayVersion |
    Format-Table -AutoSize
```

---

## サポート

問題が解決しない場合は、以下の情報と共にIT部門に連絡してください：

1. **エラーメッセージ**
2. **セットアップログ** (`C:\Setup\Logs\setup-YYYYMMDD.log`)
3. **システム情報**
   ```powershell
   Get-ComputerInfo | Select-Object CsName, OsName, OsVersion, BiosSeralNumber
   ```

---

**作成日:** 2025-11-17
**バージョン:** 1.0
