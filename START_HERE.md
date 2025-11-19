# 🚀 クイックスタートガイド

**最終更新**: 2025年11月17日 13:45
**所要時間**: 合計20分

---

## ✅ 準備完了状況

- ✅ **開発環境WebUI**: http://192.168.3.135:5000/ （稼働中）
- ✅ **本番環境WebUI**: http://192.168.3.135:8000/ （稼働中）
- ✅ **イメージパス**: /mnt/Linux-ExHDD/Ubuntu-ExHDD （設定済み）
- ✅ **DRBL**: インストール済み（/usr/sbin/）
- ✅ **TFTPサーバ**: 起動中
- ✅ **ネットワーク**: enp2s0 (192.168.3.135)

---

## 🎯 PXEブート環境完成まで（残り2ステップ）

### ステップ1: PXE環境自動セットアップ（5分）

```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project
sudo ./SETUP_PXE_AUTO.sh
```

**パスワード**: ELzion1969

**実行内容**:
1. ✅ DHCP設定ファイル配置（自宅ネットワーク用）
2. ✅ ネットワークインターフェース設定（enp2s0）
3. ✅ DHCP構文チェック
4. ✅ ファイアウォール設定（ポート67, 68, 69, 2049開放）
5. ✅ DHCPサーバ起動

---

### ステップ2: DRBL クライアント設定（10分）

```bash
sudo /usr/sbin/drblpush -i
```

**パスワード**: ELzion1969

**対話式設定**: すべて **デフォルト値でEnterキー** を押し続けるだけでOK

---

## 🖥️ 展開対象PC（192.168.3.139）のBIOS設定

### 設定項目

1. **電源ON** → **F2/F12/Del** でBIOS画面に入る
2. **Boot順序**: Network Boot（PXE Boot）→ 最優先
3. **Secure Boot**: 無効化（Disabled）
4. **F10**: 保存して終了

---

## 🧪 PXEブート動作確認

### 確認手順

**ターミナルでログ監視**:
```bash
sudo tail -f /var/log/syslog | grep -E "dhcpd|tftpd"
```

**展開対象PC再起動**: PXEブートが開始される

**成功時の画面**:
```
>> Start PXE over IPv4.
  Station IP: 192.168.3.139
  Server IP: 192.168.3.135
  
PXELINUX 6.03 ...
Clonezilla Live Menu
```

---

## 📞 問題が発生した場合

### コマンド

```bash
# 診断スクリプト実行
./CHECK_PXE_READINESS.sh

# DHCP状態確認
sudo systemctl status isc-dhcp-server

# ログ確認
sudo journalctl -u isc-dhcp-server -n 50

# TFTPポート確認
sudo netstat -ulnp | grep :69
```

### トラブルシューティングガイド

→ `docs/04_インフラ/自宅環境PXEブート構築ガイド.md`

---

## 🌐 WebUI アクセス

### 開発環境
- URL: http://192.168.3.135:5000/
- 用途: 開発・テスト

### 本番環境
- URL: http://192.168.3.135:8000/
- 用途: 本番運用シミュレーション

---

**今すぐ実行できます！上記2つのコマンドを順番に実行してください。**
