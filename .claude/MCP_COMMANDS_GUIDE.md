# MCP コマンド使用ガイド

このガイドでは、7つのMCPサーバを最大限活用するための専用スラッシュコマンドの使用方法を説明します。

## 📋 コマンド一覧

### 個別MCPコマンド（7種類）

| コマンド | MCP | 主な用途 |
|---------|-----|---------|
| `/mcp-context7` | context7 | 最新ライブラリドキュメント取得 |
| `/mcp-serena` | serena | コードベース解析・リファクタリング |
| `/mcp-chrome` | chrome-devtools | ブラウザ自動化・UIテスト |
| `/mcp-puppeteer` | puppeteer | E2Eテスト自動化 |
| `/mcp-memory` | memory | プロジェクト知識記録・管理 |
| `/mcp-filesystem` | filesystem | 高度なファイルシステム操作 |
| `/mcp-thinking` | sequential-thinking | 複雑な問題の段階的解決 |

### 統合MCPコマンド（5種類）

| コマンド | 使用MCP | 主な用途 |
|---------|---------|---------|
| `/mcp-full-analysis` | 全7つ | コードベース完全分析 |
| `/mcp-code-quality` | 4つ | コード品質総合評価 |
| `/mcp-e2e-test` | 4つ | 完全E2Eテスト自動実行 |
| `/mcp-refactor` | 4つ | インテリジェントリファクタリング |
| `/mcp-deploy-check` | 全7つ | デプロイ前総合チェック |

---

## 🎯 開発フェーズ別おすすめコマンド

### フェーズ1: 設計・計画
```
/mcp-thinking
→ アーキテクチャ設計、技術選定の段階的思考

/mcp-context7
→ 使用予定ライブラリの最新ドキュメント確認

/mcp-memory
→ 過去の設計判断を確認
```

### フェーズ2: 実装
```
/mcp-serena
→ コードベース構造理解、シンボル検索

/mcp-context7
→ 実装中のコード例・ベストプラクティス取得

/mcp-filesystem
→ プロジェクト構造作成、ファイル管理
```

### フェーズ3: テスト
```
/mcp-e2e-test
→ 完全自動E2Eテスト実行

/mcp-chrome
→ UI動作確認、スクリーンショット取得

/mcp-puppeteer
→ パフォーマンステスト、回帰テスト
```

### フェーズ4: 品質改善
```
/mcp-code-quality
→ コード品質総合評価

/mcp-refactor
→ 安全なリファクタリング実行

/mcp-full-analysis
→ プロジェクト全体の包括的分析
```

### フェーズ5: デプロイ
```
/mcp-deploy-check
→ デプロイ前の全項目チェック

/mcp-memory
→ デプロイ結果・問題点の記録
```

---

## 💡 ユースケース別コマンド選択

### ケース1: Flask API開発を始める
```bash
# Step 1: 最新ドキュメント確認
/mcp-context7
Flask最新のREST API設計パターンを教えてください

# Step 2: 既存コード確認
/mcp-serena
flask-app/内の既存APIエンドポイントをすべて検索してください

# Step 3: 実装
（コード実装）

# Step 4: テスト
/mcp-e2e-test
新しいAPIエンドポイントのE2Eテストを実行してください
```

### ケース2: PowerShellスクリプト開発
```bash
# Step 1: モジュールドキュメント
/mcp-context7
PSWindowsUpdateモジュールの使い方を教えてください

# Step 2: 既存スクリプト確認
/mcp-serena
powershell-scripts/内の関数構成を解析してください

# Step 3: 実装
（スクリプト作成）

# Step 4: 品質チェック
/mcp-code-quality
作成したPowerShellスクリプトの品質を評価してください
```

### ケース3: パフォーマンス最適化
```bash
# Step 1: ボトルネック分析
/mcp-thinking
API応答時間が目標200msを超える原因を段階的に分析してください

# Step 2: コード解析
/mcp-serena
データベースクエリを実行している全コードを検索してください

# Step 3: 最適化実装
/mcp-refactor
N+1問題を検出して解消してください

# Step 4: 効果測定
/mcp-e2e-test
パフォーマンステストを実行して改善効果を確認してください

# Step 5: 結果記録
/mcp-memory
最適化内容と効果を記録してください
```

### ケース4: セキュリティ強化
```bash
# Step 1: 脆弱性分析
/mcp-thinking
このプロジェクトのセキュリティリスクを段階的に分析してください

# Step 2: コード検査
/mcp-serena
入力バリデーションが実装されていないコードを検索してください

# Step 3: ベストプラクティス確認
/mcp-context7
Flask最新のセキュリティベストプラクティスを教えてください

# Step 4: 改善実装
（セキュリティ対策実装）

# Step 5: 総合チェック
/mcp-deploy-check
セキュリティ項目を重点的にチェックしてください
```

### ケース5: リファクタリング
```bash
# Step 1: コード品質評価
/mcp-code-quality
プロジェクト全体のコード品質を評価してください

# Step 2: リファクタリング対象特定
/mcp-serena
コード重複を検出してください

# Step 3: 影響範囲確認
/mcp-serena
リファクタリング対象関数の参照元をすべて検索してください

# Step 4: 安全にリファクタリング
/mcp-refactor
コード重複を共通化してください

# Step 5: テストで確認
/mcp-e2e-test
リファクタリング後のE2Eテストを実行してください
```

---

## 🔄 複数MCPの組み合わせパターン

### パターン1: 技術調査 + 実装
```
/mcp-context7 → /mcp-serena → /mcp-refactor
最新ドキュメント → コード理解 → 実装・改善
```

### パターン2: 問題分析 + 解決
```
/mcp-thinking → /mcp-serena → /mcp-memory
段階的分析 → コード特定 → 解決策記録
```

### パターン3: 開発 + テスト
```
/mcp-context7 → (実装) → /mcp-e2e-test → /mcp-memory
ドキュメント → 実装 → テスト → 結果記録
```

### パターン4: 品質向上サイクル
```
/mcp-code-quality → /mcp-refactor → /mcp-e2e-test → /mcp-memory
評価 → 改善 → 検証 → 記録
```

---

## 📊 コマンド実行頻度の推奨

### 毎日使うコマンド
- `/mcp-serena` - コード検索・理解
- `/mcp-context7` - ドキュメント参照

### 週1回使うコマンド
- `/mcp-code-quality` - コード品質チェック
- `/mcp-e2e-test` - E2Eテスト実行

### リリース前に必ず使うコマンド
- `/mcp-deploy-check` - デプロイ前総合チェック
- `/mcp-full-analysis` - 完全分析

### 必要に応じて使うコマンド
- `/mcp-thinking` - 複雑な問題分析
- `/mcp-refactor` - リファクタリング
- `/mcp-chrome` - UI動作確認
- `/mcp-puppeteer` - パフォーマンステスト
- `/mcp-filesystem` - ファイル一括操作
- `/mcp-memory` - 重要情報記録

---

## ⚡ クイックリファレンス

### 最新ドキュメントが必要なとき
```
/mcp-context7
```

### コードを検索・解析したいとき
```
/mcp-serena
```

### ブラウザ操作を自動化したいとき
```
/mcp-chrome
```

### E2Eテストを実行したいとき
```
/mcp-puppeteer または /mcp-e2e-test
```

### 複雑な問題を段階的に解決したいとき
```
/mcp-thinking
```

### 重要な情報を記録したいとき
```
/mcp-memory
```

### ファイル操作が必要なとき
```
/mcp-filesystem
```

### プロジェクト全体を分析したいとき
```
/mcp-full-analysis
```

### コード品質を評価したいとき
```
/mcp-code-quality
```

### リファクタリングしたいとき
```
/mcp-refactor
```

### デプロイ前にチェックしたいとき
```
/mcp-deploy-check
```

---

## 🎓 ベストプラクティス

### 1. 目的に応じて適切なコマンドを選択
- 単一目的 → 個別MCPコマンド
- 包括的分析 → 統合MCPコマンド

### 2. 段階的に使用
1. 分析・理解（serena, thinking）
2. 実装（context7, serena）
3. テスト（chrome, puppeteer）
4. 改善（refactor, code-quality）
5. 記録（memory）

### 3. 記録を活用
重要な設計判断、トラブルシューティング、最適化結果は必ず`/mcp-memory`で記録

### 4. 定期的な品質チェック
週1回は`/mcp-code-quality`で品質確認

### 5. デプロイ前の確実なチェック
本番デプロイ前は必ず`/mcp-deploy-check`を実行

---

## 🚀 まとめ

- **12種類のMCPコマンド**で全MCPサーバを最大活用
- **開発フェーズ別**に最適なコマンドを選択
- **組み合わせ**で相乗効果を発揮
- **記録・改善サイクル**で継続的な品質向上

すべてのMCP機能が、スラッシュコマンド1つで簡単に利用できます！
