---
description: Chrome DevToolsでブラウザ自動化・UI自動テスト
---

**Chrome DevTools MCPサーバ**を使用して、ブラウザ自動化とUI自動テストを実行します。

## 使用方法
このコマンドの後に、実行したいブラウザ操作を指定してください。

## 主な機能

### 1. Webページ操作
- ページナビゲーション
- フォーム入力自動化
- ボタンクリック
- スクリーンショット取得

### 2. UI自動テスト
- 管理GUIの動作確認
- CSVインポート機能テスト
- APIレスポンスのブラウザ表示確認

### 3. デバッグ・検証
- コンソールログ取得
- ネットワークリクエスト監視
- パフォーマンス測定

### 4. スクレイピング
- ページコンテンツ抽出
- データ収集

## 利用可能な主要ツール

- `mcp__chrome-devtools__navigate_page`: ページ遷移
- `mcp__chrome-devtools__take_snapshot`: ページスナップショット
- `mcp__chrome-devtools__take_screenshot`: スクリーンショット
- `mcp__chrome-devtools__click`: 要素クリック
- `mcp__chrome-devtools__fill`: フォーム入力
- `mcp__chrome-devtools__fill_form`: フォーム一括入力
- `mcp__chrome-devtools__list_network_requests`: ネットワーク監視
- `mcp__chrome-devtools__list_console_messages`: コンソールログ
- `mcp__chrome-devtools__evaluate_script`: JavaScript実行

## 例

### 管理GUI動作確認
```
/mcp-chrome
Flask管理GUIを起動し、ログイン画面からPC一覧画面まで自動操作してスクリーンショットを取得してください
```

### CSVインポートテスト
```
/mcp-chrome
管理GUIでCSVインポート機能をテストし、正常にデータが登録されるか確認してください
```

### API呼び出し確認
```
/mcp-chrome
ブラウザから /api/pcinfo?serial=ABC123456 を呼び出し、レスポンスを確認してください
```

### UI要素検証
```
/mcp-chrome
管理GUI全ページのスクリーンショットを取得し、レイアウト崩れがないか確認してください
```

Chrome DevToolsで実際のブラウザ操作を自動化し、UI品質を確保します。
