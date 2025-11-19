# タスク完了時のチェックリスト

## コード変更後の必須手順

### 1. コード品質チェック
```bash
# リント実行
python -m pyflakes flask-app/

# 必要に応じてフォーマット
# black flask-app/
```

### 2. テスト実行
```bash
# 全テスト実行
pytest tests/

# カバレッジ確認
pytest --cov=flask-app --cov-report=term
```

### 3. マニュアルテスト（必要に応じて）
```bash
# 開発サーバ起動
cd flask-app
source venv/bin/activate
flask run --host=0.0.0.0 --port=5000

# ブラウザでアクセス: http://192.168.3.135:5000/
```

### 4. API動作確認（API変更時）
```bash
# GET /api/pcinfo
curl "http://localhost:5000/api/pcinfo?serial=TEST123456"

# POST /api/log
curl -X POST http://localhost:5000/api/log \
  -H "Content-Type: application/json" \
  -d '{"serial":"TEST123456","pcname":"20251116M","status":"completed","timestamp":"2025-11-16 12:33:22"}'
```

### 5. データベースマイグレーション（モデル変更時）
```bash
# マイグレーションファイル作成
flask db migrate -m "変更内容の説明"

# マイグレーション適用
flask db upgrade
```

### 6. ドキュメント更新（必要に応じて）
- README.mdの更新
- API仕様書の更新（docs/api/）
- CLAUDE.mdの更新（プロジェクト全体に影響する変更の場合）

### 7. Git コミット
```bash
# 変更ファイル確認
git status
git diff

# ステージング
git add .

# コミット（適切なメッセージで）
git commit -m "feat: 新機能の説明"

# プッシュ
git push origin main
```

## 機能追加時の追加チェック

### 新規APIエンドポイント追加時
- [ ] API仕様書を作成・更新
- [ ] ユニットテスト作成
- [ ] 統合テスト作成
- [ ] エラーハンドリング実装
- [ ] ロギング実装
- [ ] CORS設定確認

### 新規モデル追加時
- [ ] モデルクラス実装
- [ ] マイグレーションファイル作成
- [ ] モデルテスト作成
- [ ] リレーションシップ確認
- [ ] インデックス設定

### 新規PowerShellスクリプト追加時
- [ ] エラーハンドリング実装
- [ ] リトライロジック実装
- [ ] ログ記録実装
- [ ] テストスクリプト作成
- [ ] ドキュメント作成

## バグ修正時のチェック

### 必須手順
- [ ] バグの原因特定
- [ ] 修正実装
- [ ] **リグレッションテスト追加**（同じバグが再発しないように）
- [ ] 関連テスト実行
- [ ] 修正内容のドキュメント化

## デプロイ前の最終チェック

### 開発環境→本番環境
- [ ] 全テストパス確認
- [ ] カバレッジ確認（推奨: 80%以上）
- [ ] 環境変数設定確認（.env.prod）
- [ ] データベースバックアップ
- [ ] ログレベル設定確認（本番: WARNING以上）
- [ ] セキュリティ設定確認
- [ ] パフォーマンステスト実行
- [ ] デプロイスクリプト実行

```bash
# 本番環境デプロイ
sudo ./production/scripts/deploy.sh

# サービス再起動
sudo systemctl restart pcsetup-flask
sudo systemctl restart nginx
```

## パフォーマンス最適化時

### 測定
```bash
# ベンチマークテスト実行
pytest tests/performance/ --benchmark-only

# メモリプロファイリング
python -m memory_profiler flask-app/app.py
```

### 確認項目
- [ ] API応答時間: 200ms以下
- [ ] メモリ使用量の妥当性
- [ ] データベースクエリ最適化
- [ ] インデックス設定

## セキュリティチェック

### 確認項目
- [ ] SQL インジェクション対策
- [ ] XSS対策
- [ ] CSRF対策（必要に応じて）
- [ ] 認証・認可（必要に応じて）
- [ ] 機密情報のハードコード防止
- [ ] 環境変数での設定管理

## トラブルシューティング

### テスト失敗時
```bash
# 詳細出力で再実行
pytest -vv tests/

# 失敗したテストのみ再実行
pytest --lf

# ログ出力を確認
pytest -s tests/
```

### サーバ起動失敗時
```bash
# ログ確認
sudo journalctl -u pcsetup-flask -n 50

# ポート使用確認
sudo netstat -tlnp | grep :5000
```

### データベースエラー時
```bash
# マイグレーション状態確認
flask db current

# マイグレーション履歴
flask db history

# ロールバック
flask db downgrade
```
