#!/bin/bash
# PXEブート環境準備確認スクリプト

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          PXEブート環境準備確認スクリプト                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "【確認日時】: $(date '+%Y年%m月%d日 %H:%M:%S')"
echo ""

# 1. DRBLインストール確認
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "■ 1. DRBLインストール状況"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if which drblsrv >/dev/null 2>&1; then
    echo "✅ DRBL インストール済み"
    drblsrv --version 2>/dev/null || echo "  バージョン情報取得不可"
else
    echo "❌ DRBL 未インストール"
    echo "  → sudo apt install drbl clonezilla"
fi
echo ""

# 2. DHCPサーバ状態
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "■ 2. DHCPサーバ状態"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if systemctl is-active --quiet isc-dhcp-server; then
    echo "✅ DHCP サーバ起動中"
    echo "  プロセス: $(pgrep dhcpd)"
else
    echo "❌ DHCP サーバ停止中"
    echo "  → sudo systemctl start isc-dhcp-server"
fi
echo ""

# 3. TFTPサーバ状態
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "■ 3. TFTPサーバ状態"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if systemctl is-active --quiet tftpd-hpa; then
    echo "✅ TFTP サーバ起動中"
    echo "  プロセス: $(pgrep tftpd)"
else
    echo "❌ TFTP サーバ停止中"
    echo "  → sudo systemctl start tftpd-hpa"
fi
echo ""

# 4. PXEブートファイル存在確認
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "■ 4. PXEブートファイル"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f /tftpboot/pxelinux.0 ]; then
    echo "✅ pxelinux.0 存在"
    ls -lh /tftpboot/pxelinux.0
else
    echo "❌ pxelinux.0 不在"
    echo "  → sudo drblsrv -i で自動作成"
fi
echo ""

# 5. Clonezillaイメージ存在確認
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "■ 5. Clonezillaイメージ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
IMAGE_PATH="/mnt/Linux-ExHDD/Ubuntu-ExHDD"
if [ -d "$IMAGE_PATH" ]; then
    echo "✅ イメージパス存在: $IMAGE_PATH"
    IMAGE_COUNT=$(find "$IMAGE_PATH" -maxdepth 1 -type d | wc -l)
    echo "  イメージ数: $((IMAGE_COUNT - 1)) 個"
    ls -lh "$IMAGE_PATH" | head -10
else
    echo "❌ イメージパス不在: $IMAGE_PATH"
    echo "  → mkdir -p $IMAGE_PATH"
fi
echo ""

# 6. ファイアウォール設定確認
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "■ 6. ファイアウォール設定"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if which ufw >/dev/null 2>&1; then
    if sudo ufw status | grep -q "67/udp.*ALLOW"; then
        echo "✅ DHCP（67/udp）許可"
    else
        echo "❌ DHCP（67/udp）未許可 → sudo ufw allow 67/udp"
    fi
    
    if sudo ufw status | grep -q "69/udp.*ALLOW"; then
        echo "✅ TFTP（69/udp）許可"
    else
        echo "❌ TFTP（69/udp）未許可 → sudo ufw allow 69/udp"
    fi
else
    echo "⚠️ UFW未インストール（ファイアウォール無効の可能性）"
fi
echo ""

# 7. ネットワーク疎通確認
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "■ 7. ネットワーク疎通確認"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ping -c 1 192.168.3.1 >/dev/null 2>&1; then
    echo "✅ ルータ（192.168.3.1）疎通OK"
else
    echo "❌ ルータ疎通NG"
fi

if ping -c 1 192.168.3.139 >/dev/null 2>&1; then
    echo "✅ 展開対象PC（192.168.3.139）疎通OK"
else
    echo "⚠️ 展開対象PC（192.168.3.139）疎通NG（電源OFF?）"
fi
echo ""

# 8. 総合判定
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "■ 8. PXEブート準備状況"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "次のステップ:"
echo "1. 展開対象PC（192.168.3.139）のBIOS設定"
echo "   - Boot順序: Network Boot最優先"
echo "   - Secure Boot: 無効化"
echo "2. PC再起動してPXEブート試行"
echo "3. Clonezillaメニューが表示されることを確認"
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                確認完了                                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
