---
description: 本番環境準備の完全自動化（品質保証付き）
---

**本番環境準備**: 本番デプロイに必要なすべてを自動で準備・検証します。

## 🎯 目的

開発完了したコードを**本番環境に安全にデプロイ**するための全工程を自動化します。

---

## 📋 自動実行フロー

### ステップ1: 現状分析（自動）- 5分

#### MCP: Serena → コードベース全スキャン
```
✓ 全ファイル構成確認
✓ 依存関係マッピング
✓ デッドコード検出
```

#### MCP: Memory → 過去のデプロイ問題確認
```
✓ 前回デプロイの問題点
✓ 過去の失敗パターン
✓ 成功時の設定
```

#### MCP: Sequential Thinking → リスク分析
```
✓ デプロイリスク洗い出し
✓ 影響範囲分析
✓ ロールバック戦略
```

**自動出力**: リスク分析レポート

---

### ステップ2: コード品質保証（自動並列）- 15分

#### SubAgent: test-engineer
**自動実行**:
```bash
# 全ユニットテスト
pytest tests/ --cov --cov-report=html

# PowerShellテスト
pwsh -c "Invoke-Pester -Path tests/ -OutputFormat NUnitXml"

# カバレッジチェック（目標80%）
```

**自動判定**:
- ❌ カバレッジ < 80% → 追加テスト自動生成
- ✅ カバレッジ ≥ 80% → 次ステップへ

---

#### SubAgent: integration-tester（並列）
**自動実行**:
```python
# MCP: Puppeteer → 全E2Eテスト

# tests/e2e/test_production_scenarios.py
- 完全キッティングフロー
- 同時10台展開シミュレーション
- エラーハンドリング全パターン
- パフォーマンス測定
```

**自動判定**:
- ❌ テスト失敗 → 自動修正試行
- ✅ 全テスト成功 → 次ステップへ

---

#### MCP: Serena → コード品質スキャン（並列）
```
✓ PEP 8 準拠チェック（Python）
✓ PowerShell規約チェック
✓ 循環的複雑度測定
✓ コード重複検出
```

**自動判定**:
- ⚠️ 警告あり → 自動リファクタリング
- ✅ 問題なし → 次ステップへ

---

### ステップ3: セキュリティ監査（自動）- 10分

#### MCP: Sequential Thinking → 脆弱性分析
```
✓ SQLインジェクション対策確認
✓ XSS対策確認
✓ CSRF対策確認
✓ 認証・認可実装確認
✓ シークレット情報除外確認
```

#### SubAgent: devops-engineer
**自動実行**:
```bash
# 依存関係セキュリティスキャン
pip-audit

# Docker イメージスキャン
trivy image kitting-app:latest
```

**自動判定**:
- ❌ Critical脆弱性 → アップデート自動適用
- ⚠️ Medium以下 → 警告記録
- ✅ 問題なし → 次ステップへ

---

### ステップ4: パフォーマンス検証（自動）- 10分

#### SubAgent: integration-tester
**自動実行**:
```python
# MCP: Puppeteer → パフォーマンステスト

# API応答時間測定
- GET /api/pcinfo → 目標 < 200ms
- POST /api/log → 目標 < 100ms

# ページロード時間測定
- 管理GUI全ページ → 目標 < 1秒

# 同時接続テスト
- 10台同時展開シミュレーション
```

**自動判定**:
- ❌ 目標未達成 → ボトルネック特定 & 自動最適化
- ✅ 目標達成 → 次ステップへ

---

### ステップ5: 環境構築（自動）- 15分

#### SubAgent: devops-engineer
**自動実行**:

##### 1. Docker イメージビルド
```bash
# Dockerfile 最適化
docker build -t kitting-app:prod --target production .

# マルチステージビルドで軽量化
# セキュリティ強化
```

##### 2. Docker Compose設定
```yaml
# docker-compose.prod.yml 自動生成
version: '3.8'
services:
  flask-app:
    image: kitting-app:prod
    environment:
      - FLASK_ENV=production
      - DATABASE_URL=${DATABASE_URL}
    # 自動設定

  postgres:
    image: postgres:15-alpine
    # 自動設定

  nginx:
    image: nginx:alpine
    # リバースプロキシ設定自動生成
```

##### 3. CI/CD設定
```yaml
# .github/workflows/production.yml 自動生成
name: Production Deploy
on:
  push:
    tags:
      - 'v*'
jobs:
  deploy:
    # 自動設定
```

**自動出力**:
- `Dockerfile`（本番最適化版）
- `docker-compose.prod.yml`
- `.github/workflows/production.yml`
- `nginx.conf`

---

### ステップ6: データベース準備（自動）- 5分

#### SubAgent: database-architect
**自動実行**:

##### 1. マイグレーション検証
```python
# 本番DBマイグレーション準備
alembic upgrade head --sql > migration.sql

# マイグレーションSQL確認
# ロールバックSQL生成
```

##### 2. バックアップスクリプト
```bash
# backup.sh 自動生成
#!/bin/bash
pg_dump -h localhost -U user kitting_db > backup_$(date +%Y%m%d_%H%M%S).sql
```

**自動出力**:
- `migration.sql`
- `rollback.sql`
- `backup.sh`
- `restore.sh`

---

### ステップ7: ドキュメント最終化（自動）- 10分

#### SubAgent: documentation-writer
**自動生成**:

##### 1. 本番デプロイ手順書
```markdown
# 本番デプロイ手順

## 事前準備
- [ ] データベースバックアップ取得
- [ ] 環境変数設定確認
- [ ] ダウンタイム通知

## デプロイ手順
1. Dockerイメージビルド
2. データベースマイグレーション
3. コンテナ起動
4. ヘルスチェック

## ロールバック手順
（自動生成）
```

##### 2. 運用マニュアル
```markdown
# 運用マニュアル

## 日常監視項目
- API応答時間
- エラーレート
- ディスク使用量

## トラブルシューティング
（自動生成）
```

##### 3. リリースノート
```markdown
# Release v1.0.0

## 新機能
（MCP: Serena → Gitコミットから自動生成）

## バグ修正
（自動生成）

## パフォーマンス改善
（自動生成）
```

**自動出力**:
- `DEPLOY.md`
- `OPERATIONS.md`
- `CHANGELOG.md`
- `RELEASE_NOTES.md`

---

### ステップ8: 最終チェックリスト（自動検証）- 5分

#### 全項目自動検証

```
📋 コード品質
✅ ユニットテスト: 成功率 100%, カバレッジ 85%
✅ 統合テスト: 全成功
✅ E2Eテスト: 全シナリオ成功
✅ コード品質: スコア 95/100

📋 セキュリティ
✅ 脆弱性スキャン: Critical 0件
✅ シークレット除外: 確認済み
✅ 依存関係: 最新版

📋 パフォーマンス
✅ API応答時間: 平均 150ms (目標 200ms)
✅ ページロード: 平均 800ms (目標 1000ms)
✅ 同時接続: 10台問題なし

📋 環境設定
✅ Dockerfile: 最適化済み
✅ Docker Compose: 設定完了
✅ CI/CD: 設定完了
✅ Nginx: リバースプロキシ設定完了

📋 データベース
✅ マイグレーション: 準備完了
✅ バックアップ: スクリプト作成済み
✅ ロールバック: 手順確認済み

📋 ドキュメント
✅ デプロイ手順書: 完成
✅ 運用マニュアル: 完成
✅ リリースノート: 完成
✅ README: 最新版
```

**自動判定**:
- ❌ 1つでも不合格 → 該当項目を自動修正
- ✅ 全項目合格 → デプロイ準備完了

---

### ステップ9: デプロイパッケージ作成（自動）- 5分

#### SubAgent: devops-engineer
**自動実行**:

```bash
# デプロイパッケージ作成
tar -czf kitting-app-v1.0.0-production.tar.gz \
  docker-compose.prod.yml \
  .env.production \
  nginx.conf \
  migration.sql \
  backup.sh \
  DEPLOY.md \
  OPERATIONS.md

# チェックサム生成
sha256sum kitting-app-v1.0.0-production.tar.gz > checksums.txt
```

**自動出力**:
- `kitting-app-v1.0.0-production.tar.gz`
- `checksums.txt`
- `deployment-report.pdf`

---

### ステップ10: 記録（自動）- 5分

#### MCP: Memory → 永続記録
```
記録内容:
- デプロイ準備完了日時
- テスト結果サマリ
- パフォーマンス指標
- セキュリティスキャン結果
- デプロイ設定
```

---

## 📊 自動生成される成果物

### デプロイ関連
```
Dockerfile
docker-compose.prod.yml
.env.production.template
nginx.conf
migration.sql
rollback.sql
backup.sh
restore.sh
```

### CI/CD
```
.github/workflows/production.yml
.github/workflows/rollback.yml
```

### ドキュメント
```
DEPLOY.md
OPERATIONS.md
CHANGELOG.md
RELEASE_NOTES.md
deployment-report.pdf
```

### パッケージ
```
kitting-app-v1.0.0-production.tar.gz
checksums.txt
```

---

## 🎯 使用例

### 本番環境初回デプロイ準備
```
/production-ready
本番環境への初回デプロイに必要なすべてを準備してください。
- 全テスト実行
- セキュリティ監査
- パフォーマンス検証
- デプロイパッケージ作成
完全自動で実行してください。
```

### バージョンアップデプロイ準備
```
/production-ready
v1.1.0へのバージョンアップデプロイ準備をしてください。
前回（v1.0.0）からの差分を考慮して、
必要なマイグレーション、テスト、ドキュメントを自動生成してください。
```

---

## ⏱ 所要時間

| ステップ | 時間 |
|---------|------|
| 現状分析 | 5分 |
| 品質保証 | 15分 |
| セキュリティ監査 | 10分 |
| パフォーマンス検証 | 10分 |
| 環境構築 | 15分 |
| DB準備 | 5分 |
| ドキュメント | 10分 |
| 最終チェック | 5分 |
| パッケージ作成 | 5分 |
| 記録 | 5分 |
| **合計** | **約85分** |

---

## 🔒 安全性保証

### テスト必須
- ❌ テスト失敗時はデプロイ不可
- ✅ カバレッジ80%以上必須

### セキュリティ必須
- ❌ Critical脆弱性あり時はデプロイ不可
- ✅ すべて対策済み必須

### パフォーマンス必須
- ❌ 目標未達成時はデプロイ不可
- ✅ すべての目標達成必須

---

**本番環境に安全にデプロイできる状態を、完全自動で準備します。**
