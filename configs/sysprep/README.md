# Sysprep unattend.xml使用ガイド

**バージョン**: 1.0
**最終更新**: 2025-11-17

---

## 概要

本ディレクトリには、Windows 11マスターイメージ作成時に使用するSysprep応答ファイル（unattend.xml）が含まれています。

## ファイル一覧

- **unattend.xml**: Sysprep実行時の自動応答ファイル

---

## unattend.xmlの役割

### 1. 初回起動時の自動化

- 言語・地域・タイムゾーンの自動設定
- 管理者アカウントの自動作成
- 自動ログオン設定（初回3回）
- PowerShell自動セットアップスクリプトの実行

### 2. OOBE（Out-Of-Box Experience）のスキップ

- ネットワーク接続画面のスキップ
- Microsoftアカウント作成のスキップ
- プライバシー設定のスキップ
- EULA同意画面のスキップ

### 3. 会社標準設定の適用

- タイムゾーン: 日本標準時（Tokyo Standard Time）
- 言語: 日本語（ja-JP）
- 初回起動時コマンド実行（FirstLogonCommands）

---

## 使用方法

### 1. マスターPC構築時の配置

**Sysprep実行前**に以下のパスへ配置：

```powershell
# PowerShell（管理者権限）で実行
Copy-Item -Path "C:\Temp\unattend.xml" `
          -Destination "C:\Windows\System32\Sysprep\unattend.xml" `
          -Force
```

### 2. Sysprep実行

```powershell
C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown /unattend:C:\Windows\System32\Sysprep\unattend.xml
```

### 3. イメージ展開後の自動処理

Clonezillaでイメージ展開後、初回起動時に以下が自動実行されます：

1. **PowerShell実行ポリシー変更** → Bypass設定
2. **自動セットアップスクリプト実行** → `C:\AutoSetup\setup.ps1`
3. **タスクスケジューラ登録** → 再起動後の継続処理

---

## カスタマイズ方法

### 1. 管理者アカウント名・パスワード変更

**現在の設定**:
- ユーザー名: `SetupAdmin`
- パスワード: `TempPass123!`（Base64エンコード済み）

**変更手順**:

1. 新しいパスワードをBase64エンコード:

```powershell
# PowerShellで実行
$Password = "NewPassword123!"
$EncodedPassword = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Password + "Password"))
Write-Host $EncodedPassword
```

2. unattend.xmlの該当箇所を変更:

```xml
<LocalAccount wcm:action="add">
    <Password>
        <Value>エンコード結果をここに貼り付け</Value>
        <PlainText>false</PlainText>
    </Password>
    <Name>新しいユーザー名</Name>
</LocalAccount>
```

### 2. プロダクトキー設定

ボリュームライセンスキーを使用する場合:

```xml
<component name="Microsoft-Windows-Shell-Setup" ... pass="specialize">
    <ProductKey>XXXXX-XXXXX-XXXXX-XXXXX-XXXXX</ProductKey>
</component>
```

### 3. タイムゾーン変更

別のタイムゾーンに変更する場合:

```xml
<TimeZone>Pacific Standard Time</TimeZone>
```

利用可能なタイムゾーン一覧:

```powershell
# PowerShellで確認
Get-TimeZone -ListAvailable | Select-Object Id, DisplayName
```

### 4. FirstLogonCommandsのカスタマイズ

独自のコマンドを追加する場合:

```xml
<SynchronousCommand wcm:action="add">
    <Order>6</Order>
    <CommandLine>powershell.exe -Command "独自の処理"</CommandLine>
    <Description>Custom Command</Description>
    <RequiresUserInput>false</RequiresUserInput>
</SynchronousCommand>
```

**注意**: `<Order>`番号は既存コマンドと重複しないように設定。

---

## 自動実行されるスクリプト

### C:\AutoSetup\setup.ps1（メインスクリプト）

**実行タイミング**: 初回ログオン時（FirstLogonCommands）

**主要処理**:
1. Serial番号取得（`Get-CimInstance Win32_BIOS`）
2. DRBL API呼び出し（`/api/pcinfo?serial=XXX`）
3. PC名設定（`Rename-Computer`）
4. ODJファイル取得・適用（`djoin /requestODJ /loadfile`）
5. 再起動

### C:\AutoSetup\post-reboot.ps1（再起動後スクリプト）

**実行タイミング**: 再起動後のログオン時（タスクスケジューラ）

**主要処理**:
1. ドメイン参加確認
2. Windows Update実行
3. 会社標準アプリケーションインストール
4. 完了ログ送信（`/api/log`）
5. タスク削除

---

## トラブルシューティング

### 症状: Sysprep実行時に「unattend.xmlが無効です」エラー

**原因**: XML構文エラーまたはスキーマ不一致

**解決策**:

1. XML構文チェック:

```powershell
# PowerShellで検証
[xml]$xml = Get-Content "C:\Windows\System32\Sysprep\unattend.xml"
$xml
```

2. Microsoftツールで検証:

```bash
# Windows System Image Manager (WSIM) を使用
# Windows ADKに含まれる
```

### 症状: 初回起動時にスクリプトが実行されない

**確認箇所**:

1. `C:\AutoSetup\setup.ps1` が存在するか確認
2. イベントログ確認:

```powershell
Get-EventLog -LogName Application -Source "Windows Error Reporting" -Newest 50
```

3. FirstLogonCommandsログ確認:

```powershell
Get-Content "C:\AutoSetup\setup.log"
```

### 症状: 自動ログオンが動作しない

**原因**: パスワードエンコードミスまたはアカウント作成失敗

**解決策**:

1. ログオン画面で手動ログイン:
   - ユーザー名: `SetupAdmin`
   - パスワード: `TempPass123!`

2. イベントログでアカウント作成確認:

```powershell
Get-WinEvent -LogName Security | Where-Object {$_.Id -eq 4720} | Select-Object -First 10
```

---

## セキュリティ考慮事項

### パスワード管理

- **重要**: unattend.xmlには管理者パスワードが含まれます
- マスターイメージ作成後、unattend.xmlを削除推奨:

```powershell
Remove-Item "C:\Windows\System32\Sysprep\unattend.xml" -Force -ErrorAction SilentlyContinue
```

### 自動ログオン無効化

- FirstLogonCommands完了後、自動ログオンは自動的に無効化（LogonCount=3）
- 手動で無効化する場合:

```powershell
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /f
```

---

## 検証方法

### 1. 仮想環境でのテスト

```bash
# VirtualBox VMでテスト
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project
./scripts/setup-test-vm.sh Win11-Sysprep-Test
```

### 2. unattend.xml適用確認

**Sysprep実行後**、初回起動時に以下を確認:

- [ ] 言語が日本語（ja-JP）
- [ ] タイムゾーンが日本標準時
- [ ] 自動ログオン成功（SetupAdminアカウント）
- [ ] `C:\AutoSetup\setup.log` が生成される
- [ ] スクリプトが実行される（イベントログ確認）

---

## 参考リンク

- [Microsoft: unattend.xml公式リファレンス](https://docs.microsoft.com/ja-jp/windows-hardware/customize/desktop/unattend/)
- [Microsoft: Sysprep コマンドライン オプション](https://docs.microsoft.com/ja-jp/windows-hardware/manufacture/desktop/sysprep-command-line-options)
- [Microsoft: Windows System Image Manager (WSIM)](https://docs.microsoft.com/ja-jp/windows-hardware/manufacture/desktop/update-windows-settings-and-scripts-create-your-own-answer-file-sxs)

---

## 改訂履歴

| バージョン | 日付 | 変更内容 |
|------------|------|----------|
| 1.0 | 2025-11-17 | 初版作成 |

---

**作成者**: API開発チーム
