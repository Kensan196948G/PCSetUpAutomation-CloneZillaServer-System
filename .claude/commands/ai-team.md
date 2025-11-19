---
description: AIチーム開発モード（10人の専門家が協力）
---

**AIチーム開発**: 10体のSubAgentを人間のチームのように協調させて開発します。

## 👥 チーム構成

このコマンドは、10体のSubAgentを**実際の開発チーム**のように組織化します。

---

## 🏢 組織構造

### マネジメント層
**documentation-writer** - プロジェクトマネージャー役
- 全体進捗管理
- 要件整理
- 成果物まとめ

---

### 開発チーム A: バックエンド（3名）

#### 1. database-architect（DB専門家）
**役割**: データベース設計のスペシャリスト
**使用MCP**:
- Context7 → SQLAlchemy最新ドキュメント
- Serena → 既存スキーマ解析
- Sequential Thinking → 正規化・インデックス戦略

**担当**:
- テーブル設計
- マイグレーション作成
- クエリ最適化

---

#### 2. flask-backend-dev（Flaskエンジニア）
**役割**: Flask Webアプリケーション開発
**使用MCP**:
- Context7 → Flask最新パターン
- Serena → コード構造理解
- Chrome DevTools → 動作確認

**担当**:
- 管理GUI実装
- テンプレート作成
- セッション管理

---

#### 3. api-developer（API専門家）
**役割**: REST API設計・実装
**使用MCP**:
- Context7 → REST API ベストプラクティス
- Serena → APIエンドポイント解析
- Puppeteer → APIテスト

**担当**:
- エンドポイント実装
- バリデーション
- APIドキュメント

---

### 開発チーム B: クライアント（2名）

#### 4. windows-automation（Windows専門家）
**役割**: Windows自動化のエキスパート
**使用MCP**:
- Context7 → Sysprep最新情報
- Filesystem → unattend.xml管理

**担当**:
- Sysprep設定
- unattend.xml作成
- 自動ログオン設定

---

#### 5. powershell-scripter（PowerShell開発者）
**役割**: PowerShellスクリプト開発
**使用MCP**:
- Context7 → PowerShellモジュール
- Serena → スクリプト構造解析

**担当**:
- 初期セットアップスクリプト
- API連携
- エラーハンドリング

---

### インフラチーム（1名）

#### 6. linux-sysadmin（インフラエンジニア）
**役割**: サーバ構築・運用
**使用MCP**:
- Filesystem → 設定ファイル管理
- Memory → 構築手順記録
- Sequential Thinking → トラブルシューティング

**担当**:
- DRBL/Clonezillaサーバ設定
- ネットワーク設定
- セキュリティ設定

---

### QAチーム（2名）

#### 7. test-engineer（テストエンジニア）
**役割**: テスト設計・実装
**使用MCP**:
- Context7 → pytest/Pester最新
- Serena → テスト対象コード理解

**担当**:
- ユニットテスト
- 統合テスト
- テストカバレッジ

---

#### 8. integration-tester（QAリード）
**役割**: 品質保証責任者
**使用MCP**:
- Puppeteer → E2Eテスト自動化
- Chrome DevTools → UI検証
- Sequential Thinking → テスト戦略

**担当**:
- E2Eテストシナリオ
- パフォーマンステスト
- 品質レポート

---

### DevOpsチーム（1名）

#### 9. devops-engineer（DevOpsエンジニア）
**役割**: CI/CD・デプロイ自動化
**使用MCP**:
- Filesystem → デプロイパッケージ管理
- Sequential Thinking → デプロイ戦略
- Memory → デプロイ履歴記録

**担当**:
- CI/CD設定
- Docker化
- デプロイ自動化

---

### ドキュメントチーム（1名）

#### 10. documentation-writer（テクニカルライター）
**役割**: ドキュメント作成・管理
**使用MCP**:
- Serena → コードからドキュメント生成
- Memory → 設計判断記録
- Filesystem → ドキュメント管理

**担当**:
- README作成
- API仕様書
- 運用マニュアル

---

## 🔄 協調開発フロー

### スプリント1: 設計フェーズ（Day 1）

#### 朝会（キックオフ）
```
documentation-writer（PM）: 要件整理・タスク分配
    ↓
database-architect: スキーマ設計
    ↓ (設計書共有)
flask-backend-dev: アプリ構造設計
api-developer: API仕様設計
    ↓ (API契約合意)
powershell-scripter: スクリプト設計
windows-automation: Sysprep設計
```

#### 並列作業
- **database-architect** + **MCP: Sequential Thinking** → DB正規化
- **api-developer** + **MCP: Context7** → RESTful設計
- **documentation-writer** → 設計書ドラフト作成

#### 夕会（レビュー）
- 全員で設計レビュー
- **MCP: Memory** → 設計判断を記録

---

### スプリント2: 実装フェーズ（Day 2-3）

#### 朝会（タスク確認）
```
PM: 実装タスク確認
    ↓
各メンバー: 並列実装開始
```

#### 並列実装（チーム別）

**バックエンドチーム**:
```
database-architect → マイグレーション作成
    ↓ (MCP: Serena)
flask-backend-dev → GUI実装
    ↓ (MCP: Context7, Chrome DevTools)
api-developer → エンドポイント実装
    ↓ (MCP: Context7)
```

**クライアントチーム**:
```
windows-automation → unattend.xml作成
    ↓ (MCP: Filesystem)
powershell-scripter → スクリプト実装
    ↓ (MCP: Context7, Serena)
```

**インフラチーム**:
```
linux-sysadmin → DRBLサーバ構築
    ↓ (MCP: Filesystem, Memory)
```

**QAチーム**:
```
test-engineer → テスト作成（並行）
    ↓ (MCP: Context7)
integration-tester → E2Eシナリオ準備
    ↓ (MCP: Puppeteer)
```

#### 統合（継続的）
- **Hooks: pre-commit** → コード品質自動チェック
- 各メンバーのコミット後、自動的にCI実行

#### 夕会（進捗共有）
- 各チームの進捗報告
- ブロッカー解消
- **documentation-writer** → 進捗ドキュメント更新

---

### スプリント3: テスト・統合フェーズ（Day 4）

#### 朝会（テスト計画）
```
integration-tester（QAリード）: テスト計画説明
    ↓
全メンバー: テスト協力
```

#### テスト実行
```
test-engineer → ユニット・統合テスト
    ↓
integration-tester → E2Eテスト
    ↓ (MCP: Puppeteer, Chrome DevTools)
    ↓
バグ検出
    ↓
該当メンバーが修正（並列）
    ↓
再テスト
```

#### 品質評価
```
integration-tester + MCP: Sequential Thinking
    → 品質レポート作成
```

---

### スプリント4: デプロイフェーズ（Day 5）

#### デプロイ準備
```
devops-engineer: デプロイパッケージ準備
    ↓ (MCP: Filesystem)
integration-tester: 最終テスト
    ↓
PM: デプロイ承認
    ↓
devops-engineer: デプロイ実行
    ↓ (MCP: Memory → デプロイ履歴記録)
```

#### ドキュメント最終化
```
documentation-writer:
    - README更新
    - リリースノート作成
    - 運用マニュアル最終化
    ↓ (MCP: Serena → コードから自動生成)
```

---

## 💬 チームコミュニケーション

### API契約（インターフェース）
- **api-developer** ↔ **powershell-scripter**
  - API仕様を先に確定
  - 並列で実装

### データベーススキーマ
- **database-architect** ↔ **flask-backend-dev**
  - スキーマ確定後、並列実装

### テストフィードバック
- **QAチーム** ↔ **開発チーム**
  - バグレポート → 即座に修正

---

## 📊 成果物（5日間で完成）

### Day 1: 設計書
- DB設計書
- API仕様書
- アーキテクチャドキュメント

### Day 2-3: 実装
- Flask管理GUI（完成）
- REST API（完成）
- PowerShellスクリプト（完成）
- DRBL設定（完成）

### Day 4: テスト
- ユニットテスト（カバレッジ80%+）
- E2Eテスト（全シナリオ）
- 品質レポート

### Day 5: デプロイ
- 本番デプロイ
- ドキュメント完成
- リリースノート

---

## 🎯 使用例

### 新規プロジェクト立ち上げ
```
/ai-team
新規プロジェクトを5日間で完成させてください。
10人のAIチームで協力して、設計→実装→テスト→デプロイまで完遂してください。
```

### 大規模機能追加
```
/ai-team
以下の機能をチーム開発で実装してください：
1. ダッシュボード（flask-backend-dev, api-developer）
2. リアルタイム通知（powershell-scripter）
3. 完全テスト（QAチーム）
4. ドキュメント（documentation-writer）
```

---

**10人の専門家AIチームが協力して、最高品質のプロダクトを最速で完成させます。**
