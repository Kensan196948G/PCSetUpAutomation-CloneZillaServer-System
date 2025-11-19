#!/bin/bash
# イメージ一覧と詳細情報を表示するスクリプト
# 使用方法: ./04-list-images.sh [イメージ名]

IMAGE_DIR="/home/partimag"

# 特定のイメージ詳細表示
if [ $# -ge 1 ]; then
    IMAGE_NAME="$1"
    IMAGE_PATH="$IMAGE_DIR/$IMAGE_NAME"
    
    if [ ! -d "$IMAGE_PATH" ]; then
        echo "エラー: イメージ '$IMAGE_NAME' が見つかりません"
        exit 1
    fi
    
    echo "=========================================="
    echo "イメージ詳細: $IMAGE_NAME"
    echo "=========================================="
    echo ""
    
    # ディスク情報
    if [ -f "$IMAGE_PATH/disk" ]; then
        echo "[ ディスク情報 ]"
        cat "$IMAGE_PATH/disk"
        echo ""
    fi
    
    # パーティション情報
    if [ -f "$IMAGE_PATH/parts" ]; then
        echo "[ パーティション情報 ]"
        cat "$IMAGE_PATH/parts"
        echo ""
    fi
    
    # ファイルサイズ
    echo "[ ファイル一覧 ]"
    ls -lh "$IMAGE_PATH/" | tail -n +2
    echo ""
    
    # 合計サイズ
    TOTAL_SIZE=$(du -sh "$IMAGE_PATH" | cut -f1)
    echo "[ 合計サイズ ]"
    echo "$TOTAL_SIZE"
    echo ""
    
    # 作成日時
    CREATE_TIME=$(stat -c %y "$IMAGE_PATH" | cut -d'.' -f1)
    echo "[ 作成日時 ]"
    echo "$CREATE_TIME"
    echo ""
    
    exit 0
fi

# イメージ一覧表示
echo "=========================================="
echo "利用可能なClonezillaイメージ"
echo "=========================================="
echo ""

if [ ! -d "$IMAGE_DIR" ]; then
    echo "エラー: イメージディレクトリが見つかりません: $IMAGE_DIR"
    exit 1
fi

# イメージディレクトリのリスト取得
IMAGE_COUNT=0
for IMAGE in "$IMAGE_DIR"/*; do
    if [ -d "$IMAGE" ]; then
        BASENAME=$(basename "$IMAGE")
        
        # システムディレクトリをスキップ
        if [ "$BASENAME" = "scripts" ] || [ "$BASENAME" = "logs" ]; then
            continue
        fi
        
        # イメージディレクトリのみ処理
        if [ -f "$IMAGE/disk" ] || [ -f "$IMAGE/parts" ]; then
            IMAGE_COUNT=$((IMAGE_COUNT + 1))
            
            SIZE=$(du -sh "$IMAGE" 2>/dev/null | cut -f1)
            DATE=$(stat -c %y "$IMAGE" 2>/dev/null | cut -d' ' -f1)
            
            echo "[$IMAGE_COUNT] $BASENAME"
            echo "    サイズ: $SIZE"
            echo "    作成日: $DATE"
            
            # ディスク情報があれば表示
            if [ -f "$IMAGE/disk" ]; then
                DISK_INFO=$(head -n 1 "$IMAGE/disk" 2>/dev/null)
                echo "    ディスク: $DISK_INFO"
            fi
            
            echo ""
        fi
    fi
done

if [ $IMAGE_COUNT -eq 0 ]; then
    echo "イメージが見つかりません"
    echo ""
    echo "イメージを作成するには:"
    echo "  sudo ./02-create-image.sh <イメージ名>"
else
    echo "合計: $IMAGE_COUNT イメージ"
    echo ""
    echo "イメージの詳細を表示:"
    echo "  ./04-list-images.sh <イメージ名>"
fi

echo ""
echo "ディスク使用状況:"
df -h "$IMAGE_DIR" | tail -n 1
echo ""
