# PowerShell自動セットアップスクリプト

このディレクトリには、Windows PC初回起動後の自動セットアップを行うPowerShellスクリプトが含まれています。

## ディレクトリ構造

```
powershell-scripts/
├── setup.ps1                   # メインセットアップスクリプト
├── modules/                    # モジュール
│   ├── Logger.psm1            # ログ機能
│   ├── PCInfo.psm1            # PC情報取得
│   ├── API.psm1               # API通信
│   ├── Domain.psm1            # ドメイン参加（ODJ）
│   ├── WindowsUpdate.psm1     # Windows Update
│   └── AppInstall.psm1        # アプリインストール
└── config/                    # 設定ファイル
    └── config.json            # 設定
```

## 前提条件

### システム要件
- Windows 10/11 (64bit)
- PowerShell 5.1以上
- 管理者権限
- インターネット接続（Windows Update用）
- 社内LAN接続（DRBL APIアクセス用）

### 事前準備
1. **DRBLサーバーの稼働確認**
   - APIサーバーが稼働していること
   - エンドポイント `/api/pcinfo` と `/api/log` が利用可能なこと

2. **設定ファイルの編集**
   - `config/config.json` を環境に合わせて編集
   - APIサーバーのURL、ドメイン名等を設定

3. **アプリインストーラーの配置**
   - `C:\Setup\Apps\` 配下にインストーラーを配置
   - config.jsonのパスと一致させること

## 主な機能

### setup.ps1
メインのセットアップスクリプト。以下の処理を順次実行します：

1. **Serial番号取得** - BIOSからSerial番号を取得
2. **API呼び出し** - DRBL APIから PC名とODJパスを取得
3. **PC名設定** - YYYYMMDDM形式でPC名を変更
4. **ODJ適用** - ドメイン参加ファイルを適用
5. **再起動（1回目）** - PC名とODJ適用のため
6. **Windows Update** - 最大5回ループで更新を完全適用
7. **アプリインストール** - 会社標準アプリを一括インストール
8. **完了ログ送信** - セットアップ完了をAPIに通知

### セットアップ進捗管理
- レジストリキー `HKLM:\SOFTWARE\CompanySetup` で進捗を管理
- 再起動後も処理を継続
- 異常終了時も再実行で途中から再開可能

## モジュール詳細

### Logger.psm1（ログ機能）
```powershell
Write-SetupLog "メッセージ" -Level INFO
Start-SetupTranscript
Stop-SetupTranscript
Set-LogConfiguration -ConfigPath "config.json"
Write-ErrorLog -ErrorRecord $_ -Context "関数名"
```

- ログファイル: `C:\Setup\Logs\setup-YYYYMMDD.log`
- トランスクリプト: `C:\Setup\Logs\transcript-YYYYMMDD-HHMMSS.log`
- ログレベル: INFO, WARNING, ERROR, DEBUG

### PCInfo.psm1（PC情報取得）
```powershell
$serial = Get-SerialNumber
$mac = Get-MACAddress
$sysInfo = Get-SystemInfo
$pcInfo = Get-PCInfo
$disks = Get-DiskInfo
Write-SystemInfoLog
```

### API.psm1（REST API通信）
```powershell
Test-APIConnection -APIServer "http://192.168.1.100:5000"
$pcInfo = Get-PCInfoFromAPI -APIServer "..." -Serial "ABC123"
Send-SetupLog -APIServer "..." -LogData @{...}
Download-FileFromAPI -APIServer "..." -FilePath "/odj/..." -Destination "C:\..."
```

### Domain.psm1（ドメイン参加・PC名設定）
```powershell
Test-PCNameFormat -PCName "20251116M"
Set-PCName -NewName "20251116M" -Force
Get-ODJFile -APIServer "..." -ODJPath "/odj/..." -LocalPath "C:\Setup\odj.txt"
Apply-ODJ -ODJFilePath "C:\Setup\odj.txt"
Test-DomainJoin
Get-DomainInfo
Initialize-EventLogSource
```

### WindowsUpdate.psm1（Windows Update実行）
```powershell
Install-PSWindowsUpdateModule
Get-UpdateCount
Test-UpdatesRequired
Install-WindowsUpdates -MaxIterations 5 -AutoReboot
Test-RebootRequired
Get-UpdateHistory -MaxRecords 20
```

### AppInstall.psm1（アプリインストール）
```powershell
Test-AppInstalled -AppName "アプリ名" -CheckPath "C:\..."
Install-Application -AppName "..." -InstallerPath "..." -Arguments "..." -Silent
Install-StandardApps -ConfigPath "config.json" -SkipInstalled
Get-InstalledApplications
Write-InstalledAppsLog
Install-MSI -MsiPath "..." -Arguments "..."
```

## 使用方法

### 1. マスターイメージへの組み込み

#### ステップ1: セットアップディレクトリの作成
```powershell
# マスターPC上で実行
New-Item -Path "C:\Setup" -ItemType Directory -Force
New-Item -Path "C:\Setup\Apps" -ItemType Directory -Force
New-Item -Path "C:\Setup\Logs" -ItemType Directory -Force
```

#### ステップ2: スクリプトの配置
```powershell
# このディレクトリ全体をマスターPCの C:\Setup にコピー
Copy-Item -Path "powershell-scripts\*" -Destination "C:\Setup\" -Recurse -Force
```

#### ステップ3: 設定ファイルの編集
```powershell
# C:\Setup\config\config.json を編集
# - api.server: DRBLサーバーのURL
# - domain.name: ドメイン名
# - apps.install_list: インストールするアプリ一覧
```

#### ステップ4: アプリインストーラーの配置
```powershell
# C:\Setup\Apps\ 配下にインストーラーを配置
# 例:
#   C:\Setup\Apps\Microsoft365\setup.exe
#   C:\Setup\Apps\GoogleChromeStandaloneEnterprise64.msi
#   C:\Setup\Apps\AcroRdrDC.exe
#   C:\Setup\Apps\7z-x64.msi
```

#### ステップ5: unattend.xml の設定
Sysprepのunattend.xmlに以下を追加：

```xml
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="oobeSystem">
        <!-- 自動ログオン設定 -->
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <AutoLogon>
                <Enabled>true</Enabled>
                <Username>Administrator</Username>
                <Password>
                    <Value>パスワード</Value>
                    <PlainText>true</PlainText>
                </Password>
                <LogonCount>1</LogonCount>
            </AutoLogon>
            <FirstLogonCommands>
                <SynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <CommandLine>powershell.exe -ExecutionPolicy Bypass -File C:\Setup\setup.ps1</CommandLine>
                    <Description>自動セットアップスクリプト実行</Description>
                </SynchronousCommand>
            </FirstLogonCommands>
        </component>
    </settings>
</unattend>
```

#### ステップ6: Sysprep実行
```powershell
C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown /unattend:C:\Setup\unattend.xml
```

### 2. 手動実行（テスト用）

開発環境やテスト環境で個別に実行する場合：

```powershell
# 管理者権限のPowerShellで実行
cd C:\Setup
.\setup.ps1
```

オプション指定（スクリプト内で定義が必要）:
```powershell
# 詳細ログ出力
.\setup.ps1 -Verbose

# 特定のステップから開始（レジストリで管理されるため通常不要）
# レジストリキー HKLM:\SOFTWARE\CompanySetup の SetupProgress を手動変更
```

### 3. 実運用フロー

1. **マスターPC構築** → Sysprep実行
2. **Clonezillaでイメージ化**
3. **DRBL管理GUIでPC登録**
   - Serial番号とPC名（YYYYMMDDM）を登録
   - ODJファイルをアップロード・紐付け
4. **PXEブートで展開**
   - 新しいPCをLANに接続
   - PXEブートでClonezillaイメージ展開
5. **自動セットアップ実行**
   - Windows初回起動
   - unattend.xmlにより自動ログオン
   - setup.ps1が自動実行
   - 完全無人でセットアップ完了

## 設定ファイル（config.json）

```json
{
  "api": {
    "server": "http://192.168.1.100:5000",
    "timeout": 30,
    "retry_count": 3,
    "retry_delay": 5
  },
  "domain": {
    "name": "example.com",
    "ou": "OU=Computers,DC=example,DC=com"
  },
  "windows_update": {
    "max_iterations": 5,
    "reboot_if_required": true,
    "categories": ["Security Updates", "Critical Updates", "Definition Updates"]
  },
  "apps": {
    "install_list": [
      {
        "name": "Microsoft 365 Apps",
        "installer": "C:\\Setup\\Apps\\Microsoft365\\setup.exe",
        "args": "/configure C:\\Setup\\Apps\\Microsoft365\\configuration.xml",
        "silent": true,
        "check_path": "C:\\Program Files\\Microsoft Office\\root\\Office16\\WINWORD.EXE"
      }
    ]
  },
  "logging": {
    "path": "C:\\Setup\\Logs",
    "level": "INFO",
    "max_size_mb": 10
  }
}
```

### 設定項目説明

#### api
- `server`: DRBLサーバーのURL
- `timeout`: API接続タイムアウト（秒）
- `retry_count`: リトライ回数
- `retry_delay`: リトライ間隔（秒）

#### domain
- `name`: ドメイン名
- `ou`: OU（組織単位）パス

#### windows_update
- `max_iterations`: Windows Update最大実行回数
- `reboot_if_required`: 更新後に自動再起動するか
- `categories`: 更新カテゴリ

#### apps.install_list
- `name`: アプリケーション名
- `installer`: インストーラーのフルパス
- `args`: インストーラーの引数
- `silent`: サイレントインストールフラグ
- `check_path`: インストール確認用のファイルパス（省略可）

#### logging
- `path`: ログ出力先ディレクトリ
- `level`: ログレベル（INFO, WARNING, ERROR, DEBUG）
- `max_size_mb`: ログファイルの最大サイズ（MB）

## エラーハンドリング

### リトライロジック
すべてのAPI呼び出しとネットワーク操作は自動リトライ：
- デフォルト3回リトライ
- 指数バックオフ（5秒 → 10秒 → 20秒）
- リトライ上限到達時はエラーログを送信

### 異常系処理

| エラー | 処理 |
|--------|------|
| Serial番号取得失敗 | エラーログ送信、セットアップ中止 |
| API接続失敗 | 3回リトライ後、エラーログ送信、セットアップ中止 |
| PC名設定失敗 | エラーログ送信、セットアップ中止 |
| ODJ適用失敗 | Windowsイベントログ記録、エラーログ送信、セットアップ中止 |
| Windows Update失敗 | 警告ログ出力、処理継続 |
| アプリインストール失敗 | 警告ログ出力、処理継続 |

### ログファイル

**セットアップログ**
- 場所: `C:\Setup\Logs\setup-YYYYMMDD.log`
- フォーマット: `[YYYY-MM-DD HH:MM:SS] [LEVEL] Message`

**トランスクリプト**
- 場所: `C:\Setup\Logs\transcript-YYYYMMDD-HHMMSS.log`
- すべてのPowerShellコマンドと出力を記録

**Windowsイベントログ**
- ログ名: Application
- ソース: Setup Script
- ODJ適用失敗時に記録

## トラブルシューティング

### Serial番号が取得できない
```powershell
# 手動確認
Get-CimInstance -ClassName Win32_BIOS | Select-Object SerialNumber
```
- 仮想マシンの場合、Serial番号が "To Be Filled By O.E.M." になることがある
- VMwareの場合は設定で有効なSerial番号を設定

### API接続エラー
```powershell
# 接続テスト
Test-NetConnection -ComputerName 192.168.1.100 -Port 5000

# APIテスト
Invoke-RestMethod -Uri "http://192.168.1.100:5000/api/pcinfo?serial=TEST123"
```

### PC名設定失敗
- 既にドメインに参加している場合は設定不可
- PC名の形式が不正（YYYYMMDDM以外）

### ODJ適用失敗
```powershell
# djoin.exeを手動実行
djoin.exe /requestODJ /loadfile "C:\Setup\odj.txt" /windowspath C:\Windows /localos
```
- ODJファイルの形式が不正
- ODJファイルが既に使用済み
- ネットワーク接続がない

### Windows Update失敗
```powershell
# PSWindowsUpdateモジュールの確認
Get-Module -Name PSWindowsUpdate -ListAvailable

# 手動インストール
Install-Module -Name PSWindowsUpdate -Force
```

### セットアップの初期化
```powershell
# 進捗レジストリを削除して最初からやり直す
Remove-Item -Path "HKLM:\SOFTWARE\CompanySetup" -Recurse -Force
```

## セキュリティ考慮事項

1. **スクリプト署名**
   - 実運用ではスクリプトに署名することを推奨
   ```powershell
   Set-AuthenticodeSignature -FilePath setup.ps1 -Certificate $cert
   ```

2. **API通信の暗号化**
   - HTTPSの使用を推奨（本実装はHTTP）
   - 社内LANのみアクセス可能にすること

3. **認証情報の管理**
   - unattend.xmlのパスワードは暗号化推奨
   - ログファイルに機密情報を出力しない

4. **最小権限の原則**
   - セットアップ完了後は管理者権限を削除
   - 不要なファイルは削除（Cleanup-Setup関数）

## 動作確認方法

### 1. モジュール単体テスト
```powershell
# Logger
Import-Module .\modules\Logger.psm1
Write-SetupLog "テストメッセージ" -Level INFO

# PCInfo
Import-Module .\modules\PCInfo.psm1
Get-SerialNumber
Get-SystemInfo

# API（DRBLサーバー稼働時）
Import-Module .\modules\API.psm1
Test-APIConnection -APIServer "http://192.168.1.100:5000"
```

### 2. 設定ファイルの検証
```powershell
# JSON形式チェック
Get-Content config\config.json | ConvertFrom-Json
```

### 3. 全体フローのテスト
```powershell
# テスト環境で実行（管理者権限）
.\setup.ps1
```

### 4. ログの確認
```powershell
# 最新のログファイルを表示
Get-Content C:\Setup\Logs\setup-$(Get-Date -Format 'yyyyMMdd').log -Tail 50

# エラーのみ抽出
Get-Content C:\Setup\Logs\setup-*.log | Select-String "ERROR"
```

## ライセンス

社内利用専用

## 作成者

会社名 IT部門

## バージョン履歴

- **v1.0** (2025-11-17)
  - 初回リリース
  - 全モジュール実装完了
  - Serial番号取得、API通信、PC名設定、ODJ適用、Windows Update、アプリインストール機能
