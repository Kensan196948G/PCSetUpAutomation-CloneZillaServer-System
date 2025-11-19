#!/bin/bash
# マルチキャストで複数のPCに一斉展開するスクリプト
# 使用方法: sudo ./03-deploy-multicast.sh <イメージ名> [台数] [タイムアウト秒]

set -e

# 引数チェック
if [ $# -lt 1 ]; then
    echo "使用方法: sudo ./03-deploy-multicast.sh <イメージ名> [台数] [タイムアウト秒]"
    echo "例: sudo ./03-deploy-multicast.sh win11-base-2025 20 600"
    echo ""
    echo "引数:"
    echo "  イメージ名     : 展開するイメージ名（必須）"
    echo "  台数          : 展開するPC台数（デフォルト: 10）"
    echo "  タイムアウト秒 : クライアント待機時間（デフォルト: 600秒=10分）"
    exit 1
fi

IMAGE_NAME="$1"
CLIENT_COUNT="${2:-10}"
TIMEOUT="${3:-600}"
DISK="${4:-sda}"

# rootチェック
if [ "$EUID" -ne 0 ]; then 
    echo "エラー: このスクリプトはroot権限で実行してください"
    exit 1
fi

# イメージの存在確認
if [ ! -d "/home/partimag/$IMAGE_NAME" ]; then
    echo "エラー: イメージ '$IMAGE_NAME' が見つかりません"
    echo ""
    echo "利用可能なイメージ:"
    ls -1 /home/partimag/ | grep -v "^scripts$\|^logs$"
    exit 1
fi

echo "=========================================="
echo "Clonezilla マルチキャスト展開"
echo "=========================================="
echo "イメージ名: $IMAGE_NAME"
echo "展開台数: $CLIENT_COUNT"
echo "タイムアウト: $TIMEOUT 秒 ($(($TIMEOUT/60))分)"
echo "対象ディスク: $DISK"
echo "=========================================="
echo ""

# イメージ情報表示
if [ -f "/home/partimag/$IMAGE_NAME/disk" ]; then
    echo "イメージ情報:"
    cat "/home/partimag/$IMAGE_NAME/disk"
    echo ""
fi

# 確認プロンプト
read -p "この設定で展開を開始しますか？ (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "中止しました"
    exit 1
fi

echo ""
echo "Clonezilla Server Edition を起動します..."
echo ""
echo "次の手順:"
echo "1. ブラウザで http://192.168.100.1:2556 にアクセス"
echo "2. 以下の設定を選択:"
echo "   - Mode: Beginner"
echo "   - Task: restoredisk"
echo "   - Image name: $IMAGE_NAME"
echo "   - Target disk: $DISK"
echo "   - Mode: Multicast"
echo "   - Clients: $CLIENT_COUNT"
echo "   - Time to wait: $TIMEOUT seconds"
echo "3. すべてのターゲットPCをPXEブートで起動"
echo "4. 指定台数が揃うかタイムアウト後に自動的に展開開始"
echo ""
echo "モニタリングコマンド:"
echo "  sudo tail -f /var/log/clonezilla/clonezilla-*.log"
echo "  sudo iftop -i enp0s3"
echo ""
read -p "準備ができたらEnterキーを押してください..."

# ログ記録開始
LOG_FILE="/home/partimag/logs/deployment-$(date +%Y%m%d-%H%M%S).log"
echo "展開ログ: $LOG_FILE"
echo "========================================" > "$LOG_FILE"
echo "展開開始時刻: $(date)" >> "$LOG_FILE"
echo "イメージ名: $IMAGE_NAME" >> "$LOG_FILE"
echo "展開台数: $CLIENT_COUNT" >> "$LOG_FILE"
echo "タイムアウト: $TIMEOUT 秒" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

# Clonezilla SE起動
/usr/sbin/dcs

# 展開完了記録
echo "" >> "$LOG_FILE"
echo "展開完了時刻: $(date)" >> "$LOG_FILE"

echo ""
echo "=========================================="
echo "展開プロセスが完了しました"
echo "=========================================="
echo ""
echo "展開ログ: $LOG_FILE"
echo ""
echo "次のステップ:"
echo "1. すべてのPCが正常に起動することを確認"
echo "2. Windows設定とアプリケーションの動作確認"
echo "3. ネットワーク接続とドメイン参加の確認"
echo ""

# 展開履歴をCSVに記録
HISTORY_CSV="/home/partimag/logs/deployment-history.csv"
if [ ! -f "$HISTORY_CSV" ]; then
    echo "日時,イメージ名,台数,結果" > "$HISTORY_CSV"
fi
echo "$(date '+%Y-%m-%d %H:%M:%S'),$IMAGE_NAME,$CLIENT_COUNT,success" >> "$HISTORY_CSV"

echo "展開履歴を記録しました: $HISTORY_CSV"
