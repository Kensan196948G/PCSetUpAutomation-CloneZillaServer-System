#!/bin/bash
# システム状態とサービスをチェックするスクリプト
# 使用方法: ./05-check-status.sh

echo "=========================================="
echo "Clonezilla Server ステータスチェック"
echo "=========================================="
echo ""

# ネットワーク設定確認
echo "[ ネットワーク設定 ]"
ip addr show | grep -E "^[0-9]+:|inet " | grep -v "127.0.0.1"
echo ""

# サービス状態確認
echo "[ サービス状態 ]"
echo ""

# NFS
echo "NFS Server:"
if systemctl is-active --quiet nfs-kernel-server; then
    echo "  ✓ 起動中"
else
    echo "  ✗ 停止中"
fi

# Dnsmasq (DHCP/TFTP)
echo "Dnsmasq (DHCP/TFTP):"
if systemctl is-active --quiet dnsmasq; then
    echo "  ✓ 起動中"
else
    echo "  ✗ 停止中"
fi

echo ""

# DHCPリース確認
echo "[ DHCPリース ]"
if [ -f /var/lib/misc/dnsmasq.leases ]; then
    LEASE_COUNT=$(wc -l < /var/lib/misc/dnsmasq.leases)
    echo "アクティブなリース: $LEASE_COUNT"
    if [ $LEASE_COUNT -gt 0 ]; then
        echo ""
        echo "最近のリース:"
        tail -n 5 /var/lib/misc/dnsmasq.leases | while read line; do
            echo "  $line"
        done
    fi
else
    echo "リースファイルが見つかりません"
fi
echo ""

# ディスク使用状況
echo "[ ディスク使用状況 ]"
echo "イメージディレクトリ:"
df -h /home/partimag | tail -n 1
echo ""

# イメージ数とサイズ
if [ -d /home/partimag ]; then
    IMAGE_COUNT=0
    TOTAL_SIZE=0
    
    for IMAGE in /home/partimag/*; do
        if [ -d "$IMAGE" ]; then
            BASENAME=$(basename "$IMAGE")
            if [ "$BASENAME" != "scripts" ] && [ "$BASENAME" != "logs" ]; then
                if [ -f "$IMAGE/disk" ] || [ -f "$IMAGE/parts" ]; then
                    IMAGE_COUNT=$((IMAGE_COUNT + 1))
                fi
            fi
        fi
    done
    
    if [ $IMAGE_COUNT -gt 0 ]; then
        TOTAL_SIZE=$(du -sh /home/partimag 2>/dev/null | cut -f1)
        echo "イメージ数: $IMAGE_COUNT"
        echo "合計サイズ: $TOTAL_SIZE"
    else
        echo "イメージ数: 0"
    fi
fi
echo ""

# ポート確認
echo "[ ポート状態 ]"
echo "DHCP (67/udp):"
if netstat -ulnp 2>/dev/null | grep -q ":67 "; then
    echo "  ✓ リスニング中"
else
    echo "  ✗ リスニングしていません"
fi

echo "TFTP (69/udp):"
if netstat -ulnp 2>/dev/null | grep -q ":69 "; then
    echo "  ✓ リスニング中"
else
    echo "  ✗ リスニングしていません"
fi

echo "NFS (2049/tcp):"
if netstat -tlnp 2>/dev/null | grep -q ":2049 "; then
    echo "  ✓ リスニング中"
else
    echo "  ✗ リスニングしていません"
fi
echo ""

# NFSエクスポート確認
echo "[ NFSエクスポート ]"
showmount -e localhost 2>/dev/null || echo "NFSエクスポートの確認に失敗"
echo ""

# システムリソース
echo "[ システムリソース ]"
echo "CPU使用率:"
top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "  " 100 - $1 "%"}'

echo "メモリ使用率:"
free -h | grep Mem | awk '{print "  " $3 " / " $2 " (" int($3/$2 * 100) "%)"}'

echo "ロードアベレージ:"
uptime | awk -F'load average:' '{print "  " $2}'
echo ""

# 最近のログ
echo "[ 最近のログ（エラーのみ）]"
if [ -d /var/log/clonezilla ]; then
    LATEST_LOG=$(ls -t /var/log/clonezilla/*.log 2>/dev/null | head -n 1)
    if [ -n "$LATEST_LOG" ]; then
        echo "最新のClonezillaログ: $(basename $LATEST_LOG)"
        grep -i "error\|fail" "$LATEST_LOG" 2>/dev/null | tail -n 5 || echo "  エラーなし"
    else
        echo "Clonezillaログが見つかりません"
    fi
else
    echo "Clonezillaログディレクトリが見つかりません"
fi
echo ""

# システムアップタイム
echo "[ システム情報 ]"
echo "アップタイム:"
uptime -p | sed 's/up /  /'
echo ""

echo "=========================================="
echo "ステータスチェック完了"
echo "=========================================="
