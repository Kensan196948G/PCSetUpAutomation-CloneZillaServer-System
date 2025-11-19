# 開発環境セットアップガイド

## 概要

本ディレクトリは、PCキッティング自動化フレームワークの開発環境です。
本番環境に影響を与えることなく、機能開発・テスト・デバッグを実施できます。

## ディレクトリ構成

```
development/
├── flask-app/           # Flask Webアプリケーション
├── powershell-scripts/  # Windows自動セットアップスクリプト
├── drbl-server/         # DRBL/Clonezilla設定
├── configs/             # 開発環境用設定ファイル
│   ├── database.dev.yaml
│   ├── api.dev.yaml
│   └── drbl.dev.conf
├── data/                # 開発用データ
│   ├── test-images/     # テスト用Clonezillaイメージ
│   ├── test-odj/        # テスト用ODJファイル
│   └── test-db/         # 開発用データベース
├── logs/                # 開発環境ログ
├── scripts/             # 開発環境用ユーティリティスクリプト
│   ├── start-dev.sh     # 開発サーバ起動
│   ├── stop-dev.sh      # 開発サーバ停止
│   ├── reset-db.sh      # データベースリセット
│   └── run-tests.sh     # テスト実行
├── venv/                # Python仮想環境（開発用）
├── .env.development     # 開発環境変数
├── docker-compose.dev.yml  # Docker開発環境（オプション）
└── README_DEVELOPMENT.md   # 本ファイル
```

## 開発環境セットアップ手順

### 1. Python仮想環境のセットアップ

```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/development
python3 -m venv venv
source venv/bin/activate
```

### 2. 依存パッケージのインストール

```bash
# Flask関連パッケージ
pip install Flask Flask-SQLAlchemy Flask-Migrate Flask-CORS
pip install pytest pytest-cov
pip install python-dotenv
```

### 3. 環境変数の設定

`.env.development` ファイルを編集して開発環境用の設定を行います。

```bash
cp .env.development.template .env.development
nano .env.development
```

### 4. データベースの初期化

```bash
./scripts/reset-db.sh
```

### 5. 開発サーバの起動

```bash
./scripts/start-dev.sh
```

開発サーバは `http://localhost:5000` で起動します。

## 開発ワークフロー

### テストデータの投入

```bash
# テスト用PC情報をCSVから投入
python flask-app/scripts/import_test_data.py
```

### APIテスト

```bash
# PC情報取得テスト
curl "http://localhost:5000/api/pcinfo?serial=TEST123456"

# ログ送信テスト
curl -X POST http://localhost:5000/api/log \
  -H "Content-Type: application/json" \
  -d '{"serial":"TEST123456","pcname":"20251116M","status":"completed","timestamp":"2025-11-16 12:33:22"}'
```

### ユニットテストの実行

```bash
./scripts/run-tests.sh
```

### データベースのリセット

```bash
./scripts/reset-db.sh
```

## トラブルシューティング

### ポート5000が既に使用されている

```bash
# 使用中のプロセスを確認
lsof -i :5000

# 別のポートで起動する場合
FLASK_PORT=5001 ./scripts/start-dev.sh
```

### データベースが壊れた場合

```bash
./scripts/reset-db.sh
```

### ログの確認

```bash
tail -f logs/flask-dev.log
tail -f logs/api-dev.log
```

## 開発時の注意事項

1. **本番データは使用しない**: 開発環境では必ずテストデータを使用してください
2. **セキュリティ**: `.env.development` にはテスト用の認証情報のみを設定してください
3. **コミット前**: `run-tests.sh` を実行してすべてのテストが通ることを確認してください
4. **パフォーマンステスト**: 本番と同等の負荷テストは別環境で実施してください

## 関連ドキュメント

- [本番環境セットアップガイド](../production/README_PRODUCTION.md)
- [API仕様書](../docs/API_SPECIFICATION.md)
- [データベーススキーマ](../docs/DATABASE_SCHEMA.md)
- [PowerShellスクリプト仕様](../docs/POWERSHELL_SCRIPTS.md)

## 開発環境の停止

```bash
./scripts/stop-dev.sh
```

## 問い合わせ

開発環境に関する質問や問題は、プロジェクトの管理者に連絡してください。
