# 並列開発機能ガイド

## 概要
このプロジェクトでは、複数のSubAgentを並列で実行することで開発を高速化できます。

## 並列実行可能なタスク

### 1. フロントエンド＆バックエンド同時開発
```
Agent 1: flask-backend-dev → API実装
Agent 2: documentation-writer → APIドキュメント作成
```

### 2. スクリプト＆テスト同時開発
```
Agent 1: powershell-scripter → セットアップスクリプト作成
Agent 2: test-engineer → テストスクリプト作成
```

### 3. インフラ＆アプリ同時開発
```
Agent 1: linux-sysadmin → DRBLサーバ設定
Agent 2: flask-backend-dev → 管理GUI開発
Agent 3: database-architect → DB設計
```

### 4. 複数機能並列実装
```
Agent 1: flask-backend-dev → /api/pcinfo 実装
Agent 2: api-developer → /api/log 実装
Agent 3: database-architect → テーブル作成
Agent 4: test-engineer → APIテスト作成
Agent 5: documentation-writer → API仕様書作成
```

## 使用方法

### Task ツールで並列実行
```
単一メッセージで複数のTask toolを呼び出す：
- Task 1: flask-backend-dev で API実装
- Task 2: test-engineer でテスト作成
- Task 3: documentation-writer でドキュメント作成
```

### 依存関係の管理
- **独立タスク**: 並列実行可能
- **依存タスク**: 順次実行（前のタスク完了を待つ）

## 並列開発のメリット
1. **開発速度の向上**: 複数タスクを同時進行
2. **効率的なリソース活用**: 各エージェントが専門分野に集中
3. **品質向上**: 専門エージェントによる高品質な実装

## ベストプラクティス
1. 独立したモジュール・コンポーネントは並列開発
2. 共通ファイルへの同時編集は避ける
3. API契約を先に決定してから並列実装
4. 定期的な統合テストで整合性確認

## エージェント組み合わせ例

### 初期セットアップ並列開発
1. database-architect: スキーマ設計
2. flask-backend-dev: アプリ構造作成
3. linux-sysadmin: サーバ環境構築
4. documentation-writer: セットアップガイド作成

### 機能開発並列実行
1. api-developer: REST API実装
2. powershell-scripter: クライアントスクリプト
3. test-engineer: 統合テスト
4. devops-engineer: CI/CD設定
