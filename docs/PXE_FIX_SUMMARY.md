# PXEブート修復 - エグゼクティブサマリー

## 診断結果

### 根本原因（CRITICAL）
**TFTP Root Directory Mismatch - クライアントがTFTP要求を送信しない理由**

```
設定の不整合:
  DHCP設定        → filename "pxelinux.0"
  TFTP設定ファイル → TFTP_DIRECTORY="/tftpboot"
  実際のプロセス   → /usr/sbin/in.tftpd ... /tftpboot/nbi_img  ← ここが問題！
```

### 問題の流れ
1. ✅ クライアントがDHCPで192.168.3.100を取得（成功）
2. ✅ DHCPから `filename "pxelinux.0"` と `next-server 192.168.3.135` を取得（成功）
3. ❌ クライアントがTFTP要求を送信 → **サーバが応答しない**
4. ❌ クライアントのPXE ROMが即座にタイムアウト
5. ❌ "PXE-M0F Exiting Intel Boot Agent" → ローカルディスク起動

### なぜTFTPログがないのか
- TFTPサーバは起動中（port 69リスニング）
- しかし、**ルートディレクトリの不整合**により、クライアントからの要求に正しく応答できていない
- クライアント側でTFTPタイムアウトが発生し、即座にローカルブートにフォールバック

## 修復スクリプト

### 自動修復（推奨）

```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/scripts
sudo ./fix_pxe_boot.sh
```

**実行内容**:
1. 設定ファイルのバックアップ（`/root/pxe_backup_YYYYMMDD_HHMMSS/`）
2. TFTP root を `/tftpboot` に統一
3. DHCP host宣言追加（MAC: ec:b1:d7:72:e8:38 → IP: 192.168.3.2）
4. ファイル構造検証（symlinks作成）
5. TFTP/DHCPサービス再起動
6. 監視スクリプト作成（`/usr/local/bin/monitor_pxe.sh`）

### 手動テスト

```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/scripts
./test_tftp_manually.sh
```

**期待される出力**:
```
Test 1: Fetching pxelinux.0 (from root)
  ✓ SUCCESS: Downloaded pxelinux.0 (42392 bytes)

Test 2: Fetching nbi_img/pxelinux.0 (from subdirectory)
  ✓ SUCCESS: Downloaded nbi_img/pxelinux.0 (42392 bytes)
```

## 修復後の期待動作

### 1. PXE Boot Sequence
```
Client MAC: ec:b1:d7:72:e8:38
  ↓
DHCP Discover
  ↓
DHCP Offer: 192.168.3.2 (fixed-address)
  ↓
TFTP Request: "GET /pxelinux.0" to 192.168.3.135
  ↓
TFTP Response: 42,392 bytes
  ↓
Client Screen: "PXELINUX 6.03 Copyright (C) 1994-2014 H. Peter Anvin et al"
  ↓
TFTP Request: "GET /pxelinux.cfg/default"
  ↓
Menu Display: "Clonezilla: save disk sda as image 2025-11-17-17-img"
```

### 2. ログ出力例
```
[DHCP] DHCPDISCOVER from ec:b1:d7:72:e8:38 via enp2s0
[DHCP] DHCPOFFER on 192.168.3.2 to ec:b1:d7:72:e8:38 via enp2s0
[DHCP] DHCPREQUEST for 192.168.3.2 from ec:b1:d7:72:e8:38 via enp2s0
[DHCP] DHCPACK on 192.168.3.2 to ec:b1:d7:72:e8:38 via enp2s0
[TFTP] RRQ from 192.168.3.2 filename pxelinux.0
[TFTP] RRQ from 192.168.3.2 filename pxelinux.cfg/default
[TFTP] RRQ from 192.168.3.2 filename vmlinuz-pxe
[TFTP] RRQ from 192.168.3.2 filename initrd-pxe.img
```

## トラブルシューティング

### 修復後もTFTP要求が来ない場合

1. **ホームルータDHCPとの競合確認**:
   ```bash
   # クライアントがどのDHCPサーバから応答を得ているか確認
   tail -f /var/log/syslog | grep dhcpd
   ```

   対策: ルータのDHCP範囲を192.168.3.100以降に限定

2. **TFTP手動テスト**:
   ```bash
   tftp 192.168.3.135 -c get pxelinux.0
   ```

   成功すべき: ファイルダウンロード完了

3. **ネットワークパケット監視**:
   ```bash
   sudo tcpdump -i enp2s0 -n port 69 -vv
   ```

   期待: クライアントからのTFTP RRQパケット

4. **クライアントBIOS設定確認**:
   - PXE Boot: Enabled
   - Boot Order: Network Boot が最優先
   - Legacy BIOS Mode (not UEFI)

### 完全リセット手順

```bash
# バックアップから復元
sudo cp /root/pxe_backup_YYYYMMDD_HHMMSS/dhcpd.conf.bak /etc/dhcp/dhcpd.conf
sudo cp /root/pxe_backup_YYYYMMDD_HHMMSS/tftpd-hpa.bak /etc/default/tftpd-hpa

# サービス再起動
sudo systemctl restart isc-dhcp-server.service
sudo systemctl restart tftpd-hpa.service

# 修復スクリプト再実行
sudo /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/scripts/fix_pxe_boot.sh
```

## 設定ファイルパス

- 診断レポート: `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/docs/PXE_DIAGNOSIS_REPORT.md`
- 修復スクリプト: `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/scripts/fix_pxe_boot.sh`
- テストスクリプト: `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/scripts/test_tftp_manually.sh`
- 監視スクリプト: `/usr/local/bin/monitor_pxe.sh` (修復後に作成)

## 参考情報

- Client MAC: `ec:b1:d7:72:e8:38`
- Fixed IP: `192.168.3.2`
- TFTP Server: `192.168.3.135`
- TFTP Root: `/tftpboot` (修復後)
- Boot File: `pxelinux.0` (42,392 bytes)
- Menu File: `pxelinux.cfg/default` (6,276 bytes)

## 過去の成功例との比較

| 項目 | 過去の成功時 | 現在（修復前） | 修復後 |
|------|------------|--------------|--------|
| DHCP割り当てIP | 192.168.3.2 | 192.168.3.100 | 192.168.3.2 (固定) |
| DHCP経由IF | drbl0 | enp2s0 | enp2s0 or drbl0 |
| TFTP要求 | あり | **なし** | あり（期待） |
| TFTP root | /tftpboot (推定) | /tftpboot/nbi_img | /tftpboot |
| 結果 | BusyBox起動 | M0F エラー | Clonezilla起動（期待） |

## 実行ログ保存先

修復スクリプト実行後、以下のコマンドでログを保存:

```bash
# リアルタイム監視
/usr/local/bin/monitor_pxe.sh

# または手動確認
tail -f /var/log/syslog | grep -E 'dhcpd|tftpd' | tee /tmp/pxe_boot_log.txt
```

## 次のステップ

1. ✅ 修復スクリプト実行: `sudo ./fix_pxe_boot.sh`
2. ✅ TFTP手動テスト: `./test_tftp_manually.sh`
3. ⬜ ホームルータDHCP範囲調整（必要に応じて）
4. ⬜ クライアントPC起動 → PXEブート確認
5. ⬜ ログ監視: `/usr/local/bin/monitor_pxe.sh`

---

**作成日**: 2025-11-17
**診断環境**: Ubuntu 24.04, DRBL 5.3.2, Clonezilla 5.6.13
