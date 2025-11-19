#!/bin/bash

###############################################################################
# 開発サーバ起動スクリプト
# 説明: Flask開発サーバを起動します
# 使用方法: ./start-dev.sh
###############################################################################

set -e

# カラー出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# プロジェクトルートディレクトリ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FLASK_APP_DIR="$PROJECT_ROOT/flask-app"
VENV_DIR="$PROJECT_ROOT/venv"
LOG_DIR="$PROJECT_ROOT/logs"

echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}開発サーバ起動スクリプト${NC}"
echo -e "${GREEN}=================================${NC}"

# ログディレクトリの作成
mkdir -p "$LOG_DIR"

# 仮想環境の確認
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${RED}エラー: Python仮想環境が見つかりません${NC}"
    echo -e "${YELLOW}以下のコマンドで仮想環境を作成してください:${NC}"
    echo "  python3 -m venv $VENV_DIR"
    echo "  source $VENV_DIR/bin/activate"
    echo "  pip install -r $FLASK_APP_DIR/requirements.txt"
    exit 1
fi

# 仮想環境の有効化
echo -e "${YELLOW}仮想環境を有効化しています...${NC}"
source "$VENV_DIR/bin/activate"

# 環境変数の読み込み
if [ -f "$PROJECT_ROOT/.env.development" ]; then
    echo -e "${YELLOW}環境変数を読み込んでいます...${NC}"
    export $(cat "$PROJECT_ROOT/.env.development" | grep -v '^#' | xargs)
else
    echo -e "${RED}警告: .env.development が見つかりません${NC}"
    echo -e "${YELLOW}.env.development.template からコピーして設定してください${NC}"
fi

# Flask環境変数の設定
export FLASK_APP="$FLASK_APP_DIR/app.py"
export FLASK_ENV=development
export FLASK_DEBUG=1
export FLASK_PORT=${FLASK_PORT:-5000}

# データベースの確認
if [ ! -f "$PROJECT_ROOT/data/test-db/pcsetup.db" ]; then
    echo -e "${YELLOW}データベースが見つかりません。初期化します...${NC}"
    "$SCRIPT_DIR/reset-db.sh"
fi

# Flaskアプリケーションの起動
cd "$FLASK_APP_DIR"
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}Flask開発サーバを起動しています...${NC}"
echo -e "${GREEN}URL: http://localhost:$FLASK_PORT${NC}"
echo -e "${GREEN}ログファイル: $LOG_DIR/flask-dev.log${NC}"
echo -e "${GREEN}=================================${NC}"
echo -e "${YELLOW}Ctrl+C で停止します${NC}"
echo ""

# Flask開発サーバの起動
flask run --host=0.0.0.0 --port="$FLASK_PORT" 2>&1 | tee "$LOG_DIR/flask-dev.log"
