# PXEブート環境構築手順

## 目次
1. [PXEブート概要](#pxeブート概要)
2. [前提条件](#前提条件)
3. [DHCP設定](#dhcp設定)
4. [TFTP設定](#tftp設定)
5. [PXEブートメニュー設定](#pxeブートメニュー設定)
6. [NFSエクスポート設定](#nfsエクスポート設定)
7. [ファイアウォール設定](#ファイアウォール設定)
8. [動作確認](#動作確認)
9. [トラブルシューティング](#トラブルシューティング)

---

## PXEブート概要

### PXE (Preboot Execution Environment) とは
ネットワーク経由でOSやツールを起動する仕組みです。

### 動作フロー
```
1. クライアントPC起動
   ↓
2. PXE ROMがDHCP Request送信
   ↓
3. DHCPサーバーがIPアドレス、TFTPサーバー情報を返答
   ↓
4. TFTPサーバーからブートローダー（pxelinux.0）をダウンロード
   ↓
5. ブートローダーが起動メニュー設定を読み込み
   ↓
6. ユーザー選択またはデフォルトでOSイメージを起動
   ↓
7. Clonezilla起動、イメージ展開
```

### 必要なサービス
- **DHCP**: IPアドレス配布、ブートサーバー情報提供
- **TFTP**: ブートイメージ配信
- **NFS**: ルートファイルシステム提供
- **HTTP/FTP**: オプション（大容量ファイル配信用）

---

## 前提条件

### 環境情報
```bash
# サーバー情報
SERVER_IP="192.168.1.100"
SERVER_HOSTNAME="drbl-server"

# ネットワーク情報
NETWORK="192.168.1.0/24"
GATEWAY="192.168.1.1"
DNS_SERVER="8.8.8.8"

# DHCPスコープ
DHCP_START="192.168.1.150"
DHCP_END="192.168.1.200"
```

### 必要なパッケージ
```bash
sudo apt update
sudo apt install -y \
    isc-dhcp-server \
    tftpd-hpa \
    nfs-kernel-server \
    syslinux \
    pxelinux \
    syslinux-common
```

---

## DHCP設定

### 1. DHCPサーバーのインストールと設定

```bash
# isc-dhcp-server インストール
sudo apt install -y isc-dhcp-server
```

### 2. DHCP設定ファイルの編集

```bash
# 既存設定のバックアップ
sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak

# 設定ファイルの編集
sudo vim /etc/dhcp/dhcpd.conf
```

**設定内容**:
```conf
# /etc/dhcp/dhcpd.conf
# DRBL/Clonezilla用DHCP設定

# グローバル設定
option domain-name "local";
option domain-name-servers 8.8.8.8, 8.8.4.4;

default-lease-time 600;
max-lease-time 7200;

# DHCPサーバーを権威サーバーとして設定
authoritative;

# ログ設定
log-facility local7;

# PXEブート用設定
allow booting;
allow bootp;

# サブネット設定
subnet 192.168.1.0 netmask 255.255.255.0 {
    # DHCPスコープ
    range 192.168.1.150 192.168.1.200;

    # ゲートウェイ
    option routers 192.168.1.1;

    # サブネットマスク
    option subnet-mask 255.255.255.0;

    # ブロードキャストアドレス
    option broadcast-address 192.168.1.255;

    # DNSサーバー
    option domain-name-servers 8.8.8.8, 8.8.4.4;

    # PXEブート設定
    next-server 192.168.1.100;           # TFTPサーバーのIP
    filename "pxelinux.0";                # ブートファイル名

    # リース時間
    default-lease-time 600;
    max-lease-time 7200;
}

# 固定IPアドレス割り当て（オプション）
host test-pc-01 {
    hardware ethernet 00:11:22:33:44:55;
    fixed-address 192.168.1.101;
    option host-name "test-pc-01";
}

# UEFIブート対応（オプション）
class "pxeclients" {
    match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
    next-server 192.168.1.100;

    # BIOS PXE
    if substring (option vendor-class-identifier, 15, 5) = "00000" {
        filename "pxelinux.0";
    }
    # UEFI PXE (64bit)
    else if substring (option vendor-class-identifier, 15, 5) = "00007" {
        filename "bootx64.efi";
    }
    # UEFI PXE (32bit)
    else if substring (option vendor-class-identifier, 15, 5) = "00006" {
        filename "bootia32.efi";
    }
    # その他
    else {
        filename "pxelinux.0";
    }
}
```

### 3. DHCPサーバーのインターフェース設定

```bash
# インターフェース設定ファイルの編集
sudo vim /etc/default/isc-dhcp-server
```

**設定内容**:
```bash
# /etc/default/isc-dhcp-server

# IPv4用インターフェース（使用するNICを指定）
INTERFACESv4="ens33"

# IPv6は無効
INTERFACESv6=""
```

### 4. DHCP設定の検証と起動

```bash
# 設定ファイルの文法チェック
sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf

# DHCPサーバーの起動
sudo systemctl restart isc-dhcp-server

# 自動起動を有効化
sudo systemctl enable isc-dhcp-server

# 状態確認
sudo systemctl status isc-dhcp-server

# DHCPリース状況の確認
sudo cat /var/lib/dhcp/dhcpd.leases
```

---

## TFTP設定

### 1. TFTPサーバーのインストール

```bash
# tftpd-hpa インストール
sudo apt install -y tftpd-hpa
```

### 2. TFTP設定

```bash
# TFTP設定ファイルの編集
sudo vim /etc/default/tftpd-hpa
```

**設定内容**:
```bash
# /etc/default/tftpd-hpa

# TFTPルートディレクトリ
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/tftpboot"

# TFTPオプション
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure --create"
```

### 3. TFTPディレクトリの作成

```bash
# TFTPルートディレクトリ作成
sudo mkdir -p /tftpboot
sudo mkdir -p /tftpboot/pxelinux.cfg
sudo mkdir -p /tftpboot/nbi_img

# 権限設定
sudo chown -R tftp:tftp /tftpboot
sudo chmod -R 755 /tftpboot
```

### 4. PXELinuxファイルのコピー

```bash
# PXELINUX関連ファイルのコピー
sudo cp /usr/lib/PXELINUX/pxelinux.0 /tftpboot/
sudo cp /usr/lib/syslinux/modules/bios/*.c32 /tftpboot/

# UEFIブート用ファイル（オプション）
sudo cp /usr/lib/SYSLINUX.EFI/efi64/syslinux.efi /tftpboot/bootx64.efi

# 権限設定
sudo chmod 644 /tftpboot/pxelinux.0
sudo chmod 644 /tftpboot/*.c32
```

### 5. TFTPサーバーの起動

```bash
# TFTPサーバーの起動
sudo systemctl restart tftpd-hpa

# 自動起動を有効化
sudo systemctl enable tftpd-hpa

# 状態確認
sudo systemctl status tftpd-hpa

# ポート確認
sudo netstat -ulnp | grep :69
```

### 6. TFTP動作確認

```bash
# ローカルからTFTPテスト
cd /tmp
tftp localhost
tftp> get pxelinux.0
tftp> quit
ls -l pxelinux.0

# ファイルが取得できればOK
```

---

## PXEブートメニュー設定

### 1. デフォルトメニューの作成

```bash
# PXEメニュー設定ファイル作成
sudo vim /tftpboot/pxelinux.cfg/default
```

**設定内容（基本版）**:
```
# /tftpboot/pxelinux.cfg/default
# PXEブートメニュー設定

DEFAULT menu.c32
TIMEOUT 100
PROMPT 0

MENU TITLE PC Auto Setup - PXE Boot Menu
MENU BACKGROUND splash.png

# Clonezilla マルチキャスト復元
LABEL clonezilla-multicast
    MENU LABEL ^1) Clonezilla Live (Multicast Restore)
    MENU DEFAULT
    KERNEL /nbi_img/vmlinuz
    APPEND initrd=/nbi_img/initrd.img boot=live union=overlay username=user config components noswap edd=on nomodeset nodmraid locales=ja_JP.UTF-8 keyboard-layouts=jp ocs_live_run="ocs-sr" ocs_live_extra_param="" ocs_live_batch="yes" net.ifnames=0 nosplash nfsroot=192.168.1.100:/home/partimag

# Clonezilla ユニキャスト復元
LABEL clonezilla-unicast
    MENU LABEL ^2) Clonezilla Live (Unicast Restore)
    KERNEL /nbi_img/vmlinuz
    APPEND initrd=/nbi_img/initrd.img boot=live union=overlay username=user config components noswap edd=on nomodeset ocs_live_run="ocs-sr" ocs_live_batch="no" net.ifnames=0 nfsroot=192.168.1.100:/home/partimag

# Clonezilla バックアップモード
LABEL clonezilla-save
    MENU LABEL ^3) Clonezilla Live (Save Disk Image)
    KERNEL /nbi_img/vmlinuz
    APPEND initrd=/nbi_img/initrd.img boot=live union=overlay username=user config components noswap edd=on nomodeset ocs_live_run="ocs-sr" ocs_live_batch="no" net.ifnames=0 nfsroot=192.168.1.100:/home/partimag

# メモリテスト
LABEL memtest
    MENU LABEL ^4) Memtest86+
    KERNEL /memtest86+.bin

# ローカルディスクから起動
LABEL local
    MENU LABEL ^5) Boot from Local Disk
    LOCALBOOT 0

# シャットダウン
LABEL poweroff
    MENU LABEL ^6) Power Off
    COM32 poweroff.c32

# 再起動
LABEL reboot
    MENU LABEL ^7) Reboot
    COM32 reboot.c32
```

**設定内容（詳細版）**:
```
# 高度なメニュー設定

DEFAULT menu.c32
TIMEOUT 100
PROMPT 0
ONTIMEOUT clonezilla-multicast

MENU TITLE ========================================
MENU TITLE  PC Auto Setup System
MENU TITLE  Powered by DRBL/Clonezilla
MENU TITLE ========================================

# メニューの色設定
MENU COLOR border       30;44   #40ffffff #a0000000 std
MENU COLOR title        1;36;44 #9033ccff #a0000000 std
MENU COLOR sel          7;37;40 #e0ffffff #20ffffff all
MENU COLOR unsel        37;44   #50ffffff #a0000000 std
MENU COLOR help         37;40   #c0ffffff #a0000000 std
MENU COLOR timeout_msg  37;40   #80ffffff #00000000 std
MENU COLOR timeout      1;37;40 #c0ffffff #00000000 std
MENU COLOR msg07        37;40   #90ffffff #a0000000 std
MENU COLOR tabmsg       31;40   #30ffffff #00000000 std

LABEL clonezilla-multicast
    MENU LABEL Clonezilla Multicast Restore (Default)
    MENU DEFAULT
    KERNEL /nbi_img/vmlinuz
    APPEND initrd=/nbi_img/initrd.img boot=live union=overlay username=user config components quiet noswap edd=on nomodeset locales=ja_JP.UTF-8 keyboard-layouts=jp ocs_live_run="ocs-sr" ocs_live_extra_param="--clients-to-wait 20 --max-time-to-wait 300" ocs_live_batch="yes" net.ifnames=0 nosplash ip=frommedia nfsroot=192.168.1.100:/home/partimag
    TEXT HELP
    Windows 11マスターイメージをマルチキャスト展開します。
    最大20台まで同時展開可能です。
    ENDTEXT

LABEL local
    MENU LABEL Boot from Local Disk
    LOCALBOOT 0
    TEXT HELP
    ローカルディスクから起動します。
    既にOSがインストールされている場合に使用してください。
    ENDTEXT
```

### 2. 起動イメージの配置

```bash
# Clonezilla Liveイメージのダウンロードとマウント
cd /tmp
wget https://sourceforge.net/projects/clonezilla/files/clonezilla_live_stable/clonezilla-live-latest-amd64.iso

# ISOをマウント
sudo mkdir -p /mnt/clonezilla
sudo mount -o loop clonezilla-live-latest-amd64.iso /mnt/clonezilla

# 必要なファイルをコピー
sudo cp /mnt/clonezilla/live/vmlinuz /tftpboot/nbi_img/
sudo cp /mnt/clonezilla/live/initrd.img /tftpboot/nbi_img/
sudo cp /mnt/clonezilla/live/filesystem.squashfs /tftpboot/nbi_img/

# アンマウント
sudo umount /mnt/clonezilla

# 権限設定
sudo chmod 644 /tftpboot/nbi_img/*
```

### 3. メモリテストの追加（オプション）

```bash
# Memtest86+のインストール
sudo apt install -y memtest86+

# TFTPディレクトリにコピー
sudo cp /boot/memtest86+.bin /tftpboot/

# 権限設定
sudo chmod 644 /tftpboot/memtest86+.bin
```

---

## NFSエクスポート設定

### 1. NFSサーバーのインストール

```bash
# NFSサーバーのインストール
sudo apt install -y nfs-kernel-server
```

### 2. NFSエクスポート設定

```bash
# /etc/exportsの編集
sudo vim /etc/exports
```

**設定内容**:
```bash
# /etc/exports
# NFSエクスポート設定

# マスターイメージディレクトリ
/home/partimag 192.168.1.0/24(ro,async,no_root_squash,no_subtree_check)

# TFTPブートディレクトリ（オプション）
/tftpboot/nbi_img 192.168.1.0/24(ro,async,no_root_squash,no_subtree_check)

# オプション説明:
# ro: 読み取り専用
# rw: 読み書き可能（イメージ保存時に必要）
# async: 非同期書き込み（高速）
# no_root_squash: rootユーザーの権限を保持
# no_subtree_check: サブツリーチェックを無効化（高速化）
```

### 3. NFSエクスポートの適用

```bash
# エクスポート設定の再読み込み
sudo exportfs -ra

# エクスポート状況の確認
sudo exportfs -v

# 出力例:
# /home/partimag 192.168.1.0/24(ro,async,wdelay,no_root_squash,no_subtree_check)
```

### 4. NFSサーバーの起動

```bash
# NFSサーバーの起動
sudo systemctl restart nfs-kernel-server

# 自動起動を有効化
sudo systemctl enable nfs-kernel-server

# 状態確認
sudo systemctl status nfs-kernel-server

# NFSポート確認
sudo rpcinfo -p | grep nfs
```

### 5. NFS動作確認

```bash
# ローカルからマウントテスト
sudo mkdir -p /mnt/test
sudo mount -t nfs 192.168.1.100:/home/partimag /mnt/test

# マウント確認
df -h | grep partimag

# アンマウント
sudo umount /mnt/test
```

---

## ファイアウォール設定

### 1. UFW（Uncomplicated Firewall）設定

```bash
# UFWの状態確認
sudo ufw status

# UFWが無効の場合は有効化
sudo ufw enable
```

### 2. 必要なポートの開放

```bash
# DHCP (67/udp, 68/udp)
sudo ufw allow 67/udp comment 'DHCP Server'
sudo ufw allow 68/udp comment 'DHCP Client'

# TFTP (69/udp)
sudo ufw allow 69/udp comment 'TFTP Server'

# NFS (2049/tcp, 111/tcp, 111/udp)
sudo ufw allow 2049/tcp comment 'NFS Server'
sudo ufw allow 111/tcp comment 'RPC Portmapper TCP'
sudo ufw allow 111/udp comment 'RPC Portmapper UDP'

# Flask管理アプリ (5000/tcp) - オプション
sudo ufw allow 5000/tcp comment 'Flask API'

# SSH (22/tcp) - 管理用
sudo ufw allow 22/tcp comment 'SSH'

# ファイアウォール設定の確認
sudo ufw status verbose
```

### 3. サブネット単位での制限（推奨）

```bash
# 特定サブネットからのみアクセス許可
sudo ufw delete allow 67/udp
sudo ufw delete allow 69/udp

sudo ufw allow from 192.168.1.0/24 to any port 67 proto udp
sudo ufw allow from 192.168.1.0/24 to any port 69 proto udp
sudo ufw allow from 192.168.1.0/24 to any port 2049 proto tcp
```

### 4. iptables設定（詳細制御が必要な場合）

```bash
# PXEブート用iptables設定
sudo iptables -A INPUT -p udp --dport 67 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 69 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 2049 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 111 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 111 -j ACCEPT

# 設定の保存
sudo iptables-save | sudo tee /etc/iptables/rules.v4

# 永続化（iptables-persistent使用）
sudo apt install -y iptables-persistent
sudo netfilter-persistent save
```

---

## 動作確認

### 1. サーバー側の確認

```bash
# 全サービスの起動確認
sudo systemctl status isc-dhcp-server
sudo systemctl status tftpd-hpa
sudo systemctl status nfs-kernel-server

# ポートリスニング確認
sudo netstat -tuln | grep -E ':67|:69|:2049|:111'

# ファイル配置確認
ls -lR /tftpboot/
ls -l /home/partimag/
```

### 2. ログ監視

```bash
# リアルタイムログ監視
sudo tail -f /var/log/syslog | grep -E 'dhcp|tftp|nfs'

# または個別監視
sudo journalctl -u isc-dhcp-server -f
sudo journalctl -u tftpd-hpa -f
sudo journalctl -u nfs-kernel-server -f
```

### 3. クライアントPCでの確認

**手順**:
1. クライアントPCのBIOS設定
   - Boot Orderで「Network Boot」を最優先に設定
   - または起動時にF12などでブートメニューから「PXE Boot」を選択

2. 期待される動作
   ```
   PXE-M0F: Exiting Intel PXE ROM.
   CLIENT MAC ADDR: 00 11 22 33 44 55
   CLIENT IP: 192.168.1.150
   MASK: 255.255.255.0
   DHCP IP: 192.168.1.100
   GATEWAY IP: 192.168.1.1

   Loading pxelinux.0...

   [PXEブートメニューが表示される]
   ```

3. メニュー選択後、Clonezillaが起動することを確認

### 4. 統合テストスクリプト

```bash
#!/bin/bash
# PXE環境確認スクリプト

echo "=== PXE Boot Environment Check ==="

# サービス確認
echo "1. Checking services..."
systemctl is-active isc-dhcp-server && echo "  DHCP: OK" || echo "  DHCP: NG"
systemctl is-active tftpd-hpa && echo "  TFTP: OK" || echo "  TFTP: NG"
systemctl is-active nfs-kernel-server && echo "  NFS: OK" || echo "  NFS: NG"

# ポート確認
echo "2. Checking ports..."
netstat -tuln | grep -q ':67 ' && echo "  Port 67 (DHCP): OK" || echo "  Port 67: NG"
netstat -tuln | grep -q ':69 ' && echo "  Port 69 (TFTP): OK" || echo "  Port 69: NG"
netstat -tuln | grep -q ':2049 ' && echo "  Port 2049 (NFS): OK" || echo "  Port 2049: NG"

# ファイル確認
echo "3. Checking files..."
[ -f /tftpboot/pxelinux.0 ] && echo "  pxelinux.0: OK" || echo "  pxelinux.0: NG"
[ -f /tftpboot/pxelinux.cfg/default ] && echo "  PXE config: OK" || echo "  PXE config: NG"
[ -f /tftpboot/nbi_img/vmlinuz ] && echo "  kernel: OK" || echo "  kernel: NG"

# NFSエクスポート確認
echo "4. Checking NFS exports..."
exportfs | grep -q '/home/partimag' && echo "  NFS export: OK" || echo "  NFS export: NG"

echo "=== Check complete ==="
```

---

## トラブルシューティング

### 問題1: PXE-E51 No DHCP offers

**原因**:
- DHCPサーバーが起動していない
- ネットワークが正しく接続されていない
- ファイアウォールがブロックしている

**解決策**:
```bash
# DHCPサーバー再起動
sudo systemctl restart isc-dhcp-server

# ログ確認
sudo journalctl -u isc-dhcp-server -n 50

# ファイアウォール確認
sudo ufw status
sudo ufw allow 67/udp
```

### 問題2: TFTP timeout

**原因**:
- TFTPサーバーが起動していない
- ファイルが存在しない
- パーミッションエラー

**解決策**:
```bash
# TFTPサーバー再起動
sudo systemctl restart tftpd-hpa

# ファイル確認
ls -l /tftpboot/pxelinux.0

# パーミッション修正
sudo chmod 644 /tftpboot/pxelinux.0
sudo chmod 755 /tftpboot

# TFTPテスト
tftp localhost
tftp> get pxelinux.0
```

### 問題3: NFS mount failed

**原因**:
- NFSエクスポートが正しくない
- ファイアウォールがブロックしている

**解決策**:
```bash
# NFSエクスポート再読み込み
sudo exportfs -ra
sudo exportfs -v

# NFSサーバー再起動
sudo systemctl restart nfs-kernel-server

# ファイアウォール確認
sudo ufw allow 2049/tcp
```

### 問題4: Boot menu not displayed

**原因**:
- pxelinux.cfg/default が存在しない
- 設定ファイルに文法エラーがある

**解決策**:
```bash
# 設定ファイル確認
cat /tftpboot/pxelinux.cfg/default

# パス確認
ls -l /tftpboot/pxelinux.cfg/

# サンプル設定でテスト
sudo tee /tftpboot/pxelinux.cfg/default << EOF
DEFAULT local
LABEL local
  LOCALBOOT 0
EOF
```

---

## 参考資料

- [PXE Specification](https://www.intel.com/content/www/us/en/architecture-and-technology/preboot-execution-environment.html)
- [SYSLINUX Project](https://wiki.syslinux.org/)
- [ISC DHCP Server Documentation](https://www.isc.org/dhcp/)
- [NFS Server Configuration](https://ubuntu.com/server/docs/service-nfs)
