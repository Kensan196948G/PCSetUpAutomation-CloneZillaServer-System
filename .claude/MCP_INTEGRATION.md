# MCP統合設定ガイド

## 概要
このプロジェクトでは、以下のMCP (Model Context Protocol) サーバを統合し、開発効率を最大化します。

## 接続済みMCPサーバ

### 1. context7
**用途**: 最新ライブラリのドキュメント・コード例取得

**使用場面**:
- Flask、SQLAlchemy等のPythonライブラリ最新ドキュメント
- PowerShellモジュール（PSWindowsUpdate等）のリファレンス
- Bootstrap、JavaScript等のフロントエンド技術

**使用例**:
```
Flask最新のBlueprint設計パターンを context7 から取得
SQLAlchemy最新のマイグレーション手法を確認
```

**推奨エージェント**: flask-backend-dev, api-developer, powershell-scripter

---

### 2. chrome-devtools
**用途**: ブラウザ自動化、Web UI テスト

**使用場面**:
- Flask管理GUIの自動テスト
- API呼び出しのブラウザシミュレーション
- UI/UXの動作確認
- スクリーンショット取得

**使用例**:
```
管理GUI画面の自動操作テスト
CSVインポート機能の動作確認
APIレスポンスのブラウザ表示確認
```

**推奨エージェント**: test-engineer, integration-tester

---

### 3. serena
**用途**: セマンティックコード解析・編集

**使用場面**:
- コードベース全体の構造理解
- シンボル検索・リファクタリング
- コード品質分析
- 依存関係の追跡

**使用例**:
```
Flask app.py の全関数一覧を取得
特定のAPI関数を呼び出している箇所を検索
データベースモデルの関連を解析
```

**推奨エージェント**: 全エージェント（コード解析時）

---

### 4. sequential-thinking
**用途**: 段階的思考、複雑な問題解決

**使用場面**:
- アーキテクチャ設計の意思決定
- 複雑なバグの原因調査
- パフォーマンス最適化戦略
- セキュリティリスク分析

**使用例**:
```
PXEブート〜ドメイン参加までのフロー最適化
エラーハンドリング戦略の設計
同時展開時のボトルネック分析
```

**推奨エージェント**: database-architect, devops-engineer, integration-tester

---

### 5. memory
**用途**: プロジェクトメモリ管理、長期コンテキスト保持

**使用場面**:
- プロジェクト設計判断の記録
- 重要な技術選定理由の保存
- トラブルシューティング履歴
- アーキテクチャ変更履歴

**使用例**:
```
「なぜSQLiteを選択したか」を記録
API設計の変更履歴を保存
パフォーマンスチューニングの結果を記録
```

**推奨エージェント**: documentation-writer, database-architect

---

### 6. filesystem
**用途**: 高度なファイルシステム操作

**使用場面**:
- ディレクトリ構造の作成
- 大量ファイルの一括操作
- ファイル検索・フィルタリング
- バックアップ・リストア

**使用例**:
```
プロジェクト構造の一括作成
ODJファイル群の管理
ログファイルの整理
設定ファイルのバックアップ
```

**推奨エージェント**: devops-engineer, linux-sysadmin

---

### 7. puppeteer
**用途**: ヘッドレスブラウザ自動化

**使用場面**:
- E2Eテスト自動化
- スクリーンショット取得
- PDFレポート生成
- Web スクレイピング（ChatGPT OCR結果取得等）

**使用例**:
```
管理GUIの全画面スクリーンショット
ログインフローの自動テスト
レポートPDF自動生成
```

**推奨エージェント**: test-engineer, integration-tester

---

## MCPサーバの組み合わせ活用例

### 例1: Flask API開発
```
1. context7 → Flask最新ドキュメント取得
2. serena → 既存コード構造解析
3. filesystem → 新規ファイル作成
4. chrome-devtools → APIテスト実行
```

### 例2: PowerShellスクリプト開発
```
1. context7 → PowerShellモジュールドキュメント
2. serena → 既存スクリプト解析
3. filesystem → スクリプトファイル配置
4. memory → 設計判断記録
```

### 例3: 統合テスト
```
1. puppeteer → E2Eテスト自動化
2. chrome-devtools → ブラウザ動作確認
3. serena → テスト対象コード理解
4. sequential-thinking → テストシナリオ設計
```

### 例4: デプロイメント
```
1. filesystem → ファイル配置・バックアップ
2. serena → 依存関係確認
3. memory → デプロイ履歴記録
4. sequential-thinking → ロールバック戦略
```

---

## MCPサーバ使用のベストプラクティス

### 1. 適切なツール選択
- コード理解: **serena**
- 最新ドキュメント: **context7**
- ブラウザ操作: **chrome-devtools** or **puppeteer**
- 複雑な思考: **sequential-thinking**
- 履歴管理: **memory**

### 2. 並列活用
複数のMCPサーバを同時に活用することで効率化：
```
context7でドキュメント取得 + serenaでコード解析
→ 包括的な理解
```

### 3. メモリ活用
重要な設計判断は**memory**に保存：
- API設計の変更理由
- パフォーマンス最適化の結果
- セキュリティ対策の実装内容

### 4. テスト自動化
**puppeteer** + **chrome-devtools** で完全自動化：
- ユニットテスト: pytest
- 統合テスト: API呼び出し
- E2Eテスト: ブラウザ自動操作

---

## トラブルシューティング

### MCPサーバが応答しない場合
1. 接続状態を確認
2. MCPサーバを再起動
3. ネットワーク設定を確認

### パフォーマンスが低下した場合
1. 不要なMCPサーバを無効化
2. キャッシュをクリア
3. 並列実行数を調整

---

## 設定ファイル

MCP設定は `.claude/settings.json` で管理されています。
各MCPサーバの有効/無効は以下で切り替え可能：

```json
{
  "mcp": {
    "servers": {
      "context7": { "enabled": true },
      "chrome-devtools": { "enabled": true },
      "serena": { "enabled": true },
      "sequential-thinking": { "enabled": true },
      "memory": { "enabled": true },
      "filesystem": { "enabled": true },
      "puppeteer": { "enabled": true }
    }
  }
}
```

---

## まとめ

7つのMCPサーバを統合することで、以下が実現します：
- **開発効率の向上**: 最新ドキュメント即座にアクセス
- **コード品質の向上**: セマンティック解析で深い理解
- **テスト自動化**: ブラウザ自動化で完全E2Eテスト
- **知識の蓄積**: メモリ管理で設計判断を記録
- **複雑な問題解決**: 段階的思考で最適解を導出

すべてのSubAgentがこれらのMCPサーバを活用し、最高品質のコードを生産します。
