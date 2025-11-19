#!/bin/bash

###############################################################################
# データベースリセットスクリプト
# 説明: 開発用データベースを初期化します
# 使用方法: ./reset-db.sh
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
DB_DIR="$PROJECT_ROOT/data/test-db"
DB_FILE="$DB_DIR/pcsetup.db"
FLASK_APP_DIR="$PROJECT_ROOT/flask-app"
VENV_DIR="$PROJECT_ROOT/venv"

echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}データベースリセットスクリプト${NC}"
echo -e "${GREEN}=================================${NC}"

# 確認メッセージ
echo -e "${YELLOW}警告: すべてのデータベースデータが削除されます${NC}"
read -p "続行しますか? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}キャンセルしました${NC}"
    exit 1
fi

# データベースディレクトリの作成
mkdir -p "$DB_DIR"

# 既存のデータベースファイルを削除
if [ -f "$DB_FILE" ]; then
    echo -e "${YELLOW}既存のデータベースファイルを削除しています...${NC}"
    rm -f "$DB_FILE"
fi

# 仮想環境の有効化
if [ -d "$VENV_DIR" ]; then
    echo -e "${YELLOW}仮想環境を有効化しています...${NC}"
    source "$VENV_DIR/bin/activate"
else
    echo -e "${RED}エラー: Python仮想環境が見つかりません${NC}"
    echo -e "${YELLOW}以下のコマンドで仮想環境を作成してください:${NC}"
    echo "  python3 -m venv $VENV_DIR"
    exit 1
fi

# 環境変数の読み込み
if [ -f "$PROJECT_ROOT/.env.development" ]; then
    export $(cat "$PROJECT_ROOT/.env.development" | grep -v '^#' | xargs)
fi

# Flaskアプリケーションのディレクトリに移動
cd "$FLASK_APP_DIR"

# Flask環境変数の設定
export FLASK_APP="app.py"
export DATABASE_URL="sqlite:///$DB_FILE"

# データベースの初期化
echo -e "${YELLOW}データベースを初期化しています...${NC}"

# マイグレーションディレクトリが存在する場合は削除
if [ -d "migrations" ]; then
    rm -rf migrations
fi

# Flaskマイグレーションの初期化
flask db init

# マイグレーションファイルの作成
flask db migrate -m "Initial migration"

# マイグレーションの適用
flask db upgrade

echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}データベースのリセットが完了しました${NC}"
echo -e "${GREEN}データベースファイル: $DB_FILE${NC}"
echo -e "${GREEN}=================================${NC}"

# テストデータの投入（オプション）
read -p "テストデータを投入しますか? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "$FLASK_APP_DIR/scripts/import_test_data.py" ]; then
        echo -e "${YELLOW}テストデータを投入しています...${NC}"
        python "$FLASK_APP_DIR/scripts/import_test_data.py"
        echo -e "${GREEN}テストデータの投入が完了しました${NC}"
    else
        echo -e "${RED}警告: テストデータ投入スクリプトが見つかりません${NC}"
    fi
fi
