# 推奨コマンド

## 開発環境セットアップ

### 初期セットアップ
```bash
# 開発環境の初期化（自動セットアップ）
./development/scripts/init-dev-env.sh

# 手動セットアップの場合
cd flask-app
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pip install -r requirements-test.txt
```

### 開発サーバ起動
```bash
# 開発環境
cd flask-app
source venv/bin/activate
flask run --host=0.0.0.0 --port=5000

# または開発スクリプト使用
./development/scripts/start-dev.sh
```

## テスト実行

### 全テスト実行
```bash
pytest tests/
```

### ユニットテストのみ
```bash
pytest tests/unit/
```

### 統合テストのみ
```bash
pytest tests/integration/
```

### E2Eテストのみ
```bash
pytest tests/e2e/
```

### パフォーマンステスト
```bash
pytest tests/performance/
```

### カバレッジレポート生成
```bash
# HTML形式
pytest --cov=flask-app --cov-report=html

# ターミナル表示
pytest --cov=flask-app --cov-report=term

# カバレッジレポート閲覧
open htmlcov/index.html  # macOS
xdg-open htmlcov/index.html  # Linux
```

### 特定のテスト実行
```bash
# ファイル指定
pytest tests/unit/test_api.py

# 関数指定
pytest tests/unit/test_api.py::test_get_pcinfo

# キーワード指定
pytest -k "pcinfo"
```

### 詳細出力
```bash
# 詳細モード
pytest -v

# 超詳細モード
pytest -vv

# 標準出力表示
pytest -s
```

## コード品質チェック

### リント
```bash
# Pyflakesでチェック（venv内にインストール済み）
python -m pyflakes flask-app/
```

### フォーマット
```bash
# 自動フォーマット（必要に応じてblackをインストール）
# pip install black
# black flask-app/
```

## データベース管理

### マイグレーション
```bash
# マイグレーション作成
flask db init
flask db migrate -m "Initial migration"
flask db upgrade

# ロールバック
flask db downgrade
```

### データベースリセット
```bash
# SQLiteファイル削除
rm pc_setup.db

# 再作成
flask db upgrade
```

## 本番環境デプロイ

### 本番環境初期化
```bash
sudo ./production/scripts/init-prod-env.sh
```

### サービス起動
```bash
# Flask アプリケーション
sudo systemctl start pcsetup-flask
sudo systemctl enable pcsetup-flask

# Nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### サービス状態確認
```bash
sudo systemctl status pcsetup-flask
sudo systemctl status nginx
```

### ログ確認
```bash
# Flask アプリケーションログ
sudo journalctl -u pcsetup-flask -f

# Nginx ログ
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

## DRBL/PXE環境

### PXE環境セットアップ
```bash
# 自動セットアップ（推奨）
sudo ./CHECK_PXE_READINESS.sh

# DRBL設定
sudo /usr/sbin/drblpush -i
```

### DHCP サーバ管理
```bash
# 起動
sudo systemctl start isc-dhcp-server

# 停止
sudo systemctl stop isc-dhcp-server

# 状態確認
sudo systemctl status isc-dhcp-server

# ログ確認
sudo journalctl -u isc-dhcp-server -f
```

### TFTP サーバ確認
```bash
# TFTPポート確認
sudo netstat -ulnp | grep :69

# ログ監視
sudo tail -f /var/log/syslog | grep -E "dhcpd|tftpd"
```

### PXEブート診断
```bash
# 診断スクリプト実行
./CHECK_PXE_READINESS.sh
```

## Git 操作

### ブランチ管理
```bash
# 新規ブランチ作成
git checkout -b feature/new-feature

# ブランチ切り替え
git checkout main

# ブランチ一覧
git branch -a
```

### コミット
```bash
# ステージング
git add .

# コミット
git commit -m "feat: 新機能追加"

# プッシュ
git push origin main
```

### 状態確認
```bash
# 変更状態
git status

# 変更差分
git diff

# ログ
git log --oneline -10
```

## 環境切り替え

### 開発→本番
```bash
./scripts/switch-environment.sh production
```

### 本番→開発
```bash
./scripts/switch-environment.sh development
```

## システムユーティリティ（Linux）

### ファイル検索
```bash
# ファイル名検索
find . -name "*.py"

# パターン検索
grep -r "def get_pc_info" flask-app/
```

### ディスク使用量
```bash
# ディスク使用状況
df -h

# ディレクトリサイズ
du -sh flask-app/
```

### プロセス管理
```bash
# プロセス一覧
ps aux | grep flask

# ポート使用確認
sudo netstat -tlnp | grep :5000
```
