#!/bin/bash

###############################################################################
# 本番サーバ停止スクリプト
# 説明: Flask本番サーバ（Gunicorn）を停止します
# 使用方法: sudo ./stop-prod.sh
###############################################################################

set -e

# カラー出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# root権限チェック
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}エラー: このスクリプトはroot権限で実行してください${NC}"
    echo "使用方法: sudo ./stop-prod.sh"
    exit 1
fi

echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}本番サーバ停止スクリプト${NC}"
echo -e "${GREEN}=================================${NC}"

# 確認メッセージ
echo -e "${YELLOW}警告: 本番サービスを停止します${NC}"
read -p "続行しますか? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}キャンセルしました${NC}"
    exit 1
fi

# Flask Webアプリケーションの停止
echo -e "${YELLOW}Flask Webアプリケーションを停止しています...${NC}"
systemctl stop flask-app.service

# ステータスチェック
sleep 2
if ! systemctl is-active --quiet flask-app.service; then
    echo -e "${GREEN}Flask Webアプリケーションが正常に停止しました${NC}"
else
    echo -e "${RED}警告: Flask Webアプリケーションが完全に停止していない可能性があります${NC}"
fi

echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}本番サーバの停止が完了しました${NC}"
echo -e "${GREEN}=================================${NC}"
echo -e "${YELLOW}サービスステータス:${NC}"
systemctl status flask-app.service --no-pager -l
