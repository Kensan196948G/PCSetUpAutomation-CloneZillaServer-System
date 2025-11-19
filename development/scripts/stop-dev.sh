#!/bin/bash

###############################################################################
# 開発サーバ停止スクリプト
# 説明: Flask開発サーバを停止します
# 使用方法: ./stop-dev.sh
###############################################################################

set -e

# カラー出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}開発サーバ停止スクリプト${NC}"
echo -e "${GREEN}=================================${NC}"

# Flask開発サーバのプロセスを検索
FLASK_PID=$(pgrep -f "flask run" || true)

if [ -z "$FLASK_PID" ]; then
    echo -e "${YELLOW}Flask開発サーバは起動していません${NC}"
    exit 0
fi

# プロセスの停止
echo -e "${YELLOW}Flask開発サーバを停止しています... (PID: $FLASK_PID)${NC}"
kill -TERM "$FLASK_PID"

# プロセスが停止するまで待機
for i in {1..10}; do
    if ! ps -p "$FLASK_PID" > /dev/null 2>&1; then
        echo -e "${GREEN}Flask開発サーバを正常に停止しました${NC}"
        exit 0
    fi
    sleep 1
done

# 強制停止
echo -e "${RED}プロセスが応答しません。強制停止します...${NC}"
kill -KILL "$FLASK_PID" 2>/dev/null || true
echo -e "${GREEN}Flask開発サーバを強制停止しました${NC}"
