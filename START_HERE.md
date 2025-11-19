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
- ⚠️ **Docker**: 無効化済み（DRBL環境には必須）

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

### Docker干渉問題（最重要）

**症状**: drblpush実行時に `docker0` インターフェースが検出される

**解決方法**:
```bash
# 自動修正スクリプトを実行
sudo ./scripts/fix_drbl_docker_issue.sh
```

**詳細**: [DRBL_FIX_DOCKER_GUIDE.md](./docs/04_インフラ/DRBL_FIX_DOCKER_GUIDE.md)

---

### 一般的なコマンド

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
→ `docs/08_トラブルシューティング/トラブルシューティング集.md`

---

## 🌐 WebUI アクセス

### 開発環境
- URL: http://192.168.3.135:5000/
- 用途: 開発・テスト

### 本番環境
- URL: http://192.168.3.135:8000/
- 用途: 本番運用シミュレーション

---

## 📋 前提条件チェックリスト

PXEブート環境構築前に、以下を確認してください：

- [ ] Dockerサービスが停止・無効化されている（`systemctl status docker`）
- [ ] `docker0` インターフェースが存在しない（`ip addr show docker0` でエラー）
- [ ] atftpdが削除されている（`dpkg -l | grep atftpd` で何も表示されない）
- [ ] tftpd-hpaがインストール済み（`systemctl status tftpd-hpa`）
- [ ] 物理NIC（enp2s0等）が正常に動作している

**前提条件を満たしていない場合**:
```bash
sudo ./scripts/fix_drbl_docker_issue.sh
```

---

**今すぐ実行できます！上記2つのコマンドを順番に実行してください。**

**最終更新日**: 2025-11-19
