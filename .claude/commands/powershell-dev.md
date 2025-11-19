---
description: PowerShell自動セットアップスクリプト開発
---

Windows初期セットアップスクリプトを開発します。

**powershell-scripter** エージェントを起動して、以下のPowerShellスクリプトを実装してください：

## スクリプト構成

### 1. メインスクリプト: Setup-AutoKitting.ps1
- Serial番号取得
- DRBL API呼び出し
- PC名設定
- ODJ適用
- 再起動制御
- Windows Update実行
- 完了ログ送信

### 2. モジュール構成
- **Get-PCInfo.ps1**: Serial取得、API通信
- **Set-ComputerName.ps1**: PC名設定
- **Apply-OfflineDomainJoin.ps1**: ODJ適用
- **Install-WindowsUpdates.ps1**: Windows Update自動化
- **Send-CompletionLog.ps1**: 完了ログAPI送信

### 3. エラーハンドリング
- API不応答時: 3回リトライ
- ODJ適用失敗: イベントログ記録
- ネットワーク切断: ログ保存・後で再送

### 4. テスト
- Pester テストスクリプト作成
- モック使用
- 異常系テスト

完了後、実行手順書も作成してください。
