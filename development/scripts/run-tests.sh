#!/bin/bash

###############################################################################
# テスト実行スクリプト
# 説明: ユニットテストとインテグレーションテストを実行します
# 使用方法: ./run-tests.sh [--coverage]
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

# オプション解析
COVERAGE=false
if [[ "$1" == "--coverage" ]]; then
    COVERAGE=true
fi

echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}テスト実行スクリプト${NC}"
echo -e "${GREEN}=================================${NC}"

# ログディレクトリの作成
mkdir -p "$LOG_DIR"

# 仮想環境の確認
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${RED}エラー: Python仮想環境が見つかりません${NC}"
    exit 1
fi

# 仮想環境の有効化
echo -e "${YELLOW}仮想環境を有効化しています...${NC}"
source "$VENV_DIR/bin/activate"

# 環境変数の読み込み
if [ -f "$PROJECT_ROOT/.env.development" ]; then
    export $(cat "$PROJECT_ROOT/.env.development" | grep -v '^#' | xargs)
fi

# テスト用環境変数の設定
export FLASK_ENV=testing
export DATABASE_URL="sqlite:///:memory:"

# Flaskアプリケーションのディレクトリに移動
cd "$FLASK_APP_DIR"

# テスト実行
if [ "$COVERAGE" = true ]; then
    echo -e "${YELLOW}カバレッジレポート付きでテストを実行しています...${NC}"
    pytest --cov=. --cov-report=html --cov-report=term tests/ 2>&1 | tee "$LOG_DIR/test-results.log"

    echo -e "${GREEN}=================================${NC}"
    echo -e "${GREEN}カバレッジレポート: $FLASK_APP_DIR/htmlcov/index.html${NC}"
    echo -e "${GREEN}=================================${NC}"
else
    echo -e "${YELLOW}テストを実行しています...${NC}"
    pytest -v tests/ 2>&1 | tee "$LOG_DIR/test-results.log"
fi

# テスト結果の判定
if [ $? -eq 0 ]; then
    echo -e "${GREEN}=================================${NC}"
    echo -e "${GREEN}すべてのテストが成功しました${NC}"
    echo -e "${GREEN}=================================${NC}"
    exit 0
else
    echo -e "${RED}=================================${NC}"
    echo -e "${RED}テストが失敗しました${NC}"
    echo -e "${RED}ログファイル: $LOG_DIR/test-results.log${NC}"
    echo -e "${RED}=================================${NC}"
    exit 1
fi
