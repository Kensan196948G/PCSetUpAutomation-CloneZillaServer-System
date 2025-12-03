# 🖥️ PC Setup Automation - Clonezilla Server Project

**会社キッティング自動化フレームワーク** - 年間100台規模のWindows PCを完全自動でキッティングするシステム

## 📋 プロジェクト概要

本プロジェクトは、「LANに挿して電源を入れるだけ」でWindows PCのキッティングを完全自動化するシステムです。

### 主な機能
- ✅ PXEブート → Clonezillaによるマスターイメージ展開
- ✅ PC名の自動設定（命名規則: YYYYMMDDM）
- ✅ ODJ（Offline Domain Join）によるドメイン参加
- ✅ Windows Update自動実行
- ✅ 会社標準アプリケーションの自動導入
- ✅ セットアップログの自動記録

## 🏗️ システムアーキテクチャ（4レイヤー構造）

### 1. マスターPC構築レイヤー
- Windows 11ベースのマスターPC作成
- 会社標準構成の実装
- Sysprep実行 → Clonezillaでイメージ化

### 2. 前処理レイヤー（箱OCR）
- PCの箱側面にあるSerial番号をスマホで撮影
- ChatGPT OCRでSerial番号抽出
- 導入日ベースでPC名自動生成

### 3. インフラレイヤー（DRBL/Clonezilla + 管理GUI）
- **DRBLサーバ**（Ubuntu）: PXEブート環境、10〜20台同時展開
- **管理Webアプリケーション**（Flask）: Serial番号とPC名の管理
- **REST API**: `/api/pcinfo`、`/api/log`

### 4. 実行レイヤー（PXE → 完全自動化）
- PXEブート → Clonezillaイメージ展開
- Windows初回起動後の自動処理（PowerShell）
- Windows Update + アプリ導入 + 完了ログ送信

## 📁 ディレクトリ構造

```
/
├── development/             # 開発環境
│   ├── flask-app/          # Flask開発用アプリケーション
│   ├── scripts/            # 開発環境用スクリプト
│   │   ├── init-dev-env.sh  # 開発環境初期化スクリプト
│   │   └── start-dev.sh     # 開発サーバ起動スクリプト
│   ├── tests/              # テストコード
│   ├── .env.dev            # 開発環境変数
│   └── README.md           # 開発環境用README
├── production/              # 本番環境
│   ├── flask-app/          # Flask本番用アプリケーション
│   ├── scripts/            # 本番環境用スクリプト
│   │   ├── init-prod-env.sh # 本番環境初期化スクリプト
│   │   ├── deploy.sh        # デプロイスクリプト
│   │   └── backup.sh        # バックアップスクリプト
│   ├── nginx/              # Nginx設定
│   ├── systemd/            # systemdサービス設定
│   ├── .env.prod           # 本番環境変数
│   └── README.md           # 本番環境用README
├── scripts/                 # 共通スクリプト
│   ├── prepare-migration.sh # 移行準備スクリプト
│   └── switch-environment.sh # 環境切り替えスクリプト
├── flask-app/              # Flask管理Webアプリケーション（現在の環境）
│   ├── api/               # APIエンドポイント
│   ├── models/            # データベースモデル
│   ├── views/             # ビュー（GUI）
│   ├── templates/         # HTMLテンプレート
│   └── static/            # CSS/JavaScript
├── powershell-scripts/     # Windows自動化スクリプト
│   ├── modules/           # PowerShellモジュール
│   └── config/            # 設定ファイル
├── drbl-server/           # DRBL設定ファイル
├── tests/                 # テストコード
│   ├── unit/             # ユニットテスト
│   ├── integration/      # 統合テスト
│   └── e2e/              # E2Eテスト
├── docs/                  # ドキュメント
│   ├── architecture/     # アーキテクチャ設計
│   ├── api/              # API仕様書
│   └── deployment/       # デプロイメントガイド
├── media/                 # ISOファイル等のメディア
│   ├── clonezilla/       # Clonezillaイメージ
│   └── windows/          # Windows ISOファイル
├── migrations/            # データベースマイグレーション
├── odj-files/             # ODJファイル格納
└── .claude/               # Claude Code設定
    ├── agents/           # 10個のSubAgent定義
    ├── commands/         # 24個のスラッシュコマンド
    └── hooks/            # Git Hooks
```

## 🚀 クイックスタートガイド

### 開発環境のセットアップ

```bash
# 1. リポジトリのクローン
git clone <repository-url>
cd PCSetUpAutomation-CloneZillaServer-Project

# 2. 開発環境の初期化（自動セットアップ）
./development/scripts/init-dev-env.sh

# 3. 開発サーバの起動
cd development/flask-app
source venv/bin/activate
flask run --host=0.0.0.0 --port=5000
```

### 本番環境のセットアップ

```bash
# 1. 本番環境の初期化（自動セットアップ）
sudo ./production/scripts/init-prod-env.sh

# 2. サービスの起動
sudo systemctl start pcsetup-flask
sudo systemctl enable pcsetup-flask

# 3. Nginxの起動
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 環境移行の手順

```bash
# 1. 移行準備（dry-runモード）
./scripts/prepare-migration.sh --dry-run

# 2. 実際の移行実行
./scripts/prepare-migration.sh

# 3. 環境の切り替え（開発 → 本番）
./scripts/switch-environment.sh production
```

## 💻 必要な環境・依存関係

### ハードウェア要件
- CPU: 4コア以上
- メモリ: 8GB以上
- ストレージ: 100GB以上（マスターイメージ保存用）
- ネットワーク: Gigabit Ethernet x2（PXE用、管理用）

### ソフトウェア要件
- **OS**: Ubuntu 22.04 LTS（DRBLサーバ用）
- **Python**: 3.10以上
- **データベース**: PostgreSQL 14以上（または SQLite）
- **Webサーバ**: Nginx 1.18以上
- **DRBL/Clonezilla**: 最新版
- **Windows**: Windows 11（マスターPC）

### 重要な前提条件
- ⚠️ **Docker**: DRBL環境ではDockerサービスを無効化する必要があります
  - Dockerの `docker0` インターフェースがDRBL設定と競合するため
  - 詳細: [DRBL_FIX_DOCKER_GUIDE.md](./docs/04_インフラ/DRBL_FIX_DOCKER_GUIDE.md)

### Python依存パッケージ
```
Flask==3.0.0
Flask-SQLAlchemy==3.0.5
Flask-Migrate==4.0.5
psycopg2-binary==2.9.9
python-dotenv==1.0.0
pytest==7.4.3
pytest-cov==4.1.0
```

## 🔌 API仕様

### GET /api/pcinfo
Serial番号からPC名とODJファイルパスを取得

**リクエスト:**
```
GET /api/pcinfo?serial=ABC123456
```

**レスポンス:**
```json
{
  "pcname": "20251116M",
  "odj_path": "/odj/20251116M.txt"
}
```

### POST /api/log
セットアップログを記録

**リクエスト:**
```json
{
  "serial": "ABC123456",
  "pcname": "20251116M",
  "status": "completed",
  "timestamp": "2025-11-16 12:33:22",
  "logs": "Setup completed successfully"
}
```

**レスポンス:**
```json
{
  "result": "ok"
}
```

## 📊 データベーススキーマ

### pc_master テーブル
| カラム名 | 型 | 説明 |
|---------|---|------|
| id | INTEGER | 主キー |
| serial | TEXT | PCシリアル番号（UNIQUE） |
| pcname | TEXT | PC名（YYYYMMDDM形式） |
| odj_path | TEXT | ODJファイルパス |
| created_at | DATETIME | 作成日時 |

### setup_logs テーブル
| カラム名 | 型 | 説明 |
|---------|---|------|
| id | INTEGER | 主キー |
| serial | TEXT | PCシリアル番号 |
| pcname | TEXT | PC名 |
| status | TEXT | セットアップ状態 |
| timestamp | DATETIME | タイムスタンプ |
| logs | TEXT | ログ文字列 |

## 🧪 テスト

### ユニットテストの実行
```bash
pytest tests/unit/
```

### 統合テストの実行
```bash
pytest tests/integration/
```

### カバレッジレポートの生成
```bash
pytest --cov=flask-app --cov-report=html
```

## 🛠️ 開発用スラッシュコマンド

本プロジェクトには24個のスラッシュコマンドが用意されています：

### 基本開発コマンド
- `/setup-dev` - プロジェクト構造とセットアップ
- `/api-dev` - APIエンドポイントの実装
- `/powershell-dev` - PowerShellスクリプトの実装
- `/test-all` - テストの作成と実行
- `/deploy` - デプロイメント実行

### MCP統合コマンド
- `/mcp-full-analysis` - 全MCP統合でコードベースを完全分析
- `/mcp-code-quality` - MCP統合でコード品質を総合評価
- `/mcp-e2e-test` - 完全E2Eテストを自動実行
- `/mcp-refactor` - インテリジェントなリファクタリング
- `/mcp-deploy-check` - デプロイ前の総合チェック

### 最強開発コマンド
- `/ultimate-dev` - 全機能統合開発モード（10 SubAgents + 7 MCPs + Hooks）
- `/ai-team` - AIチーム開発モード（10人の専門家が協力）
- `/full-automation` - 完全自動化開発フロー（設計→実装→テスト→デプロイ）
- `/production-ready` - 本番環境準備の完全自動化
- `/mega-refactor` - 全機能を使った大規模リファクタリング

## 📝 PC命名規則

**YYYYMMDDM形式**:
- YYYY: 導入年（4桁）
- MM: 導入月（2桁）
- DD: 導入日（2桁）
- M: 固定サフィックス

例: 2025年11月16日導入 → `20251116M`

## 🔒 セキュリティ考慮事項

- ChatGPTへはSerial番号のみ送信（機微情報なし）
- API通信は社内LANのみ
- ODJファイルは権限付きフォルダに保存
- 展開後スクリプトは署名/ハッシュ検証を実装
- 本番環境ではHTTPS通信を使用
- データベース接続情報は環境変数で管理
- ファイアウォールで不要なポートを閉鎖

## 📈 非機能要件

- **Sysprep成功率**: 100%
- **API応答時間**: 200ms以下（LAN環境）
- **同時展開**: 10〜20台（性能劣化1台あたり20%以内）
- **展開時間**: 開始から完了まで60〜90分以内
- **展開失敗率**: 1%未満
- **データベースバックアップ**: 日次自動バックアップ
- **ログ保持期間**: 1年間

## 📚 ドキュメント

- [詳細要件定義書](./docs/詳細要件定義書.md)
- [CLAUDE.md](./CLAUDE.md) - Claude Code用プロジェクトガイド
- [MCP_COMMANDS_GUIDE.md](./.claude/MCP_COMMANDS_GUIDE.md) - MCP統合コマンドガイド
- [ULTIMATE_COMMANDS_GUIDE.md](./.claude/ULTIMATE_COMMANDS_GUIDE.md) - 最強開発コマンドガイド
- [開発環境README](./development/README.md)
- [本番環境README](./production/README.md)

## 🤝 貢献

本プロジェクトは会社内部プロジェクトです。

## 📄 ライセンス

社内利用限定

## 📞 サポート

問題が発生した場合は、IT部門までお問い合わせください。

---

## 🔧 トラブルシューティング

### Docker干渉問題
DRBL環境構築時にDockerの `docker0` インターフェースが干渉する問題が発生します。

**解決方法**:
```bash
# 自動修正スクリプトを実行
sudo ./scripts/fix_drbl_docker_issue.sh
```

**詳細**: [DRBL_FIX_DOCKER_GUIDE.md](./docs/04_インフラ/DRBL_FIX_DOCKER_GUIDE.md)

---

## 🤖 GitHub Actions - 自動エラー検知・修復システム

本プロジェクトには、**30分間隔で無限ループする自動エラー検知・修復システム**が組み込まれています。

### 主な機能
- ✅ **自動エラー検知**: 構文エラー、テスト失敗、Import エラー、コード品質問題
- ✅ **自動修復**: 未使用インポート削除、インデント修正、不足インポート追加、自動フォーマット
- ✅ **15回リトライループ**: 1回の実行で最大15回の検知→修復を繰り返し
- ✅ **30分間隔で無限実行**: cronで30分ごとに自動実行
- ✅ **自動Issue作成**: 修復できなかったエラーをIssueとして自動報告
- ✅ **自動コミット・プッシュ**: 修復したコードを自動的にリポジトリへ反映

### ワークフロー

```
30分ごとに実行
    ↓
エラー検知（構文、テスト、Import、品質）
    ↓
自動修復試行（最大15回ループ）
    ↓
    ├─ 全て修復成功 → コミット・プッシュ → Issue自動クローズ
    └─ 一部失敗 → GitHub Issue自動作成 → 次回30分後に再試行
```

### 手動実行

```bash
# GitHub Actionsで手動実行
# GitHub > Actions > Auto Error Detection & Healing System > Run workflow

# ローカルで実行
python .github/scripts/auto_heal.py --max-iterations 15
```

### 詳細

- **ワークフローファイル**: `.github/workflows/auto-heal.yml`
- **修復スクリプト**: `.github/scripts/auto_heal.py`
- **Issueテンプレート**: `.github/ISSUE_TEMPLATE/auto-heal-failure.md`

---

**最終更新日**: 2025-12-03
**バージョン**: 1.2.0
