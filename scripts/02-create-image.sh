#!/bin/bash
# マスターPCからイメージを作成するスクリプト
# 使用方法: sudo ./02-create-image.sh <イメージ名>

set -e

# 引数チェック
if [ $# -lt 1 ]; then
    echo "使用方法: sudo ./02-create-image.sh <イメージ名>"
    echo "例: sudo ./02-create-image.sh win11-base-2025"
    exit 1
fi

IMAGE_NAME="$1"
DISK="${2:-sda}"  # デフォルトはsda
COMPRESSION="${3:-z1p}"  # デフォルトは並列gzip圧縮

# rootチェック
if [ "$EUID" -ne 0 ]; then 
    echo "エラー: このスクリプトはroot権限で実行してください"
    echo "使用方法: sudo ./02-create-image.sh <イメージ名>"
    exit 1
fi

echo "=========================================="
echo "Clonezilla イメージ作成"
echo "=========================================="
echo "イメージ名: $IMAGE_NAME"
echo "対象ディスク: $DISK"
echo "圧縮方式: $COMPRESSION"
echo "=========================================="
echo ""

# イメージディレクトリの存在確認
if [ -d "/home/partimag/$IMAGE_NAME" ]; then
    echo "警告: イメージ '$IMAGE_NAME' は既に存在します"
    read -p "上書きしますか？ (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "既存のイメージを削除します..."
        rm -rf "/home/partimag/$IMAGE_NAME"
    else
        echo "中止しました"
        exit 1
    fi
fi

echo "Clonezilla Server Edition を起動します..."
echo ""
echo "次の手順:"
echo "1. ブラウザで http://192.168.100.1:2556 にアクセス"
echo "2. 以下の設定を選択:"
echo "   - Mode: Beginner"
echo "   - Task: savedisk"
echo "   - Image name: $IMAGE_NAME"
echo "   - Select disk: $DISK"
echo "   - Compression: $COMPRESSION"
echo "   - Clients: 1 (マスターPC1台)"
echo "3. マスターPCをPXEブートで起動"
echo "4. イメージ作成が完了するまで待機"
echo ""
read -p "準備ができたらEnterキーを押してください..."

# Clonezilla SE起動
/usr/sbin/dcs

echo ""
echo "=========================================="
echo "イメージ作成プロセスが完了しました"
echo "=========================================="
echo ""
echo "イメージの確認:"
echo "  ls -lh /home/partimag/$IMAGE_NAME/"
echo ""
echo "イメージ情報:"
echo "  cat /home/partimag/$IMAGE_NAME/disk"
echo "  cat /home/partimag/$IMAGE_NAME/parts"
echo ""
