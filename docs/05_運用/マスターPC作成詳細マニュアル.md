# マスターPC作成詳細マニュアル

## 目次
- [概要](#概要)
- [準備](#準備)
- [BIOS設定](#bios設定)
- [Windows 11インストール](#windows-11インストール)
- [Windows初期設定](#windows初期設定)
- [会社標準アプリケーション導入](#会社標準アプリケーション導入)
- [AppX削除詳細手順](#appx削除詳細手順)
- [Sysprep実行前チェックリスト](#sysprep実行前チェックリスト)
- [unattend.xml作成と配置](#unattendxml作成と配置)
- [Sysprep実行手順](#sysprep実行手順)
- [Clonezillaイメージ化手順](#clonezillaイメージ化手順)
- [マスターイメージ検証](#マスターイメージ検証)
- [マスターイメージ更新頻度と判断基準](#マスターイメージ更新頻度と判断基準)
- [トラブルシューティング](#トラブルシューティング)

---

## 概要

### マスターPCとは

マスターPCは、会社標準構成を実装したWindows PCのテンプレートです。Sysprepで一般化後、Clonezillaでイメージ化し、全社PCに展開します。

### マスターPC作成の流れ

```
1. BIOS設定
   ↓
2. Windows 11インストール
   ↓
3. Windows初期設定
   ↓
4. 会社標準アプリケーション導入
   ↓
5. Windows Update最新化
   ↓
6. AppX削除
   ↓
7. Sysprep実行前チェック
   ↓
8. unattend.xml配置
   ↓
9. Sysprep実行
   ↓
10. Clonezillaイメージ化
   ↓
11. マスターイメージ検証
```

### 所要時間

- **初回作成**: 4-6時間
- **更新（Windows Update中心）**: 2-3時間

---

## 準備

### 必要なもの

#### ハードウェア
- [ ] マスターPC用ハードウェア（会社標準仕様）
  - CPU: Intel Core i5 以上（4コア以上推奨）
  - メモリ: 8GB以上（16GB推奨）
  - ストレージ: SSD 256GB以上
  - ネットワーク: Gigabit Ethernet
- [ ] USB キーボード・マウス
- [ ] ディスプレイ

#### メディア
- [ ] Windows 11 インストールUSB（64GB以上推奨）
- [ ] Clonezilla Live USB（8GB以上）
- [ ] ドライバUSB（メーカー提供ドライバ）

#### ソフトウェア
- [ ] Windows 11 Pro ISOファイル
- [ ] 会社標準アプリケーションインストーラ
  - Microsoft 365 Apps
  - セキュリティソフト
  - PDF閲覧ソフト
  - 圧縮解凍ツール
  - その他（会社指定）
- [ ] unattend.xml サンプルファイル

#### ライセンス
- [ ] Windows 11 Pro プロダクトキー
- [ ] Microsoft 365 Apps ライセンス
- [ ] セキュリティソフトライセンス

---

## BIOS設定

### 起動とBIOS画面表示

1. マスターPC電源投入
2. BIOS起動キー押下（メーカーにより異なる）
   - **Dell**: F2
   - **HP**: F10
   - **Lenovo**: F1 or F2
   - **NEC**: F2

### 推奨BIOS設定

#### Boot Mode（起動モード）

```
Boot Mode: UEFI（推奨）
※ 全展開先PCも統一すること
```

- **Legacy BIOS**: 古い起動方式（非推奨）
- **UEFI**: 新しい起動方式（推奨、GPTパーティション対応）

#### Secure Boot（セキュアブート）

```
Secure Boot: Disabled（無効）
```

- Clonezillaブート時に問題が発生する可能性があるため無効化
- 展開後、必要に応じて有効化可能

#### Fast Boot（高速起動）

```
Fast Boot: Disabled（無効）
```

- PXEブート時に問題が発生する可能性があるため無効化

#### Virtualization（仮想化）

```
Intel VT-x / AMD-V: Enabled（有効）
VT-d: Enabled（有効）※必要に応じて
```

- Hyper-V、WSL2等を使用する場合は有効化

#### SATA Mode

```
SATA Mode: AHCI
```

- **AHCI**: 推奨（パフォーマンス向上）
- **IDE**: レガシーモード（非推奨）
- **RAID**: RAIDコントローラ使用時のみ

#### ネットワークブート

```
Network Boot: Enabled（有効）
PXE Boot: Enabled（有効）
```

- 展開先PCでPXEブート必要
- マスターPC作成時は無効でも可

### BIOS設定保存

1. F10キー押下（Save and Exit）
2. "Save configuration changes?" → **Yes**
3. 再起動

---

## Windows 11インストール

### Windows 11インストールUSB作成

#### Rufus使用（推奨）

```powershell
# Rufus ダウンロード
# https://rufus.ie/

# 1. Rufus起動
# 2. Device: USBメモリ選択
# 3. Boot selection: Windows 11 ISO選択
# 4. Partition scheme: GPT（UEFI用）
# 5. File system: NTFS
# 6. START ボタンクリック
```

#### Windows公式ツール使用

```
# Media Creation Tool ダウンロード
# https://www.microsoft.com/software-download/windows11

# 1. Media Creation Tool実行
# 2. "USB フラッシュ ドライブ" 選択
# 3. USBメモリ選択
# 4. ダウンロード開始
```

### インストール開始

1. Windows 11 インストールUSBをマスターPCに挿入
2. BIOS Boot MenuでUSBブート選択
   - **Dell**: F12
   - **HP**: F9
   - **Lenovo**: F12
3. "Press any key to boot from USB..." → 任意キー押下

### Windows 11セットアップ

#### 言語・地域設定

```
言語: 日本語
時刻と通貨の形式: 日本語（日本）
キーボードまたは入力方法: Microsoft IME
```

#### プロダクトキー入力

```
プロダクトキー入力画面:
- プロダクトキー入力
- または "プロダクトキーがありません" をクリック（後で入力）
```

#### エディション選択

```
Windows 11 Pro を選択
```

#### ライセンス条項

```
"ライセンス条項に同意します" にチェック
→ 次へ
```

#### インストールの種類

```
"カスタム: Windowsのみをインストールする" を選択
```

### パーティション構成

#### 推奨パーティション構成（GPT、UEFI）

```
パーティション1: EFI System Partition (ESP) - 100MB
パーティション2: Microsoft Reserved (MSR) - 16MB
パーティション3: Windows (C:) - 残り全容量
```

#### 手動パーティション作成

1. "ドライブ0の割り当てられていない領域" を選択
2. "新規" をクリック
3. サイズ: 最大サイズのまま（例: 250000 MB）
4. "適用" をクリック
5. "追加のパーティションが作成される可能性があります" → OK

**重要**: データドライブ（D:等）は作成しない

#### インストール開始

1. パーティション3（Windows）を選択
2. "次へ" をクリック
3. インストール開始（15-30分）

### 初回起動とOOBE（Out-of-Box Experience）

#### 地域設定

```
地域: 日本
```

#### キーボードレイアウト

```
キーボードレイアウト: Microsoft IME
2番目のキーボードレイアウト: スキップ
```

#### ネットワーク接続

```
"インターネットに接続していません" を選択
→ "制限された設定で続行" をクリック
```

**重要**: マスターPC作成時はネットワーク未接続推奨（Microsoftアカウント要求回避）

#### アカウント設定

```
ユーザー名: Administrator（または company_admin）
パスワード: 強力なパスワード設定
セキュリティの質問: 3つ設定
```

#### プライバシー設定

```
すべてオフ推奨:
- 位置情報: オフ
- デバイスの検索: オフ
- 診断データ: 必須のみ
- 手書き入力と入力: オフ
- エクスペリエンスのカスタマイズ: オフ
- 広告ID: オフ
```

---

## Windows初期設定

### Windowsライセンス認証

```powershell
# プロダクトキー確認
slmgr /dli

# プロダクトキー設定（未設定の場合）
slmgr /ipk XXXXX-XXXXX-XXXXX-XXXXX-XXXXX

# ライセンス認証
slmgr /ato

# 認証状態確認
slmgr /xpr
```

### コンピュータ名変更（一時的）

```powershell
# 現在のコンピュータ名確認
hostname

# コンピュータ名変更（例: MASTER-PC）
Rename-Computer -NewName "MASTER-PC" -Force -Restart
```

### Windows Update実行

```powershell
# Windows Update設定画面を開く
Start-Process ms-settings:windowsupdate

# 手動で "更新プログラムのチェック" をクリック
# すべての更新プログラムをインストール
# 再起動が必要な場合、再起動

# 繰り返し実行（利用可能な更新が0になるまで）
```

**所要時間**: 1-2時間（初回）

### リモートデスクトップ有効化（オプション）

```powershell
# リモートデスクトップ有効化
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0

# ファイアウォール許可
Enable-NetFirewallRule -DisplayGroup "リモート デスクトップ"
```

### Windows Defender設定

```powershell
# Windows Defender状態確認
Get-MpComputerStatus

# リアルタイム保護一時無効化（セットアップ作業中のみ）
Set-MpPreference -DisableRealtimeMonitoring $true

# 作業完了後、必ず有効化
Set-MpPreference -DisableRealtimeMonitoring $false
```

---

## 会社標準アプリケーション導入

### アプリケーション一覧

#### 必須アプリケーション

1. **Microsoft 365 Apps**（Word, Excel, PowerPoint, Outlook等）
2. **セキュリティソフト**（例: Trend Micro、Symantec等）
3. **PDF閲覧ソフト**（例: Adobe Acrobat Reader DC）
4. **圧縮解凍ツール**（例: 7-Zip）
5. **ブラウザ**（Google Chrome、Microsoft Edge等）

#### 推奨アプリケーション

6. **VPN クライアント**（会社指定）
7. **リモートアクセスツール**（TeamViewer、AnyDesk等）
8. **メモ帳++**（Notepad++）
9. **画像ビューア**（IrfanView等）

### Microsoft 365 Apps インストール

#### オンラインインストール（推奨）

```powershell
# Microsoft 365 Deployment Tool ダウンロード
# https://www.microsoft.com/en-us/download/details.aspx?id=49117

# setup.exe と configuration.xml を同じフォルダに配置

# configuration.xml サンプル（サイレントインストール）
```

```xml
<Configuration>
  <Add OfficeClientEdition="64" Channel="Current">
    <Product ID="O365ProPlusRetail">
      <Language ID="ja-jp" />
      <ExcludeApp ID="Groove" />
      <ExcludeApp ID="Teams" />
    </Product>
  </Add>
  <Display Level="None" AcceptEULA="TRUE" />
  <Property Name="AUTOACTIVATE" Value="0" />
</Configuration>
```

```powershell
# インストール実行
.\setup.exe /configure configuration.xml
```

#### オフラインインストール

```powershell
# オフラインインストーラダウンロード
.\setup.exe /download configuration.xml

# インストール実行
.\setup.exe /configure configuration.xml
```

**所要時間**: 15-30分

### セキュリティソフトインストール

#### 例: Trend Micro Apex One

```powershell
# サイレントインストール
Start-Process "C:\Installers\TrendMicro\setup.exe" -ArgumentList "/s /v/qn" -Wait
```

#### 例: Symantec Endpoint Protection

```powershell
# サイレントインストール
Start-Process "C:\Installers\Symantec\setup.exe" -ArgumentList "/s /v`"/qn REBOOT=ReallySuppress`"" -Wait
```

**所要時間**: 10-20分

### Adobe Acrobat Reader DC インストール

```powershell
# サイレントインストール
Start-Process "C:\Installers\AdobeReader\AcroRdrDC.exe" -ArgumentList "/sAll /rs /msi EULA_ACCEPT=YES" -Wait

# インストール確認
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*Adobe*"}
```

**所要時間**: 5-10分

### 7-Zip インストール

```powershell
# サイレントインストール
Start-Process "msiexec.exe" -ArgumentList "/i `"C:\Installers\7-Zip\7z2301-x64.msi`" /qn /norestart" -Wait

# インストール確認
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*7-Zip*"}
```

**所要時間**: 2-5分

### Google Chrome インストール

```powershell
# サイレントインストール
Start-Process "msiexec.exe" -ArgumentList "/i `"C:\Installers\Chrome\googlechromestandaloneenterprise64.msi`" /qn /norestart" -Wait

# 自動更新無効化（オプション）
New-Item -Path "HKLM:\SOFTWARE\Policies\Google\Update" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Update" -Name "AutoUpdateCheckPeriodMinutes" -Value 0
```

**所要時間**: 5-10分

### インストール確認

```powershell
# インストール済みアプリケーション一覧
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher | Sort-Object DisplayName
```

---

## AppX削除詳細手順

### AppXとは

AppX（Appxパッケージ）は、Microsoft Storeアプリやプレインストールアプリ（Xbox、Candy Crush等）のパッケージ形式です。Sysprep実行前に不要なAppXを削除しないと、Sysprep失敗の原因になります。

### 削除対象AppX一覧（30個以上）

#### ゲーム系（全削除推奨）

- Microsoft.BingNews
- Microsoft.BingWeather
- Microsoft.BingFinance
- Microsoft.BingSports
- Microsoft.XboxApp
- Microsoft.XboxGameOverlay
- Microsoft.XboxGamingOverlay
- Microsoft.XboxIdentityProvider
- Microsoft.XboxSpeechToTextOverlay
- Microsoft.Xbox.TCUI
- Microsoft.GamingApp
- king.com.CandyCrushSaga
- king.com.CandyCrushSodaSaga

#### メディア・エンターテイメント系

- Microsoft.ZuneMusic
- Microsoft.ZuneVideo
- Microsoft.MixedReality.Portal
- SpotifyAB.SpotifyMusic

#### SNS・コミュニケーション系

- Microsoft.SkypeApp（※Skype for Business使用時は残す）
- Microsoft.YourPhone
- Microsoft.People

#### その他

- Microsoft.GetHelp
- Microsoft.Getstarted
- Microsoft.MicrosoftOfficeHub（※Microsoft 365 Apps使用時は削除可）
- Microsoft.MicrosoftSolitaireCollection
- Microsoft.MicrosoftStickyNotes
- Microsoft.Messaging
- Microsoft.OneConnect
- Microsoft.Print3D
- Microsoft.Todos
- Microsoft.Wallet
- Microsoft.WindowsFeedbackHub
- Microsoft.WindowsMaps
- Microsoft.WindowsSoundRecorder
- Microsoft.3DBuilder

#### 残すべきAppX

- **Microsoft.WindowsStore**（Storeアプリ、削除非推奨）
- **Microsoft.WindowsCalculator**（電卓）
- **Microsoft.Windows.Photos**（フォト）
- **Microsoft.ScreenSketch**（Snipping Tool）
- **Microsoft.MSPaint**（ペイント）
- **Microsoft.WindowsCamera**（カメラアプリ、必要に応じて）

### AppX削除PowerShellスクリプト

#### 手動実行（推奨）

```powershell
# 管理者権限でPowerShell起動
Start-Process powershell -Verb RunAs

# 現在インストールされているAppX一覧表示
Get-AppxPackage | Select-Object Name, PackageFullName | Sort-Object Name

# 個別削除（例: Xbox）
Get-AppxPackage -Name "Microsoft.XboxApp" | Remove-AppxPackage

# プロビジョニングパッケージも削除（新規ユーザーに再インストールされるのを防止）
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq "Microsoft.XboxApp"} | Remove-AppxProvisionedPackage -Online
```

#### 一括削除スクリプト

```powershell
# AppX一括削除スクリプト（慎重に実行）
# C:\Scripts\Remove-AppX.ps1 として保存

# 削除対象AppX一覧
$AppXList = @(
    "Microsoft.BingNews",
    "Microsoft.BingWeather",
    "Microsoft.BingFinance",
    "Microsoft.BingSports",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.Xbox.TCUI",
    "Microsoft.GamingApp",
    "king.com.CandyCrushSaga",
    "king.com.CandyCrushSodaSaga",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "Microsoft.MixedReality.Portal",
    "SpotifyAB.SpotifyMusic",
    "Microsoft.SkypeApp",
    "Microsoft.YourPhone",
    "Microsoft.People",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.Messaging",
    "Microsoft.OneConnect",
    "Microsoft.Print3D",
    "Microsoft.Todos",
    "Microsoft.Wallet",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.3DBuilder"
)

# 現在ユーザーからAppX削除
foreach ($AppX in $AppXList) {
    Write-Host "Removing AppX: $AppX" -ForegroundColor Yellow
    Get-AppxPackage -Name $AppX -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
}

# プロビジョニングパッケージ削除（新規ユーザー対策）
foreach ($AppX in $AppXList) {
    Write-Host "Removing Provisioned Package: $AppX" -ForegroundColor Yellow
    Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq $AppX} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

Write-Host "AppX removal completed!" -ForegroundColor Green
```

#### スクリプト実行

```powershell
# 実行ポリシー一時変更
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# スクリプト実行
C:\Scripts\Remove-AppX.ps1

# 削除確認
Get-AppxPackage | Select-Object Name | Sort-Object Name
```

### AppX削除確認

```powershell
# 残存AppX確認
Get-AppxPackage | Select-Object Name, PackageFullName

# 期待される残存AppX（例）
# Microsoft.WindowsStore
# Microsoft.WindowsCalculator
# Microsoft.Windows.Photos
# Microsoft.ScreenSketch
# Microsoft.MSPaint
```

---

## Sysprep実行前チェックリスト

### 必須チェック項目（20項目）

#### Windowsシステム

- [ ] **Windows Update最新化完了**
  - 利用可能な更新プログラム: 0件
  - 保留中の再起動: なし

```powershell
# 確認コマンド
Get-WindowsUpdate
```

- [ ] **Windowsライセンス認証済み**

```powershell
slmgr /xpr
# "Windows(R), Professional edition: The machine is permanently activated."
```

- [ ] **一時ファイル削除**

```powershell
# ディスククリーンアップ実行
cleanmgr /d C:

# または手動削除
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Users\*\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
```

- [ ] **Windows イベントログクリア**

```powershell
wevtutil el | ForEach-Object {wevtutil cl "$_"}
```

- [ ] **ページングファイル最適化**

```powershell
# システム管理ページングファイル確認
Get-WmiObject Win32_PageFileSetting
```

#### アプリケーション

- [ ] **会社標準アプリ全てインストール済み**

```powershell
# インストール済みアプリ確認
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName
```

- [ ] **Microsoft 365 Apps動作確認**
  - Word起動確認
  - Excel起動確認
  - ライセンス認証未実施（Sysprep後に各PCで実施）

- [ ] **セキュリティソフト動作確認**
  - リアルタイム保護: 有効
  - 定義ファイル: 最新

- [ ] **不要なアプリアンインストール**
  - トライアルソフト
  - メーカー独自アプリ（不要な場合）

#### AppX削除

- [ ] **不要なAppX削除完了**

```powershell
Get-AppxPackage | Select-Object Name | Sort-Object Name
# Xbox, ゲーム系が含まれていないこと確認
```

- [ ] **AppXプロビジョニングパッケージ削除**

```powershell
Get-AppxProvisionedPackage -Online | Select-Object DisplayName
```

#### ユーザープロファイル

- [ ] **不要なユーザーアカウント削除**

```powershell
Get-LocalUser | Select-Object Name, Enabled
```

- [ ] **Administratorアカウントのみ残存**
  - または会社標準管理者アカウント

- [ ] **ユーザープロファイルフォルダ確認**

```powershell
Get-ChildItem C:\Users\
# Administrator（または標準管理者アカウント）、Default、Public のみ
```

#### ドライバ

- [ ] **必要なドライバ全てインストール済み**

```powershell
# 不明なデバイス確認
Get-PnpDevice | Where-Object {$_.Status -eq "Error"} | Select-Object FriendlyName, Status
```

- [ ] **グラフィックドライバ最新化**
- [ ] **ネットワークドライバ最新化**
- [ ] **チップセットドライバ最新化**

#### その他

- [ ] **ドメイン未参加**

```powershell
(Get-WmiObject Win32_ComputerSystem).Domain
# WORKGROUP であること
```

- [ ] **ネットワーク設定: DHCP**

```powershell
Get-NetIPConfiguration
# DHCP Enabled: True
```

- [ ] **Sysprep実行回数確認**（3回以下）

```powershell
# レジストリ確認
Get-ItemProperty -Path "HKLM:\SYSTEM\Setup\Status\SysprepStatus" -Name "GeneralizationState"
# Windows は最大8回までSysprep可能（通常3回以下推奨）
```

---

## unattend.xml作成と配置

### unattend.xmlとは

unattend.xml（応答ファイル）は、Windowsセットアップを自動化するXML形式の設定ファイルです。Sysprep実行時に読み込まれ、以下を自動化します：

- OOBE（初期設定）スキップ
- 自動ログオン設定
- タイムゾーン設定
- 初回起動時のスクリプト実行

### unattend.xml サンプル

```xml
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">

  <!-- Windows PE -->
  <settings pass="windowsPE">
    <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
      <UserData>
        <AcceptEula>true</AcceptEula>
      </UserData>
    </component>
  </settings>

  <!-- Specialize Pass -->
  <settings pass="specialize">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <TimeZone>Tokyo Standard Time</TimeZone>
      <RegisteredOrganization>Company Name</RegisteredOrganization>
      <RegisteredOwner>IT Department</RegisteredOwner>
    </component>

    <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <InputLocale>ja-JP</InputLocale>
      <SystemLocale>ja-JP</SystemLocale>
      <UILanguage>ja-JP</UILanguage>
      <UserLocale>ja-JP</UserLocale>
    </component>
  </settings>

  <!-- OOBE System Pass -->
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">

      <!-- OOBE設定 -->
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <ProtectYourPC>3</ProtectYourPC>
        <SkipMachineOOBE>true</SkipMachineOOBE>
        <SkipUserOOBE>true</SkipUserOOBE>
      </OOBE>

      <!-- 自動ログオン設定 -->
      <AutoLogon>
        <Enabled>true</Enabled>
        <Username>Administrator</Username>
        <Password>
          <Value>AdminPassword123!</Value>
          <PlainText>true</PlainText>
        </Password>
        <LogonCount>3</LogonCount>
      </AutoLogon>

      <!-- ローカルアカウント作成（Administratorを使用） -->
      <UserAccounts>
        <AdministratorPassword>
          <Value>AdminPassword123!</Value>
          <PlainText>true</PlainText>
        </AdministratorPassword>
      </UserAccounts>

      <!-- 初回ログオン時のコマンド実行 -->
      <FirstLogonCommands>
        <SynchronousCommand wcm:action="add">
          <Order>1</Order>
          <CommandLine>PowerShell.exe -ExecutionPolicy Bypass -File "C:\Setup\setup.ps1"</CommandLine>
          <Description>Run Setup Script</Description>
        </SynchronousCommand>
      </FirstLogonCommands>

    </component>
  </settings>

</unattend>
```

### unattend.xml 配置場所

Sysprep実行時に自動的に読み込まれる配置場所：

```
C:\Windows\System32\Sysprep\unattend.xml
```

または

```
C:\Windows\Panther\unattend.xml
```

**推奨**: `C:\Windows\System32\Sysprep\unattend.xml`

### unattend.xml 配置

```powershell
# unattend.xmlを作成（テキストエディタで上記サンプル保存）
# C:\Temp\unattend.xml

# Sysprepディレクトリにコピー
Copy-Item -Path "C:\Temp\unattend.xml" -Destination "C:\Windows\System32\Sysprep\unattend.xml" -Force

# 配置確認
Test-Path "C:\Windows\System32\Sysprep\unattend.xml"
```

### unattend.xml 検証

```powershell
# Windows System Image Manager (SIM) で検証
# Windows ADK (Assessment and Deployment Kit) に含まれる

# または XMLスキーマ検証
$xml = [xml](Get-Content "C:\Windows\System32\Sysprep\unattend.xml")
$xml.Schemas.Add("urn:schemas-microsoft-com:unattend", "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\DISM\unattend.xsd")
$xml.Validate($null)
```

---

## Sysprep実行手順

### Sysprepとは

Sysprep（System Preparation Tool）は、Windowsを一般化（Generalize）し、複数のPCに展開可能な状態にするツールです。

### Sysprep実行前の最終確認

```powershell
# 実行中のアプリケーションをすべて終了

# Windows Update確認
Get-WindowsUpdate

# AppX確認
Get-AppxPackage | Select-Object Name

# unattend.xml配置確認
Test-Path "C:\Windows\System32\Sysprep\unattend.xml"
```

### Sysprep実行（GUIモード）

1. `C:\Windows\System32\Sysprep\sysprep.exe` を起動

2. Sysprep画面で以下を選択：

```
システムクリーンアップアクション: システムのOOBE（Out-of-Box Experience）に入る
一般化する: チェック ON
シャットダウンオプション: シャットダウン
```

3. **OK** をクリック

4. Sysprep処理開始（10-20分）

5. 完了後、自動的にシャットダウン

### Sysprep実行（コマンドライン）

```powershell
# 管理者権限でコマンドプロンプト起動
C:\Windows\System32\Sysprep\sysprep.exe /oobe /generalize /shutdown

# オプション説明
# /oobe: 初回起動時にOOBEを実行
# /generalize: システムを一般化（PC固有情報削除）
# /shutdown: 完了後シャットダウン（/reboot: 再起動、/quit: 終了のみ）

# unattend.xml指定（明示的に指定する場合）
C:\Windows\System32\Sysprep\sysprep.exe /oobe /generalize /shutdown /unattend:C:\Windows\System32\Sysprep\unattend.xml
```

### Sysprep実行中の動作

1. サービス停止
2. ドライバキャッシュクリア
3. SID（セキュリティ識別子）削除
4. コンピュータ名削除
5. イベントログクリア
6. ユーザープロファイル初期化
7. システム一般化完了
8. シャットダウン

### Sysprepログ確認

Sysprep実行後、以下のログファイルで成功/失敗を確認できます：

```
C:\Windows\System32\Sysprep\Panther\setuperr.log（エラーログ）
C:\Windows\System32\Sysprep\Panther\setupact.log（実行ログ）
```

**成功時**: `setuperr.log` が空、または軽微な警告のみ
**失敗時**: `setuperr.log` にエラー詳細記録

---

## Clonezillaイメージ化手順

### Clonezilla Live USB作成

#### Rufus使用

```
1. Rufus起動
2. Device: USBメモリ選択（8GB以上）
3. Boot selection: Clonezilla ISO選択
   - ダウンロード: https://clonezilla.org/downloads.php
4. Partition scheme: MBR（BIOS/UEFI両対応）
5. File system: FAT32
6. START ボタンクリック
```

### Clonezillaブート

1. Clonezilla Live USBをマスターPCに挿入
2. 電源投入後、Boot MenuでUSBブート選択
3. Clonezillaメニュー表示

### Clonezillaメニュー操作

#### 起動モード選択

```
Clonezilla live (Default settings, VGA 1024x768)
→ Enterキー
```

#### 言語選択

```
Choose language
→ "ja_JP.UTF-8 Japanese" を選択
→ Enterキー
```

#### キーボード選択

```
キーボードレイアウト
→ "キーマップを選択しない" を選択
→ Enterキー
```

#### Clonezillaモード選択

```
Clonezilla を起動
→ "device-image ディスクまたはパーティションをイメージに保存/復元" を選択
→ Enterキー
```

#### イメージ保存先選択

**ローカルディスク使用（推奨）**:

```
mount_local_dev ローカルデバイス（例: ハードディスク、SSD、USBディスク）をマウント
→ Enterキー
```

1. 外付けUSB HDD（500GB以上推奨）を接続
2. Clonezillaがデバイス検出（10秒待機）
3. 保存先パーティション選択（例: `/dev/sdb1`）
4. マウントポイント確認（例: `/home/partimag`）

**ネットワーク経由（DRBLサーバ使用）**:

```
ssh_server SSHサーバを使う
→ Enterキー

# DRBLサーバIPアドレス入力
IP: 192.168.1.10
Port: 22
User: drbl
Password: ******

# 保存先ディレクトリ: /home/partimag
```

#### Clonezillaモード（詳細設定）

```
Beginner 初心者モード
→ Enterキー
```

#### 操作選択

```
savedisk ローカルディスクをイメージに保存
→ Enterキー
```

#### イメージ名入力

```
イメージ名を入力してください
→ 例: win11-master-20251116
→ Enterキー
```

**命名規則推奨**: `win11-master-YYYYMMDD`

#### ソースディスク選択

```
/dev/sda（マスターPCの内蔵ディスク）
→ Spaceキーで選択
→ Enterキー
```

#### チェックオプション選択

```
-fsck-src-part ソースファイルシステムをチェック・修復する（推奨）
→ Enterキー
```

#### 圧縮形式選択

```
-z1p zstd圧縮を使う（バランス型、推奨）
→ Enterキー
```

**圧縮形式比較**:

| 圧縮形式 | 圧縮率 | 展開速度 | 推奨用途 |
|---------|--------|---------|----------|
| -z0 (圧縮なし) | 最低 | 最速 | テスト環境 |
| -z1 (gzip) | 低 | 速い | 高速展開優先 |
| -z2 (bzip2) | 中 | 中速 | バランス |
| -z1p (zstd) | 中 | 速い | **推奨（バランス最良）** |
| -z5 (xz) | 最高 | 遅い | 容量優先 |

#### 分割オプション

```
イメージファイル分割（4GB以上の場合）
→ -i 2000 （2GB毎に分割、FAT32対応）
→ Enterキー
```

#### 暗号化（オプション）

```
暗号化しますか？
→ "暗号化しない" を選択（社内LAN使用のため）
→ Enterキー
```

#### イメージチェック

```
イメージ作成後にチェックしますか？
→ "-gmf イメージの修復可能性をチェック" を選択
→ Enterキー
```

#### 完了後の動作

```
完了時の動作
→ "poweroff 完了後シャットダウン" を選択
→ Enterキー
```

#### イメージ作成開始

```
準備完了。イメージ作成を開始しますか？
→ "y" を入力
→ Enterキー

最終確認
→ "y" を入力
→ Enterキー
```

### イメージ作成中

- 進捗状況表示（残り時間表示）
- 所要時間: 15-30分（ディスクサイズ・圧縮率による）
- 完了後、自動シャットダウン

### イメージファイル確認

#### ローカルディスク保存の場合

```bash
# 外付けUSB HDDをDRBLサーバに接続
sudo mount /dev/sdb1 /mnt

# イメージファイル確認
ls -lh /mnt/win11-master-20251116/

# DRBLサーバにコピー
sudo cp -r /mnt/win11-master-20251116 /home/partimag/

# 権限設定
sudo chmod -R 755 /home/partimag/win11-master-20251116

# アンマウント
sudo umount /mnt
```

#### ネットワーク保存の場合（SSH）

```bash
# DRBLサーバで確認
ls -lh /home/partimag/win11-master-20251116/
```

### イメージファイル構成

```
win11-master-20251116/
├── Info-lshw.txt          # ハードウェア情報
├── Info-packages.txt      # インストール済みパッケージ
├── blkdev.list            # ブロックデバイス一覧
├── blkid.list             # UUID一覧
├── clonezilla-img         # Clonezillaメタデータ
├── dev-fs.list            # ファイルシステム一覧
├── disk                   # ディスク情報
├── efi-nvram.dat          # UEFI NVRAM情報
├── parts                  # パーティション情報
├── sda-chs.sf             # ディスクジオメトリ
├── sda-gpt-1st           # GPT 1stセクタ
├── sda-gpt-2nd           # GPT 2ndセクタ
├── sda-hidden-data-after-mbr  # MBR後のデータ
├── sda-mbr                # MBRセクタ
├── sda1.ext4-ptcl-img.gz.aa  # パーティション1イメージ（分割1）
├── sda1.ext4-ptcl-img.gz.ab  # パーティション1イメージ（分割2）
├── sda2.ntfs-ptcl-img.gz.aa  # パーティション2イメージ（分割1）
└── sda2.ntfs-ptcl-img.gz.ab  # パーティション2イメージ（分割2）
```

---

## マスターイメージ検証

### イメージ整合性確認

```bash
# DRBLサーバで実行
sudo /usr/sbin/ocs-chkimg -b -g auto -e1 auto -e2 -nogui -i 2000 /home/partimag/win11-master-20251116

# 成功例
# Checking the image win11-master-20251116...
# Partition sda1 is OK.
# Partition sda2 is OK.
# Image win11-master-20251116 is OK!
```

### テスト展開

1. テスト用PCでPXEブート
2. Clonezillaメニューから "restoredisk" 選択
3. イメージ "win11-master-20251116" 選択
4. 展開実行
5. Windows起動確認

### 展開後確認項目

#### Windows起動確認

- [ ] Windows正常起動
- [ ] OOBE自動スキップ
- [ ] 自動ログオン成功
- [ ] デスクトップ表示

#### アプリケーション確認

- [ ] Microsoft 365 Apps起動確認
- [ ] セキュリティソフト動作確認
- [ ] PDF閲覧ソフト起動確認
- [ ] その他標準アプリ起動確認

#### システム確認

```powershell
# コンピュータ名確認（未設定、またはランダム）
hostname

# ドメイン参加状態（WORKGROUP）
(Get-WmiObject Win32_ComputerSystem).Domain

# Windows Update確認
Get-WindowsUpdate

# インストール済みアプリ確認
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName
```

#### ネットワーク確認

```powershell
# DHCP IPアドレス取得確認
Get-NetIPConfiguration

# インターネット接続確認
Test-Connection -ComputerName 8.8.8.8 -Count 4
```

### マスターイメージ承認

全確認項目をパスした場合、マスターイメージを本番環境で使用可能と承認します。

---

## マスターイメージ更新頻度と判断基準

### 更新頻度

#### 定期更新

- **3ヶ月に1回**（推奨）
- 理由: Windows Updateの累積更新、アプリケーション更新

#### 臨時更新

以下の場合、即時更新実施：

1. **重大なセキュリティ脆弱性対応**
   - Microsoft Security Updateで緊急度「緊急」
   - セキュリティソフト定義ファイル重大更新

2. **会社標準アプリケーション変更**
   - 新規アプリ追加
   - 既存アプリバージョンアップ
   - アプリ削除

3. **Windows 大型アップデート**
   - Windows 11 23H2 → 24H1 等

4. **ハードウェア変更**
   - 新しいPC機種導入
   - ドライバ追加必要

### 更新判断フローチャート

```
マスターイメージ更新必要か？
    ↓
┌─ YES ← 最終更新から3ヶ月以上経過？
│   ↓ NO
├─ YES ← 重大セキュリティ脆弱性あり？
│   ↓ NO
├─ YES ← 会社標準アプリ変更あり？
│   ↓ NO
├─ YES ← Windows大型アップデートあり？
│   ↓ NO
└─ NO ← 更新不要
    ↓
  更新実施
```

### 更新手順

1. 現在のマスターイメージバックアップ

```bash
sudo cp -r /home/partimag/win11-master-20251116 /home/partimag/backup/
```

2. テストPCに現在のマスターイメージ展開

3. Windows Update実行

4. アプリケーション更新

5. AppX削除（新規追加分があれば）

6. Sysprep実行前チェック

7. Sysprep実行

8. Clonezillaイメージ化（新しいイメージ名: win11-master-20251216）

9. テスト展開・検証

10. 本番環境適用

---

## トラブルシューティング

### Sysprep失敗: AppX関連エラー

**症状**:

```
Sysprep was not able to validate your Windows installation.
SYSPRP Failed on validate ScanState for sid
```

**原因**: 不要なAppXが残存

**対処**:

```powershell
# setuperr.log確認
Get-Content C:\Windows\System32\Sysprep\Panther\setuperr.log | Select-String "AppX"

# エラーメッセージ例:
# Package Microsoft.XboxApp_... was installed for a user, but not provisioned for all users.

# 該当AppX削除
Get-AppxPackage -Name "Microsoft.XboxApp" -AllUsers | Remove-AppxPackage
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq "Microsoft.XboxApp"} | Remove-AppxProvisionedPackage -Online

# Sysprep再実行
```

### Sysprep失敗: ドライバ関連エラー

**症状**:

```
Sysprep fails with fatal error
```

**原因**: サードパーティドライバ問題

**対処**:

```powershell
# ドライバストア確認
pnputil /enum-drivers

# 問題のあるドライバ削除
pnputil /delete-driver oem123.inf /uninstall

# Sysprep再実行
```

### Clonezillaイメージ化失敗: ディスク容量不足

**症状**:

```
Not enough space on target device
```

**対処**:

1. より大きな外付けHDD使用（500GB以上）
2. 圧縮率変更（-z1p → -z5）
3. 不要ファイル削除後、再イメージ化

### Clonezilla展開失敗: パーティションサイズ不一致

**症状**:

```
Target disk is too small
```

**対処**:

1. マスターPCより大きいディスクのPCに展開
2. または `-icds` オプション使用（Expert mode）

---

**ドキュメントバージョン**: 1.0
**最終更新日**: 2025-11-17
**作成者**: IT部門
