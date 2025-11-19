#!/bin/bash

###############################################################################
# ヘルスチェックスクリプト
# 説明: システムの正常性を確認します
# 使用方法: ./health-check.sh
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
DATA_DIR="$PROJECT_ROOT/data"
DB_FILE="$DATA_DIR/db/pcsetup.db"

# ヘルスチェック結果カウンター
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}システムヘルスチェック${NC}"
echo -e "${GREEN}=================================${NC}"
echo ""

# チェック関数
check_service() {
    local SERVICE_NAME=$1
    local DESCRIPTION=$2
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    echo -n "[$TOTAL_CHECKS] $DESCRIPTION ... "

    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "${GREEN}OK${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_file() {
    local FILE_PATH=$1
    local DESCRIPTION=$2
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    echo -n "[$TOTAL_CHECKS] $DESCRIPTION ... "

    if [ -f "$FILE_PATH" ]; then
        echo -e "${GREEN}OK${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_directory() {
    local DIR_PATH=$1
    local DESCRIPTION=$2
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    echo -n "[$TOTAL_CHECKS] $DESCRIPTION ... "

    if [ -d "$DIR_PATH" ]; then
        echo -e "${GREEN}OK${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_api() {
    local ENDPOINT=$1
    local DESCRIPTION=$2
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    echo -n "[$TOTAL_CHECKS] $DESCRIPTION ... "

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$ENDPOINT" 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" == "200" ]; then
        echo -e "${GREEN}OK (HTTP $HTTP_CODE)${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}FAILED (HTTP $HTTP_CODE)${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_disk_space() {
    local PATH=$1
    local THRESHOLD=$2
    local DESCRIPTION=$3
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    echo -n "[$TOTAL_CHECKS] $DESCRIPTION ... "

    USAGE=$(df -h "$PATH" | awk 'NR==2 {print $(NF-1)}' | sed 's/%//')

    if [ "$USAGE" -lt "$THRESHOLD" ]; then
        echo -e "${GREEN}OK (${USAGE}% used)${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}FAILED (${USAGE}% used, threshold: ${THRESHOLD}%)${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

# サービスチェック
echo -e "${YELLOW}=== サービスステータス ===${NC}"
check_service "flask-app.service" "Flask Webアプリケーション"
check_service "nginx.service" "Nginx Webサーバ"
check_service "tftpd-hpa.service" "TFTP サーバ（PXEブート）" || echo -e "${YELLOW}    注意: PXEブートが必要な場合は起動してください${NC}"
echo ""

# ファイル・ディレクトリチェック
echo -e "${YELLOW}=== ファイル・ディレクトリ ===${NC}"
check_file "$DB_FILE" "データベースファイル"
check_directory "$DATA_DIR/odj" "ODJファイルディレクトリ"
check_directory "/home/partimag" "Clonezillaイメージディレクトリ"
check_directory "$PROJECT_ROOT/logs" "ログディレクトリ"
echo ""

# API動作チェック
echo -e "${YELLOW}=== API動作確認 ===${NC}"
check_api "http://localhost/api/health" "APIヘルスチェック" || echo -e "${YELLOW}    注意: APIエンドポイントが正しく設定されているか確認してください${NC}"
echo ""

# ディスク容量チェック
echo -e "${YELLOW}=== ディスク容量 ===${NC}"
check_disk_space "$PROJECT_ROOT" 80 "プロジェクトディレクトリ (80%未満)"
check_disk_space "/home/partimag" 90 "Clonezillaイメージディレクトリ (90%未満)"
echo ""

# データベース整合性チェック
echo -e "${YELLOW}=== データベース整合性 ===${NC}"
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
echo -n "[$TOTAL_CHECKS] データベース整合性チェック ... "
if sqlite3 "$DB_FILE" "PRAGMA integrity_check;" | grep -q "ok"; then
    echo -e "${GREEN}OK${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}FAILED${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi
echo ""

# ネットワーク接続チェック
echo -e "${YELLOW}=== ネットワーク接続 ===${NC}"
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
echo -n "[$TOTAL_CHECKS] インターネット接続 ... "
if ping -c 1 8.8.8.8 &> /dev/null; then
    echo -e "${GREEN}OK${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}FAILED${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi
echo ""

# 結果サマリー
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}ヘルスチェック結果${NC}"
echo -e "${GREEN}=================================${NC}"
echo -e "総チェック数: $TOTAL_CHECKS"
echo -e "${GREEN}成功: $PASSED_CHECKS${NC}"
if [ $FAILED_CHECKS -gt 0 ]; then
    echo -e "${RED}失敗: $FAILED_CHECKS${NC}"
else
    echo -e "失敗: $FAILED_CHECKS"
fi

PASS_RATE=$(awk "BEGIN {printf \"%.1f\", ($PASSED_CHECKS/$TOTAL_CHECKS)*100}")
echo -e "成功率: ${PASS_RATE}%"
echo ""

# 最終判定
if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}すべてのチェックに合格しました${NC}"
    exit 0
elif [ $FAILED_CHECKS -le 2 ]; then
    echo -e "${YELLOW}一部のチェックに失敗しました。確認してください。${NC}"
    exit 1
else
    echo -e "${RED}複数のチェックに失敗しました。システムに問題がある可能性があります。${NC}"
    exit 2
fi
