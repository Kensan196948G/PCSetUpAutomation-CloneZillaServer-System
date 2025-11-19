# コードベース構造

## ディレクトリ構造

```
/
├── development/             # 開発環境
│   ├── flask-app/          # Flask開発用アプリケーション
│   ├── scripts/            # 開発環境用スクリプト
│   │   ├── init-dev-env.sh  # 開発環境初期化
│   │   └── start-dev.sh     # 開発サーバ起動
│   ├── tests/              # テストコード
│   ├── .env.dev            # 開発環境変数
│   └── README.md
├── production/              # 本番環境
│   ├── flask-app/          # Flask本番用アプリケーション
│   ├── scripts/            # 本番環境用スクリプト
│   │   ├── init-prod-env.sh # 本番環境初期化
│   │   ├── deploy.sh        # デプロイスクリプト
│   │   └── backup.sh        # バックアップスクリプト
│   ├── nginx/              # Nginx設定
│   ├── systemd/            # systemdサービス設定
│   ├── .env.prod           # 本番環境変数
│   └── README.md
├── flask-app/              # Flask管理Webアプリケーション（現在の環境）
│   ├── api/               # APIエンドポイント
│   │   ├── pcinfo.py      # GET /api/pcinfo
│   │   ├── log.py         # POST /api/log
│   │   └── pc_crud.py     # CRUD API
│   ├── models/            # データベースモデル
│   │   ├── pc_master.py   # PCMasterモデル
│   │   └── setup_log.py   # SetupLogモデル
│   ├── views/             # ビュー（GUI）
│   ├── templates/         # HTMLテンプレート
│   ├── static/            # CSS/JavaScript
│   ├── app.py             # Flaskアプリケーションエントリポイント
│   ├── requirements.txt   # 本番依存関係
│   └── requirements-test.txt # テスト依存関係
├── powershell-scripts/     # Windows自動化スクリプト
│   ├── modules/           # PowerShellモジュール
│   ├── config/            # 設定ファイル
│   ├── tests/             # PowerShellテスト
│   └── setup.ps1          # メインセットアップスクリプト
├── drbl-server/           # DRBL設定ファイル
├── tests/                 # テストコード
│   ├── unit/             # ユニットテスト
│   ├── integration/      # 統合テスト
│   ├── e2e/              # E2Eテスト
│   ├── performance/      # パフォーマンステスト
│   └── conftest.py       # pytest設定・フィクスチャ
├── docs/                  # ドキュメント
│   ├── architecture/     # アーキテクチャ設計
│   ├── api/              # API仕様書
│   └── deployment/       # デプロイメントガイド
├── media/                 # ISOファイル等のメディア
│   ├── clonezilla/       # Clonezillaイメージ
│   └── windows/          # Windows ISOファイル
├── migrations/            # データベースマイグレーション
├── odj-files/             # ODJファイル格納
├── logs/                  # アプリケーションログ
├── scripts/               # 共通スクリプト
│   ├── prepare-migration.sh # 移行準備スクリプト
│   └── switch-environment.sh # 環境切り替え
├── .claude/               # Claude Code設定
│   ├── agents/           # 10個のSubAgent定義
│   ├── commands/         # 24個のスラッシュコマンド
│   └── hooks/            # Git Hooks
├── .git/                  # Gitリポジトリ
├── venv/                  # Python仮想環境
├── CLAUDE.md             # Claude Code用プロジェクトガイド
├── README.md             # プロジェクトREADME
├── START_HERE.md         # クイックスタートガイド
├── .env.example          # 環境変数サンプル
└── .gitignore            # Git除外設定
```

## 主要コンポーネント

### Flask App (flask-app/)
- **app.py**: アプリケーションファクトリパターン
  - `create_app()`: アプリケーション作成
  - `setup_logging()`: ロギング設定
  - `register_blueprints()`: Blueprint登録
  - `register_error_handlers()`: エラーハンドラ登録
  - `register_commands()`: CLIコマンド登録

### Models (flask-app/models/)
- **pc_master.py**: PCMasterモデル
  - id, serial, pcname, odj_path, created_at
- **setup_log.py**: SetupLogモデル
  - id, serial, pcname, status, timestamp, logs, step

### API (flask-app/api/)
- **pcinfo.py**: GET /api/pcinfo（Serial番号からPC情報取得）
- **log.py**: POST /api/log（セットアップログ記録）
- **pc_crud.py**: CRUD API（PC情報の作成・更新・削除）

### Tests (tests/)
- **conftest.py**: pytest設定
  - フィクスチャ: app, client, runner, sample_pc_data, sample_log_data
- **unit/**: ユニットテスト
- **integration/**: 統合テスト
- **e2e/**: E2Eテスト
- **performance/**: パフォーマンステスト
