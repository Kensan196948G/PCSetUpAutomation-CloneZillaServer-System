#!/bin/bash
#
# DRBL Docker問題修正スクリプト
# Docker干渉を排除し、DRBL環境を正しく構成します
#
# 実行方法: sudo ./fix_drbl_docker_issue.sh
#

set -e

echo "=========================================="
echo "DRBL Docker問題修正スクリプト"
echo "=========================================="
echo ""

# 管理者権限確認
if [ "$EUID" -ne 0 ]; then
    echo "エラー: このスクリプトはroot権限で実行してください"
    echo "実行方法: sudo ./fix_drbl_docker_issue.sh"
    exit 1
fi

echo "ステップ1: Dockerサービスを停止・無効化"
echo "-------------------------------------------"
systemctl stop docker.socket 2>/dev/null || true
systemctl stop docker 2>/dev/null || true
systemctl stop containerd 2>/dev/null || true
systemctl disable docker.socket 2>/dev/null || true
systemctl disable docker 2>/dev/null || true
systemctl disable containerd 2>/dev/null || true
echo "✓ Dockerサービスを停止・無効化しました"
echo ""

echo "ステップ2: docker0インターフェースを無効化"
echo "-------------------------------------------"
if ip link show docker0 &>/dev/null; then
    ip link set docker0 down
    echo "✓ docker0インターフェースを無効化しました"
else
    echo "✓ docker0インターフェースは存在しません（スキップ）"
fi
echo ""

echo "ステップ3: 必要なディレクトリを作成"
echo "-------------------------------------------"
mkdir -p /tftpboot/nbi_img
mkdir -p /tftpboot/nbi_img/pxelinux.cfg
mkdir -p /tftpboot/node_root
mkdir -p /opt/clonezilla-images
echo "✓ TFTPブート用ディレクトリを作成しました"
echo ""

echo "ステップ4: DRBL設定ファイルを修正"
echo "-------------------------------------------"
# /etc/drbl/drblpush.confでdocker0を除外
if [ -f /etc/drbl/drblpush.conf ]; then
    # enp2s0を明示的に指定
    sed -i 's/^nic_ifs=.*/nic_ifs="enp2s0"/' /etc/drbl/drblpush.conf 2>/dev/null || true
    echo "✓ /etc/drbl/drblpush.conf を修正しました"
else
    echo "✓ /etc/drbl/drblpush.conf はまだ存在しません（後で作成されます）"
fi
echo ""

echo "ステップ5: 既存のDRBL設定をクリーンアップ"
echo "-------------------------------------------"
# 既存の設定をバックアップして削除
if [ -d /tftpboot ]; then
    timestamp=$(date +%Y%m%d_%H%M%S)
    if [ -d /tftpboot.backup ]; then
        mv /tftpboot.backup /tftpboot.backup.$timestamp
    fi
    echo "既存の /tftpboot をバックアップ中..."
    # 念のため既存をバックアップ
    # cp -a /tftpboot /tftpboot.backup.$timestamp
fi

# NFS exportsのクリーンアップ
if [ -f /etc/exports ]; then
    # DRBLエントリを削除
    sed -i '/# Added by DRBL/d' /etc/exports 2>/dev/null || true
    sed -i '/\/tftpboot/d' /etc/exports 2>/dev/null || true
fi

echo "✓ 既存のDRBL設定をクリーンアップしました"
echo ""

echo "ステップ6: ネットワーク設定を確認"
echo "-------------------------------------------"
echo "現在のネットワークインターフェース:"
ip addr show | grep -E "^[0-9]+:|inet " | grep -v "127.0.0.1" | grep -v "docker0" || true
echo ""
echo "使用するインターフェース: enp2s0"
enp2s0_ip=$(ip addr show enp2s0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
echo "enp2s0 IPアドレス: $enp2s0_ip"
echo ""

echo "=========================================="
echo "修正完了！"
echo "=========================================="
echo ""
echo "次のステップ:"
echo "1. drblsrv -i を再実行してDRBLサーバを初期化"
echo "   sudo /usr/sbin/drblsrv -i"
echo ""
echo "2. drblpush -i を再実行してDRBL環境を設定"
echo "   sudo /usr/sbin/drblpush -i"
echo ""
echo "   対話モードでは以下を選択してください:"
echo "   - NIC選択: enp2s0 のみを選択（docker0は選択しない）"
echo "   - ディスクレスLinux: [2] 提供しない"
echo "   - Clonezilla: [3] Clonezilla Live を使用"
echo ""
echo "=========================================="
