# Clonezillaイメージパス設定機能 - 実装完了レポート

## 実装概要

Clonezillaイメージパスの動的設定・検証機能を完全実装しました。この機能により、管理者はWeb UIからClonezillaイメージの格納パスを変更・検証できます。

## 実装日時

2025-11-17

## 実装内容

### 1. 新規APIエンドポイント

**ファイル**: `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/flask-app/api/settings.py`

#### エンドポイント一覧

| エンドポイント | メソッド | 説明 |
|--------------|---------|------|
| `/api/settings` | GET | 現在の設定を取得 |
| `/api/settings/image-path` | POST | イメージパスを更新 |
| `/api/settings/image-path/validate` | POST | パスの検証 |

#### GET /api/settings

**レスポンス例**:
```json
{
  "clonezilla_image_path": "/mnt/Linux-ExHDD/Ubuntu-ExHDD",
  "odj_files_path": "/srv/odj/",
  "api_port": 5000,
  "api_host": "0.0.0.0"
}
```

#### POST /api/settings/image-path

**リクエスト**:
```json
{
  "path": "/mnt/Linux-ExHDD/Ubuntu-ExHDD"
}
```

**レスポンス（成功）**:
```json
{
  "success": true,
  "message": "イメージパスを更新しました",
  "new_path": "/mnt/Linux-ExHDD/Ubuntu-ExHDD"
}
```

**レスポンス（エラー）**:
```json
{
  "error": "パスが存在しません: /invalid/path"
}
```

#### POST /api/settings/image-path/validate

**リクエスト**:
```json
{
  "path": "/mnt/Linux-ExHDD/Ubuntu-ExHDD"
}
```

**レスポンス（成功）**:
```json
{
  "valid": true,
  "path": "/mnt/Linux-ExHDD/Ubuntu-ExHDD",
  "writable": true,
  "image_count": 5,
  "disk_free": {
    "free": "123.45 GB",
    "total": "500.00 GB",
    "used": "376.55 GB",
    "percent_used": "75.3%"
  }
}
```

**レスポンス（エラー）**:
```json
{
  "valid": false,
  "error": "パスが存在しません"
}
```

### 2. バリデーション機能

実装された検証項目:
- パスの存在確認
- ディレクトリチェック
- 読み取り権限確認
- 書き込み権限確認
- ディスク容量取得
- イメージ数カウント

### 3. Web UI拡張

**ファイル**: `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/flask-app/templates/deployment/settings.html`

#### 新規追加UIコンポーネント

1. **イメージパス入力フィールド**
   - 現在のパス表示
   - パス編集機能
   - プレースホルダー: `/mnt/Linux-ExHDD/Ubuntu-ExHDD`

2. **検証ボタン**
   - パスの即座検証
   - リアルタイムフィードバック
   - ローディング状態表示

3. **更新ボタン**
   - パス変更確認ダイアログ
   - .envファイル永続化
   - 成功/エラー通知

4. **パス情報表示パネル**
   - 検証されたパス
   - 書き込み権限状態
   - イメージ数
   - 空き容量
   - 使用容量
   - 合計容量
   - 使用率（色分け表示）

#### JavaScript機能

- **パス検証処理**
  - フェッチAPIによる非同期検証
  - ローディング表示
  - エラーハンドリング
  - 結果の視覚的フィードバック

- **パス更新処理**
  - 確認ダイアログ
  - 非同期更新
  - ボタン状態管理（無効化/有効化）
  - ページリロード

- **使用率色分け**
  - 60%未満: 成功（緑）
  - 60-80%: 警告（黄）
  - 80%以上: 危険（赤）

### 4. 環境変数設定

#### 開発環境（.env）

**ファイル**: `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/flask-app/.env`

新規作成し、以下を設定:
```env
CLONEZILLA_IMAGE_PATH=/mnt/Linux-ExHDD/Ubuntu-ExHDD
```

#### 本番環境（.env.production）

**ファイル**: `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/.env.production`

既存ファイルに追加:
```env
CLONEZILLA_IMAGE_PATH=/mnt/Linux-ExHDD/Ubuntu-ExHDD
```

### 5. 設定ファイル更新

#### config.py

**変更内容**: .envファイル読み込みロジック改善

```python
# Load environment variables
basedir = Path(__file__).resolve().parent.parent
app_dir = Path(__file__).resolve().parent
load_dotenv(app_dir / '.env')  # Load from flask-app/.env first
load_dotenv(basedir / '.env')  # Then load from production/.env (can override)
```

これにより、開発環境と本番環境の両方の.envファイルを読み込み可能になりました。

#### views/deployment.py

**変更内容**: deploy_settings関数にconfigを渡すよう更新

```python
from flask import current_app

def deploy_settings():
    """Deployment settings page."""
    return render_template('deployment/settings.html', config=current_app.config)
```

### 6. API Blueprint登録

**ファイル**: `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/flask-app/api/__init__.py`

```python
from . import settings  # noqa: F401, E402
```

### 7. ヘルパー関数

#### get_disk_free(path)

ディスクの空き容量情報を取得:
- 空き容量
- 合計容量
- 使用容量
- 使用率

#### update_env_file(key, value)

.envファイルを更新:
- 既存キーの更新
- 新規キーの追加
- ファイルが存在しない場合は作成

## ファイル一覧

### 新規作成ファイル

1. `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/flask-app/api/settings.py`
   - Settings API実装
   - 220行

2. `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/flask-app/.env`
   - 開発環境設定
   - 45行

3. `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/flask-app/test_settings_api.py`
   - APIテストスクリプト
   - 150行

### 更新ファイル

1. `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/flask-app/api/__init__.py`
   - settings importを追加

2. `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/flask-app/config.py`
   - .env読み込みロジック改善

3. `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/flask-app/views/deployment.py`
   - current_app import追加
   - deploy_settings関数にconfig渡し

4. `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/flask-app/templates/deployment/settings.html`
   - イメージパス設定UIセクション追加
   - JavaScript検証・更新ロジック追加

5. `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/.env.production`
   - CLONEZILLA_IMAGE_PATH追加

## テスト方法

### 1. Flaskサーバー起動

```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/flask-app
source venv/bin/activate
python app.py
```

### 2. Web UIテスト

ブラウザで以下にアクセス:
```
http://localhost:5000/deployment/settings
```

手順:
1. 「Clonezillaイメージパス設定」セクションを確認
2. パス入力フィールドに `/mnt/Linux-ExHDD/Ubuntu-ExHDD` が表示されていることを確認
3. 「検証」ボタンをクリック
4. パス情報が表示されることを確認
5. 別のパス（例: `/tmp`）を入力して検証
6. 存在しないパス（例: `/invalid/path`）を入力してエラー表示を確認

### 3. APIテスト

別ターミナルで:
```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/flask-app
source venv/bin/activate
python test_settings_api.py
```

または手動でcurlテスト:
```bash
# 設定取得
curl http://localhost:5000/api/settings

# パス検証
curl -X POST http://localhost:5000/api/settings/image-path/validate \
  -H "Content-Type: application/json" \
  -d '{"path": "/mnt/Linux-ExHDD/Ubuntu-ExHDD"}'

# パス更新
curl -X POST http://localhost:5000/api/settings/image-path \
  -H "Content-Type: application/json" \
  -d '{"path": "/mnt/Linux-ExHDD/Ubuntu-ExHDD"}'
```

## 動作確認結果

### 設定読み込み確認

```bash
source venv/bin/activate
python -c "
from app import create_app
app = create_app()
with app.app_context():
    print(f'CLONEZILLA_IMAGE_PATH: {app.config[\"CLONEZILLA_IMAGE_PATH\"]}')
"
```

**出力**:
```
CLONEZILLA_IMAGE_PATH: /mnt/Linux-ExHDD/Ubuntu-ExHDD
```

### デフォルトディレクトリ確認

```bash
ls -la /mnt/Linux-ExHDD/Ubuntu-ExHDD
```

**出力**:
```
drwxr-xr-x  2 kensan kensan 4096 11月 17 12:53 .
drwxrwxr-x 45 kensan kensan 4096 11月 17 12:53 ..
```

ディレクトリは存在し、読み書き可能です。

## セキュリティ考慮事項

1. **パス検証**
   - 存在確認
   - 権限確認（読み取り/書き込み）
   - ディレクトリチェック

2. **入力サニタイズ**
   - パス文字列の前後空白削除
   - 末尾スラッシュ削除

3. **エラーハンドリング**
   - すべてのAPI呼び出しにtry-catch
   - 適切なHTTPステータスコード
   - ユーザーフレンドリーなエラーメッセージ

4. **権限管理**
   - 書き込み権限のないパスは拒否
   - 読み取り権限のないパスは拒否

## 今後の拡張案

1. **パス履歴管理**
   - 過去に使用したパスの記録
   - ドロップダウンでの選択

2. **デフォルトパス復元**
   - ワンクリックでデフォルトに戻す

3. **パスブラウザ**
   - ディレクトリツリー表示
   - UIからのパス選択

4. **検証スケジュール**
   - 定期的なパス検証
   - 問題時の通知

5. **監査ログ**
   - パス変更履歴の記録
   - 変更者・変更日時の追跡

## トラブルシューティング

### 問題: パス更新が反映されない

**解決策**:
1. .envファイルの権限を確認
2. Flaskサーバーを再起動
3. ブラウザのキャッシュをクリア

### 問題: 書き込み権限エラー

**解決策**:
```bash
sudo chown -R $USER:$USER /mnt/Linux-ExHDD/Ubuntu-ExHDD
sudo chmod -R 755 /mnt/Linux-ExHDD/Ubuntu-ExHDD
```

### 問題: APIが応答しない

**解決策**:
1. Flaskサーバーが起動しているか確認
2. ポート5000が使用可能か確認
3. ログファイルを確認: `logs/app.log`

## まとめ

Clonezillaイメージパス設定機能を完全実装しました。以下の機能が利用可能です:

- Web UIからのパス変更
- リアルタイムパス検証
- ディスク容量表示
- .envファイル永続化
- REST API提供

この機能により、管理者は柔軟にClonezillaイメージの格納場所を変更できるようになり、システムの運用性が大幅に向上しました。
