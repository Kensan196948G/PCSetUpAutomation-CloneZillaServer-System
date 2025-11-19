# PXE Boot Quick Reference Card

## 緊急修復（3ステップ）

```bash
# 1. 修復実行
sudo /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/scripts/fix_pxe_boot.sh

# 2. テスト実行
/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/scripts/test_tftp_manually.sh

# 3. ログ監視
/usr/local/bin/monitor_pxe.sh
```

## 問題診断（ワンライナー）

```bash
# TFTP動作確認
ss -uln | grep :69 && ps aux | grep in.tftpd | grep -v grep

# DHCP動作確認
ss -uln | grep :67 && systemctl status isc-dhcp-server --no-pager | head -10

# 最新のPXEログ
tail -50 /var/log/syslog | grep -E 'dhcpd|tftpd' | tail -20

# TFTP手動テスト
tftp 192.168.3.135 -c get pxelinux.0 && ls -lh pxelinux.0

# 設定確認
grep -E 'next-server|filename' /etc/dhcp/dhcpd.conf | grep -A2 'subnet 192.168.3.0'
grep TFTP_DIRECTORY /etc/default/tftpd-hpa
```

## 期待される正常状態

### サービス状態
```bash
$ ss -uln | grep -E ':(67|69) '
udp  0  0  0.0.0.0:67   0.0.0.0:*  # DHCP
udp  0  0  0.0.0.0:69   0.0.0.0:*  # TFTP
```

### 設定値
```
DHCP: next-server 192.168.3.135
DHCP: filename "pxelinux.0"
TFTP: TFTP_DIRECTORY="/tftpboot"
Process: /usr/sbin/in.tftpd ... /tftpboot
```

### クライアント情報
```
MAC:  ec:b1:d7:72:e8:38
IP:   192.168.3.2 (fixed-address)
Boot: pxelinux.0 (42,392 bytes)
```

## トラブルシューティング決定木

```
PXEブート失敗？
├─ DHCP失敗 → 「DHCPログなし」
│   ├─ ルータDHCPが優先 → ルータ設定変更
│   ├─ isc-dhcp-server停止 → systemctl start isc-dhcp-server
│   └─ インターフェース設定 → /etc/default/isc-dhcp-server 確認
│
├─ DHCP成功 → 「192.168.3.X割り当て」
│   └─ TFTP失敗 → 「TFTPログなし」★ ← あなたはここ
│       ├─ TFTPサービス停止 → systemctl start tftpd-hpa
│       ├─ ポート69未リスニング → ps aux | grep in.tftpd
│       ├─ TFTPルート不整合 ★★★ ← 今回の原因
│       │   └─ fix_pxe_boot.sh 実行
│       └─ ファイル不在 → ls -la /tftpboot/pxelinux.0
│
└─ TFTP成功 → 「pxelinux.0ダウンロード成功」
    └─ メニュー不表示
        ├─ pxelinux.cfg/default不在 → ls -la /tftpboot/pxelinux.cfg/default
        └─ vmlinuz/initrd不在 → ls -la /tftpboot/nbi_img/
```

## よく使うコマンド集

### サービス制御
```bash
# 再起動
sudo systemctl restart tftpd-hpa isc-dhcp-server

# 状態確認
systemctl status tftpd-hpa isc-dhcp-server

# ログ確認
journalctl -u tftpd-hpa -n 50
journalctl -u isc-dhcp-server -n 50
```

### ファイル検証
```bash
# 必須ファイル存在確認
ls -lh /tftpboot/pxelinux.0
ls -lh /tftpboot/nbi_img/pxelinux.0
ls -lh /tftpboot/pxelinux.cfg/default
ls -lh /tftpboot/nbi_img/vmlinuz-pxe
ls -lh /tftpboot/nbi_img/initrd-pxe.img

# シンボリックリンク確認
find /tftpboot -maxdepth 1 -type l -ls
```

### ネットワーク監視
```bash
# DHCP/TFTPパケット監視
sudo tcpdump -i enp2s0 -n port 67 or port 68 or port 69 -vv

# クライアントMAC特定監視
sudo tcpdump -i enp2s0 -e -n ether host ec:b1:d7:72:e8:38
```

## ディレクトリ構造（正常時）

```
/tftpboot/
├── pxelinux.0 -> /tftpboot/nbi_img/pxelinux.0 (symlink)
├── pxelinux.cfg -> /tftpboot/nbi_img/pxelinux.cfg (symlink)
├── initrd-pxe.img -> /tftpboot/nbi_img/initrd-pxe.img (symlink)
├── vmlinuz-pxe -> /tftpboot/nbi_img/vmlinuz-pxe (symlink)
└── nbi_img/
    ├── pxelinux.0 (42,392 bytes)
    ├── pxelinux.cfg/
    │   └── default (6,276 bytes)
    ├── vmlinuz-pxe
    ├── initrd-pxe.img -> initrd-pxe.6.8.0-87-generic.img
    └── ... (other boot files)
```

## 設定ファイルパス一覧

| 役割 | ファイルパス |
|------|------------|
| DHCP設定 | `/etc/dhcp/dhcpd.conf` |
| DHCPインターフェース | `/etc/default/isc-dhcp-server` |
| TFTP設定 | `/etc/default/tftpd-hpa` |
| NFS設定 | `/etc/exports` |
| PXEメニュー | `/tftpboot/nbi_img/pxelinux.cfg/default` |
| 修復スクリプト | `/mnt/Linux-ExHDD/.../scripts/fix_pxe_boot.sh` |
| テストスクリプト | `/mnt/Linux-ExHDD/.../scripts/test_tftp_manually.sh` |
| 監視スクリプト | `/usr/local/bin/monitor_pxe.sh` |

## 緊急連絡先（ログ）

```bash
# 全体ログ
tail -f /var/log/syslog

# DHCP専用
journalctl -u isc-dhcp-server -f

# TFTP専用
journalctl -u tftpd-hpa -f

# 統合監視（推奨）
/usr/local/bin/monitor_pxe.sh
```

## チェックリスト

修復前:
- [ ] バックアップ確認: `ls -la /root/pxe_backup_*`
- [ ] 現在のTFTPルート確認: `ps aux | grep in.tftpd`
- [ ] 現在のDHCP設定確認: `grep filename /etc/dhcp/dhcpd.conf`

修復後:
- [ ] TFTPサービス起動: `systemctl status tftpd-hpa`
- [ ] DHCPサービス起動: `systemctl status isc-dhcp-server`
- [ ] ポート67/69リスニング: `ss -uln | grep -E ':(67|69) '`
- [ ] TFTP手動テスト成功: `tftp 192.168.3.135 -c get pxelinux.0`
- [ ] 設定ファイル整合性: TFTPルート = /tftpboot

PXEブート試験:
- [ ] クライアントMAC確認: ec:b1:d7:72:e8:38
- [ ] BIOS設定: PXE Boot Enabled
- [ ] ログ監視開始: `/usr/local/bin/monitor_pxe.sh`
- [ ] クライアント起動
- [ ] DHCP DISCOVER/OFFER/ACK 確認
- [ ] TFTP RRQ 確認
- [ ] PXELINUX画面表示確認
- [ ] メニュー選択 → Clonezilla起動

---

**最終更新**: 2025-11-17
**適用環境**: Ubuntu 24.04, DRBL 5.3.2
