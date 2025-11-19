---
description: 全機能統合開発モード（10 SubAgents + 7 MCPs + Hooks）
---

**究極の開発モード**: 10体のSubAgent、7つのMCPサーバ、並列開発Hooks、標準機能のすべてを総動員します。

## 🚀 実行内容

このコマンドは、プロジェクトの全機能を統合した最強の開発環境を起動します。

---

## 📋 統合される機能

### 1️⃣ SubAgent群（10体）- 並列実行
以下のエージェントを**並列で**起動します：

#### バックエンド層（3体）
- **database-architect**: スキーマ設計・最適化
- **flask-backend-dev**: Flask管理GUI/API実装
- **api-developer**: REST APIエンドポイント開発

#### クライアント層（2体）
- **powershell-scripter**: Windows自動セットアップスクリプト
- **windows-automation**: Sysprep・unattend.xml設定

#### インフラ層（1体）
- **linux-sysadmin**: DRBL/Clonezillaサーバ設定

#### 品質保証層（2体）
- **test-engineer**: ユニット・統合テスト作成
- **integration-tester**: E2Eテストシナリオ実行

#### DevOps層（1体）
- **devops-engineer**: CI/CD設定・Docker化

#### ドキュメント層（1体）
- **documentation-writer**: 全体ドキュメント作成・更新

---

### 2️⃣ MCP統合（7サーバ）

各SubAgentが以下のMCPサーバを適切に活用：

#### Context7
- 最新ライブラリドキュメント（Flask, SQLAlchemy, PowerShell）
- ベストプラクティス・コード例

#### Serena
- コードベース全体の構造解析
- シンボル検索・依存関係追跡
- インテリジェントリファクタリング

#### Chrome DevTools
- 管理GUIの自動テスト
- UIコンポーネント動作確認
- ネットワーク監視

#### Puppeteer
- E2Eテスト自動実行
- パフォーマンス測定
- スクリーンショット取得

#### Sequential Thinking
- アーキテクチャ設計判断
- 複雑な問題の段階的解決
- トレードオフ分析

#### Memory
- 設計判断の記録
- トラブルシューティング履歴
- パフォーマンス改善記録

#### Filesystem
- プロジェクト構造管理
- ファイル一括操作
- バックアップ・リストア

---

### 3️⃣ Hooks機能（並列開発）

#### Pre-commit Hook
- Python: flake8リント自動実行
- PowerShell: 構文チェック
- JSON: 構文検証

#### Post-commit Hook
- コミット統計自動表示
- 変更ファイルタイプ検出

#### On-agent-complete Hook
- エージェント完了ログ記録
- タイプ別後処理自動実行

---

### 4️⃣ 標準機能

- Read, Write, Edit: ファイル操作
- Bash: システムコマンド実行
- Glob, Grep: 高速検索
- TodoWrite: タスク管理

---

## 🎯 実行フロー

### フェーズ1: 分析・計画（5分）

**MCP活用**:
1. **Serena** → プロジェクト構造解析
2. **Context7** → 最新技術スタック確認
3. **Sequential Thinking** → 開発戦略立案
4. **Memory** → 過去の設計判断確認

**SubAgent**:
- **documentation-writer** → 現状ドキュメント確認

---

### フェーズ2: 並列開発開始（30-60分）

**10体のSubAgentが並列実行**:

#### グループA: データベース＆API
```
database-architect   → テーブル設計
    ↓ (MCP: Serena, Context7)
flask-backend-dev    → Flask アプリ実装
    ↓ (MCP: Serena, Context7)
api-developer        → APIエンドポイント実装
    ↓ (MCP: Context7, Sequential Thinking)
```

#### グループB: クライアント
```
windows-automation   → Sysprep設定
    ↓ (MCP: Context7, Filesystem)
powershell-scripter  → 自動化スクリプト作成
    ↓ (MCP: Context7, Serena)
```

#### グループC: インフラ
```
linux-sysadmin       → DRBL設定
    ↓ (MCP: Filesystem, Memory)
```

#### グループD: 品質保証
```
test-engineer        → テスト作成
    ↓ (MCP: Serena, Context7)
integration-tester   → E2Eテスト実行
    ↓ (MCP: Puppeteer, Chrome DevTools)
```

#### グループE: DevOps
```
devops-engineer      → CI/CD設定
    ↓ (MCP: Filesystem, Sequential Thinking)
```

#### グループF: ドキュメント
```
documentation-writer → ドキュメント更新
    ↓ (MCP: Serena, Memory)
```

---

### フェーズ3: 統合・テスト（15分）

**統合テスト実行**:
1. **integration-tester** + **Puppeteer** → E2Eテスト
2. **test-engineer** → ユニット・統合テスト
3. **Chrome DevTools** → UI動作確認

**Hooks自動実行**:
- コード品質チェック（pre-commit）
- コミット統計表示（post-commit）

---

### フェーズ4: 品質評価・改善（10分）

**MCP統合評価**:
1. **Serena** → コード品質スキャン
2. **Sequential Thinking** → 改善提案
3. **Memory** → 結果記録

---

### フェーズ5: デプロイ準備（5分）

1. **devops-engineer** → デプロイパッケージ作成
2. **MCP: Filesystem** → ファイル配置確認
3. **documentation-writer** → リリースノート作成

---

## 💡 使用例

### 完全新規開発
```
/ultimate-dev
プロジェクトをゼロから完全構築してください。
要件：
- Flask管理GUI
- PC名・Serial管理
- API実装
- PowerShellスクリプト
- 完全テスト
```

### 大規模機能追加
```
/ultimate-dev
以下の機能を追加実装してください：
1. ダッシュボード画面
2. リアルタイム展開状況表示
3. メール通知機能
4. 完全自動テスト
5. ドキュメント更新
```

### 全面リファクタリング
```
/ultimate-dev
プロジェクト全体を最新ベストプラクティスに基づいてリファクタリングしてください。
- コード品質向上
- パフォーマンス最適化
- セキュリティ強化
- テスト拡充
```

---

## 📊 期待される成果物

### コード
- ✅ Flask管理GUI（完全実装）
- ✅ REST API（全エンドポイント）
- ✅ PowerShellスクリプト（完全自動化）
- ✅ データベーススキーマ（最適化済み）

### テスト
- ✅ ユニットテスト（カバレッジ80%以上）
- ✅ 統合テスト
- ✅ E2Eテスト（全シナリオ）

### インフラ
- ✅ DRBL/Clonezillaサーバ設定
- ✅ CI/CDパイプライン
- ✅ Dockerコンテナ化

### ドキュメント
- ✅ README更新
- ✅ API仕様書
- ✅ 運用マニュアル
- ✅ アーキテクチャドキュメント

---

## ⚡ パフォーマンス

### 並列実行による高速化
- 従来の逐次実行: **8-10時間**
- 並列実行: **1-2時間** （5-10倍高速化）

### リソース使用
- CPU: 並列実行で効率的活用
- メモリ: エージェント間で最適分散
- ディスク I/O: MCP Filesystemで最適化

---

## 🔒 安全性

### Git管理
- 各フェーズでコミット
- ロールバック可能

### テスト必須
- すべての実装後にテスト実行
- 失敗時は自動ロールバック

### 品質保証
- Pre-commit hookで自動チェック
- コード品質基準を満たさない場合は警告

---

**全機能を総動員した究極の開発モード。最速・最高品質でプロジェクトを完成させます。**
