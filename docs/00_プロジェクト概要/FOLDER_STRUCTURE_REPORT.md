# フォルダ構造構築レポート

## 実施日時
2025-11-17

## 概要
PCキッティング自動化フレームワークのdevelopment/とproduction/フォルダ構造を設計・作成しました。

## 作成されたフォルダ構造

### development/ (開発環境)

```
development/
├── README_DEVELOPMENT.md        # 開発環境セットアップガイド
├── .env.development             # 開発環境変数設定ファイル
├── configs/                     # 開発環境用設定ファイル
│   ├── api.dev.yaml            # API設定（開発用）
│   └── database.dev.yaml       # データベース設定（開発用）
├── data/                        # 開発用データ
│   ├── test-db/                # 開発用データベース
│   ├── test-images/            # テスト用Clonezillaイメージ
│   └── test-odj/               # テスト用ODJファイル
├── drbl-server/                # DRBL/Clonezilla設定（開発用）
├── flask-app/                  # Flask Webアプリケーション
├── logs/                       # 開発環境ログ
├── powershell-scripts/         # Windows自動セットアップスクリプト
├── scripts/                    # 開発環境用ユーティリティスクリプト
│   ├── start-dev.sh           # 開発サーバ起動
│   ├── stop-dev.sh            # 開発サーバ停止
│   ├── reset-db.sh            # データベースリセット
│   └── run-tests.sh           # テスト実行
└── venv/                       # Python仮想環境（開発用）
```

### production/ (本番環境)

```
production/
├── README_PRODUCTION.md         # 本番環境運用ガイド
├── .env.production              # 本番環境変数設定ファイル
├── backups/                     # バックアップ保存先
│   ├── daily/                  # 日次バックアップ
│   ├── weekly/                 # 週次バックアップ
│   └── monthly/                # 月次バックアップ
├── configs/                     # 本番環境用設定ファイル
│   ├── api.prod.yaml           # API設定（本番用）
│   ├── database.prod.yaml      # データベース設定（本番用）
│   └── nginx.conf              # Nginx設定
├── data/                        # 本番用データ
│   ├── db/                     # 本番データベース
│   ├── images/                 # 本番用Clonezillaイメージ
│   └── odj/                    # 本番用ODJファイル
├── drbl-server/                # DRBL/Clonezilla設定（本番用）
├── flask-app/                  # Flask Webアプリケーション（本番用）
├── logs/                       # 本番環境ログ
│   ├── drbl/                   # DRBLログ
│   ├── flask/                  # Flaskログ
│   └── nginx/                  # Nginxログ
├── powershell-scripts/         # Windows自動セットアップスクリプト
├── scripts/                    # 本番環境用スクリプト
│   ├── start-prod.sh          # 本番サーバ起動
│   ├── stop-prod.sh           # 本番サーバ停止
│   ├── backup.sh              # バックアップスクリプト
│   ├── restore.sh             # リストアスクリプト
│   └── health-check.sh        # ヘルスチェック
└── systemd/                    # systemdサービスファイル
    └── flask-app.service       # Flask Webアプリケーションサービス
```

## 作成されたファイル一覧

### 開発環境 (development/)

#### ドキュメント
- `README_DEVELOPMENT.md` - 開発環境セットアップガイド

#### スクリプト（すべて実行権限付与済み）
- `scripts/start-dev.sh` - 開発サーバ起動スクリプト
- `scripts/stop-dev.sh` - 開発サーバ停止スクリプト
- `scripts/reset-db.sh` - データベースリセットスクリプト
- `scripts/run-tests.sh` - テスト実行スクリプト

#### 設定ファイル
- `.env.development` - 開発環境変数設定ファイル
- `configs/database.dev.yaml` - データベース設定（SQLite、デバッグモード有効）
- `configs/api.dev.yaml` - API設定（CORS有効、認証無効、詳細ログ）

### 本番環境 (production/)

#### ドキュメント
- `README_PRODUCTION.md` - 本番環境運用ガイド

#### スクリプト（すべて実行権限付与済み）
- `scripts/start-prod.sh` - 本番サーバ起動スクリプト
- `scripts/stop-prod.sh` - 本番サーバ停止スクリプト
- `scripts/backup.sh` - バックアップスクリプト（daily/weekly/monthly対応）
- `scripts/restore.sh` - リストアスクリプト
- `scripts/health-check.sh` - システムヘルスチェックスクリプト

#### 設定ファイル
- `.env.production` - 本番環境変数設定ファイル（機密情報含む）
- `configs/database.prod.yaml` - データベース設定（本番用、バックアップ設定含む）
- `configs/api.prod.yaml` - API設定（レート制限、認証有効、セキュリティ強化）
- `configs/nginx.conf` - Nginx Webサーバ設定

#### systemdサービス
- `systemd/flask-app.service` - Flask Webアプリケーションのsystemdサービスファイル

## 主要な設計思想

### 1. 環境分離
- development/ と production/ を完全に分離
- それぞれ独立した設定ファイル、データ、ログを保持
- 開発環境での作業が本番環境に影響を与えない構造

### 2. セキュリティ考慮
- 本番環境の .env.production に機密情報を集約
- スクリプトに適切な実行権限を付与
- Nginx設定でセキュリティヘッダーを設定
- レート制限、認証、アクセス制御を本番環境で有効化

### 3. 運用性
- 各種スクリプトでカラー出力と詳細なエラーメッセージ
- バックアップスクリプトで日次/週次/月次の自動バックアップ
- ヘルスチェックスクリプトでシステム状態を監視
- systemdサービス化で自動起動・再起動に対応

### 4. 開発効率
- 開発環境用のユーティリティスクリプトを充実
- テスト実行スクリプトでカバレッジレポート生成
- データベースリセットスクリプトで環境リセット容易
- 詳細なREADMEで新規開発者のオンボーディング支援

## 次のステップ（推奨）

### 1. Flask Webアプリケーションの実装
- development/flask-app/ に以下を作成:
  - app.py（メインアプリケーション）
  - models.py（データベースモデル）
  - api.py（APIエンドポイント）
  - templates/（HTMLテンプレート）
  - static/（CSS、JavaScript）

### 2. PowerShellスクリプトの実装
- development/powershell-scripts/ に以下を作成:
  - setup.ps1（メインセットアップスクリプト）
  - modules/（機能別モジュール）
  - config/（設定ファイル）

### 3. DRBL/Clonezilla設定
- development/drbl-server/ に以下を作成:
  - PXEブート設定
  - Clonezillaメニュー設定
  - ネットワーク設定

### 4. テストの実装
- development/flask-app/tests/ にユニットテストを作成
- run-tests.sh でテスト実行環境を整備

### 5. 本番環境へのデプロイ準備
- .env.production の機密情報を設定
- Nginx設定の調整（サーバ名、SSL証明書など）
- systemdサービスの登録とテスト

## 注意事項

### セキュリティ
1. `.env.production` ファイルは必ず.gitignoreに追加してください
2. 本番環境の機密情報（パスワード、APIキー等）を必ず変更してください
3. Nginx設定でSSL証明書を設定してHTTPSを有効化してください

### 運用
1. バックアップスクリプトをcronで定期実行するよう設定してください
2. ログファイルのローテーション設定を確認してください
3. ディスク容量を定期的に監視してください

### 開発
1. 開発環境では必ずテストデータを使用してください
2. 本番データを開発環境に持ち込まないでください
3. コミット前に必ずrun-tests.shでテストを実行してください

## ファイルパス（絶対パス）

### 開発環境
- プロジェクトルート: `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/development/`
- データベース: `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/development/data/test-db/pcsetup.db`
- ログディレクトリ: `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/development/logs/`

### 本番環境
- プロジェクトルート: `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/`
- データベース: `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/data/db/pcsetup.db`
- ログディレクトリ: `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/logs/`
- バックアップディレクトリ: `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/backups/`

## まとめ

development/とproduction/のフォルダ構造を設計・作成し、必要なテンプレートファイルとスクリプトを配置しました。これにより、開発から本番環境への移行がスムーズに行えるようになります。

各スクリプトには実行権限が付与されており、すぐに使用可能です。設定ファイルはテンプレートとして作成されているため、プロジェクトの要件に合わせて調整してください。

次のステップとして、Flask Webアプリケーション、PowerShellスクリプト、DRBL/Clonezilla設定の実装に進むことをお勧めします。
