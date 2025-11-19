#!/bin/bash

###############################################################################
# バックアップスクリプト
# 説明: データベース、ODJファイル、マスターイメージをバックアップします
# 使用方法: sudo ./backup.sh [daily|weekly|monthly]
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
BACKUP_DIR="$PROJECT_ROOT/backups"
DATA_DIR="$PROJECT_ROOT/data"
DB_FILE="$DATA_DIR/db/pcsetup.db"
ODJ_DIR="$DATA_DIR/odj"
IMAGES_DIR="/home/partimag"

# バックアップタイプの取得（デフォルト: daily）
BACKUP_TYPE=${1:-daily}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_SUBDIR="$BACKUP_DIR/$BACKUP_TYPE"
BACKUP_FILE="backup_${BACKUP_TYPE}_${TIMESTAMP}.tar.gz"

echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}バックアップスクリプト${NC}"
echo -e "${GREEN}バックアップタイプ: $BACKUP_TYPE${NC}"
echo -e "${GREEN}=================================${NC}"

# root権限チェック
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}エラー: このスクリプトはroot権限で実行してください${NC}"
    echo "使用方法: sudo ./backup.sh [daily|weekly|monthly]"
    exit 1
fi

# バックアップディレクトリの作成
mkdir -p "$BACKUP_SUBDIR"

# 一時ディレクトリの作成
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo -e "${YELLOW}バックアップを開始しています...${NC}"

# データベースのバックアップ
if [ -f "$DB_FILE" ]; then
    echo -e "${YELLOW}データベースをバックアップしています...${NC}"
    mkdir -p "$TEMP_DIR/database"
    cp "$DB_FILE" "$TEMP_DIR/database/"
    sqlite3 "$DB_FILE" ".backup $TEMP_DIR/database/pcsetup_backup.db"
    echo -e "${GREEN}データベースのバックアップが完了しました${NC}"
else
    echo -e "${RED}警告: データベースファイルが見つかりません: $DB_FILE${NC}"
fi

# ODJファイルのバックアップ
if [ -d "$ODJ_DIR" ]; then
    echo -e "${YELLOW}ODJファイルをバックアップしています...${NC}"
    mkdir -p "$TEMP_DIR/odj"
    cp -r "$ODJ_DIR"/* "$TEMP_DIR/odj/" 2>/dev/null || echo -e "${YELLOW}ODJファイルがありません${NC}"
    echo -e "${GREEN}ODJファイルのバックアップが完了しました${NC}"
else
    echo -e "${RED}警告: ODJディレクトリが見つかりません: $ODJ_DIR${NC}"
fi

# Clonezillaマスターイメージのバックアップ（weeklyとmonthlyのみ）
if [[ "$BACKUP_TYPE" == "weekly" ]] || [[ "$BACKUP_TYPE" == "monthly" ]]; then
    if [ -d "$IMAGES_DIR" ]; then
        echo -e "${YELLOW}Clonezillaマスターイメージをバックアップしています（時間がかかります）...${NC}"
        mkdir -p "$TEMP_DIR/images"
        # イメージディレクトリのリストを取得（最新の1つのみ）
        LATEST_IMAGE=$(ls -t "$IMAGES_DIR" | head -1)
        if [ -n "$LATEST_IMAGE" ]; then
            cp -r "$IMAGES_DIR/$LATEST_IMAGE" "$TEMP_DIR/images/" || echo -e "${RED}警告: イメージのコピーに失敗しました${NC}"
            echo -e "${GREEN}マスターイメージのバックアップが完了しました${NC}"
        else
            echo -e "${YELLOW}マスターイメージが見つかりません${NC}"
        fi
    else
        echo -e "${RED}警告: Clonezillaイメージディレクトリが見つかりません: $IMAGES_DIR${NC}"
    fi
fi

# 設定ファイルのバックアップ
echo -e "${YELLOW}設定ファイルをバックアップしています...${NC}"
mkdir -p "$TEMP_DIR/configs"
cp -r "$PROJECT_ROOT/configs"/* "$TEMP_DIR/configs/" 2>/dev/null || echo -e "${YELLOW}設定ファイルがありません${NC}"

# バックアップアーカイブの作成
echo -e "${YELLOW}バックアップアーカイブを作成しています...${NC}"
cd "$TEMP_DIR"
tar -czf "$BACKUP_SUBDIR/$BACKUP_FILE" ./*

# バックアップファイルのサイズを表示
BACKUP_SIZE=$(du -h "$BACKUP_SUBDIR/$BACKUP_FILE" | cut -f1)
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}バックアップが完了しました${NC}"
echo -e "${GREEN}バックアップファイル: $BACKUP_SUBDIR/$BACKUP_FILE${NC}"
echo -e "${GREEN}ファイルサイズ: $BACKUP_SIZE${NC}"
echo -e "${GREEN}=================================${NC}"

# 古いバックアップの削除（保持期間を過ぎたもの）
echo -e "${YELLOW}古いバックアップファイルを確認しています...${NC}"

case $BACKUP_TYPE in
    daily)
        # 7日以上前のdailyバックアップを削除
        find "$BACKUP_SUBDIR" -name "backup_daily_*.tar.gz" -mtime +7 -delete
        echo -e "${GREEN}7日以上前のdailyバックアップを削除しました${NC}"
        ;;
    weekly)
        # 4週間以上前のweeklyバックアップを削除
        find "$BACKUP_SUBDIR" -name "backup_weekly_*.tar.gz" -mtime +28 -delete
        echo -e "${GREEN}4週間以上前のweeklyバックアップを削除しました${NC}"
        ;;
    monthly)
        # 12ヶ月以上前のmonthlyバックアップを削除
        find "$BACKUP_SUBDIR" -name "backup_monthly_*.tar.gz" -mtime +365 -delete
        echo -e "${GREEN}12ヶ月以上前のmonthlyバックアップを削除しました${NC}"
        ;;
esac

# バックアップ完了ログの記録
echo "$(date): バックアップ完了 - $BACKUP_FILE ($BACKUP_SIZE)" >> "$PROJECT_ROOT/logs/backup.log"

echo -e "${GREEN}すべての処理が完了しました${NC}"
