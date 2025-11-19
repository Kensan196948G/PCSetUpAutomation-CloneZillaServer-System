#!/bin/bash

###############################################################################
# 本番サーバ起動スクリプト
# 説明: Flask本番サーバ（Gunicorn）を起動します
# 使用方法: sudo ./start-prod.sh
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
    echo "使用方法: sudo ./start-prod.sh"
    exit 1
fi

echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}本番サーバ起動スクリプト${NC}"
echo -e "${GREEN}=================================${NC}"

# systemdサービスの起動
echo -e "${YELLOW}Flask Webアプリケーションを起動しています...${NC}"
systemctl start flask-app.service

# ステータスチェック
sleep 2
if systemctl is-active --quiet flask-app.service; then
    echo -e "${GREEN}Flask Webアプリケーションが正常に起動しました${NC}"
else
    echo -e "${RED}エラー: Flask Webアプリケーションの起動に失敗しました${NC}"
    echo -e "${YELLOW}ログを確認してください: journalctl -u flask-app.service -n 50${NC}"
    exit 1
fi

# Nginxの起動確認
echo -e "${YELLOW}Nginxのステータスを確認しています...${NC}"
if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}Nginxは既に起動しています${NC}"
else
    echo -e "${YELLOW}Nginxを起動しています...${NC}"
    systemctl start nginx
    if systemctl is-active --quiet nginx; then
        echo -e "${GREEN}Nginxが正常に起動しました${NC}"
    else
        echo -e "${RED}エラー: Nginxの起動に失敗しました${NC}"
        exit 1
    fi
fi

# DRBLサービスの確認（オプション）
echo -e "${YELLOW}DRBLサービスのステータスを確認しています...${NC}"
if systemctl is-active --quiet tftpd-hpa; then
    echo -e "${GREEN}TFTP サーバは起動しています${NC}"
else
    echo -e "${YELLOW}警告: TFTP サーバが起動していません${NC}"
    echo -e "${YELLOW}PXEブートが必要な場合は起動してください: sudo systemctl start tftpd-hpa${NC}"
fi

echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}本番サーバの起動が完了しました${NC}"
echo -e "${GREEN}=================================${NC}"
echo -e "${YELLOW}サービスステータス:${NC}"
systemctl status flask-app.service --no-pager -l
