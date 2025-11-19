#!/bin/bash
# NFSエクスポート完全修正スクリプト
# 目的: 192.168.3.109のNFSアクセス拒否を解決

set -e

echo "=========================================="
echo "NFSエクスポート完全修正開始"
echo "=========================================="

# 1. 既存設定のバックアップ
echo "[1/6] 既存設定をバックアップ中..."
sudo cp /etc/exports /etc/exports.backup.final.$(date +%Y%m%d_%H%M%S)
echo "✅ バックアップ完了: /etc/exports.backup.final.$(date +%Y%m%d_%H%M%S)"

# 2. /etc/exportsの内容確認
echo ""
echo "[2/6] 現在の/etc/exports内容:"
echo "----------------------------------------"
cat /etc/exports
echo "----------------------------------------"

# 3. サブネット形式への変換
echo ""
echo "[3/6] IP範囲をサブネット形式に変換中..."

# 一時ファイルに出力
sudo awk '
{
    # 個別IP指定(192.168.3.X)をサブネット形式(192.168.3.0/24)に変換
    gsub(/192\.168\.3\.[0-9]+ /, "192.168.3.0/24 ");
    gsub(/192\.168\.3\.[0-9]+\(/, "192.168.3.0/24(");
    print;
}
' /etc/exports > /tmp/exports.converted

# 重複行を削除
awk '!seen[$0]++' /tmp/exports.converted > /tmp/exports.clean

# 空行を削除
grep -v '^$' /tmp/exports.clean > /tmp/exports.final || true

# 適用
sudo cp /tmp/exports.final /etc/exports

echo "✅ サブネット形式への変換完了"

# 4. 変換後の内容確認
echo ""
echo "[4/6] 変換後の/etc/exports内容:"
echo "----------------------------------------"
cat /etc/exports
echo "----------------------------------------"

# 5. NFS再エクスポート
echo ""
echo "[5/6] NFS再エクスポート中..."
sudo exportfs -rv
echo "✅ NFS再エクスポート完了"

# 6. NFSサービス再起動
echo ""
echo "[6/6] NFSサービス再起動中..."
sudo systemctl restart nfs-server
sudo systemctl restart nfs-kernel-server 2>/dev/null || true

sleep 2

# 最終確認
echo ""
echo "=========================================="
echo "最終確認"
echo "=========================================="

echo ""
echo "[NFSエクスポート状況]"
sudo exportfs -v

echo ""
echo "[NFSサービス状態]"
sudo systemctl status nfs-server --no-pager -l

echo ""
echo "=========================================="
echo "✅ NFSエクスポート完全修正完了"
echo "=========================================="
echo ""
echo "次のステップ:"
echo "1. PCを再起動してPXEブートを試行"
echo "2. NFSマウント成功 → Clonezillaメニュー表示を確認（2〜5分）"
echo "3. 192.168.3.109がNFSマウントできることを確認"
echo ""
