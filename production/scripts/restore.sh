#!/bin/bash

###############################################################################
# リストアスクリプト
# 説明: バックアップファイルからシステムをリストアします
# 使用方法: sudo ./restore.sh <バックアップファイルパス>
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
ODJ_DIR="$DATA_DIR/odj"

echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}リストアスクリプト${NC}"
echo -e "${GREEN}=================================${NC}"

# root権限チェック
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}エラー: このスクリプトはroot権限で実行してください${NC}"
    echo "使用方法: sudo ./restore.sh <バックアップファイルパス>"
    exit 1
fi

# 引数チェック
if [ $# -ne 1 ]; then
    echo -e "${RED}エラー: バックアップファイルのパスを指定してください${NC}"
    echo "使用方法: sudo ./restore.sh <バックアップファイルパス>"
    echo ""
    echo "利用可能なバックアップファイル:"
    find "$PROJECT_ROOT/backups" -name "backup_*.tar.gz" -printf "%T@ %p\n" | sort -rn | cut -d' ' -f2- | head -10
    exit 1
fi

BACKUP_FILE="$1"

# バックアップファイルの存在確認
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}エラー: バックアップファイルが見つかりません: $BACKUP_FILE${NC}"
    exit 1
fi

# 確認メッセージ
echo -e "${RED}警告: 現在のデータがすべて上書きされます${NC}"
echo -e "${YELLOW}バックアップファイル: $BACKUP_FILE${NC}"
echo -e "${YELLOW}リストア先: $PROJECT_ROOT${NC}"
read -p "本当に実行しますか? (yes/no): " -r
if [[ ! $REPLY == "yes" ]]; then
    echo -e "${RED}キャンセルしました${NC}"
    exit 1
fi

# サービスの停止
echo -e "${YELLOW}関連サービスを停止しています...${NC}"
systemctl stop flask-app.service || true
echo -e "${GREEN}サービスを停止しました${NC}"

# 一時ディレクトリの作成
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# バックアップファイルの解凍
echo -e "${YELLOW}バックアップファイルを解凍しています...${NC}"
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"
echo -e "${GREEN}解凍が完了しました${NC}"

# 現在のデータのバックアップ（リストア前）
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
PRE_RESTORE_BACKUP="$PROJECT_ROOT/backups/pre-restore/backup_pre_restore_${TIMESTAMP}.tar.gz"
mkdir -p "$PROJECT_ROOT/backups/pre-restore"

echo -e "${YELLOW}現在のデータをバックアップしています...${NC}"
cd "$DATA_DIR"
tar -czf "$PRE_RESTORE_BACKUP" ./* 2>/dev/null || echo -e "${YELLOW}バックアップするデータがありません${NC}"
echo -e "${GREEN}現在のデータのバックアップ: $PRE_RESTORE_BACKUP${NC}"

# データベースのリストア
if [ -f "$TEMP_DIR/database/pcsetup.db" ]; then
    echo -e "${YELLOW}データベースをリストアしています...${NC}"
    mkdir -p "$(dirname "$DB_FILE")"
    cp "$TEMP_DIR/database/pcsetup.db" "$DB_FILE"
    chown root:root "$DB_FILE"
    chmod 644 "$DB_FILE"
    echo -e "${GREEN}データベースのリストアが完了しました${NC}"
else
    echo -e "${RED}警告: バックアップにデータベースファイルが含まれていません${NC}"
fi

# ODJファイルのリストア
if [ -d "$TEMP_DIR/odj" ]; then
    echo -e "${YELLOW}ODJファイルをリストアしています...${NC}"
    mkdir -p "$ODJ_DIR"
    rm -rf "$ODJ_DIR"/*
    cp -r "$TEMP_DIR/odj"/* "$ODJ_DIR/" 2>/dev/null || echo -e "${YELLOW}リストアするODJファイルがありません${NC}"
    chown -R root:root "$ODJ_DIR"
    chmod -R 644 "$ODJ_DIR"/*
    echo -e "${GREEN}ODJファイルのリストアが完了しました${NC}"
else
    echo -e "${RED}警告: バックアップにODJファイルが含まれていません${NC}"
fi

# Clonezillaマスターイメージのリストア（存在する場合のみ）
if [ -d "$TEMP_DIR/images" ]; then
    echo -e "${YELLOW}Clonezillaマスターイメージをリストアしています...${NC}"
    IMAGES_DIR="/home/partimag"
    mkdir -p "$IMAGES_DIR"
    cp -r "$TEMP_DIR/images"/* "$IMAGES_DIR/" 2>/dev/null || echo -e "${YELLOW}リストアするイメージがありません${NC}"
    chown -R root:root "$IMAGES_DIR"
    echo -e "${GREEN}マスターイメージのリストアが完了しました${NC}"
else
    echo -e "${YELLOW}バックアップにマスターイメージは含まれていません（スキップ）${NC}"
fi

# 設定ファイルのリストア
if [ -d "$TEMP_DIR/configs" ]; then
    echo -e "${YELLOW}設定ファイルをリストアしています...${NC}"
    mkdir -p "$PROJECT_ROOT/configs"
    cp -r "$TEMP_DIR/configs"/* "$PROJECT_ROOT/configs/" 2>/dev/null || echo -e "${YELLOW}リストアする設定ファイルがありません${NC}"
    echo -e "${GREEN}設定ファイルのリストアが完了しました${NC}"
else
    echo -e "${RED}警告: バックアップに設定ファイルが含まれていません${NC}"
fi

# サービスの再起動
echo -e "${YELLOW}関連サービスを起動しています...${NC}"
systemctl start flask-app.service
sleep 2

if systemctl is-active --quiet flask-app.service; then
    echo -e "${GREEN}サービスが正常に起動しました${NC}"
else
    echo -e "${RED}警告: サービスの起動に失敗しました${NC}"
    echo -e "${YELLOW}ログを確認してください: journalctl -u flask-app.service -n 50${NC}"
fi

echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}リストアが完了しました${NC}"
echo -e "${GREEN}リストア前のデータ: $PRE_RESTORE_BACKUP${NC}"
echo -e "${GREEN}=================================${NC}"

# リストア完了ログの記録
echo "$(date): リストア完了 - $BACKUP_FILE" >> "$PROJECT_ROOT/logs/restore.log"

echo -e "${YELLOW}動作確認を実施してください:${NC}"
echo -e "  - Web管理画面: http://localhost/admin"
echo -e "  - API動作確認: curl http://localhost/api/health"
echo -e "  - データベース確認: sqlite3 $DB_FILE .tables"
