# DRBL/Clonezillaサーバ詳細導入手順書（Ubuntu版）

## 目次
- [概要](#概要)
- [ハードウェア要件](#ハードウェア要件)
- [Ubuntu 22.04 LTSインストール](#ubuntu-2204-ltsインストール)
- [ネットワーク設定](#ネットワーク設定)
- [DRBLリポジトリ追加](#drblリポジトリ追加)
- [DRBLパッケージインストール](#drblパッケージインストール)
- [drblsrv初期設定](#drblsrv初期設定)
- [drblpushクライアント設定](#drblpushクライアント設定)
- [マスターイメージ格納先準備](#マスターイメージ格納先準備)
- [ODJファイル格納先準備](#odjファイル格納先準備)
- [systemd自動起動設定](#systemd自動起動設定)
- [ファイアウォール設定](#ファイアウォール設定)
- [動作確認手順](#動作確認手順)
- [パフォーマンスチューニング](#パフォーマンスチューニング)
- [バックアップ設定](#バックアップ設定)
- [トラブルシューティング](#トラブルシューティング)

---

## 概要

### DRBLとは

DRBL（Diskless Remote Boot in Linux）は、Linuxベースのネットワークブート環境を構築するオープンソースソフトウェアです。Clonezillaと統合され、PXEブート経由で複数台PCに同時にOSイメージを展開できます。

### システム構成

```
[DRBLサーバ（Ubuntu 22.04 LTS）]
    │
    ├─ DHCP サーバ（ISC DHCP Server）
    ├─ TFTP サーバ（TFTP-HPA）
    ├─ NFS サーバ（NFS Kernel Server）
    ├─ Clonezilla イメージ管理
    └─ Flask管理Webアプリケーション
    │
    └─ LAN（Gigabit Ethernet）
         │
         ├─ クライアントPC 1
         ├─ クライアントPC 2
         ├─ ...
         └─ クライアントPC 20
```

### 所要時間

- **初回構築**: 2-3時間
- **更新・再設定**: 30-60分

---

## ハードウェア要件

### 最低要件

- **CPU**: 2コア以上
- **メモリ**: 4GB以上
- **ストレージ**: 128GB以上（SSD推奨）
- **ネットワーク**: Gigabit Ethernet x1

### 推奨要件（10-20台同時展開）

- **CPU**: 4コア以上（Intel Core i5 / AMD Ryzen 5以上）
- **メモリ**: 16GB以上
- **ストレージ**: 500GB以上（SSD推奨）
  - OS: 50GB
  - /home/partimag: 400GB以上（マスターイメージ保存用）
  - /backup: 50GB（バックアップ用）
- **ネットワーク**: Gigabit Ethernet x1（または10GbE）

### パーティション構成（推奨）

| マウントポイント | サイズ | ファイルシステム | 用途 |
|---------------|--------|--------------|------|
| / | 50GB | ext4 | OSルート |
| /home/partimag | 400GB | ext4 | マスターイメージ保存 |
| /backup | 50GB | ext4 | バックアップ |
| swap | 16GB | swap | スワップ領域 |

---

## Ubuntu 22.04 LTSインストール

### インストールメディア作成

#### Ubuntu 22.04 LTS ISOダウンロード

```bash
# 公式サイト
https://ubuntu.com/download/server

# ファイル名例
ubuntu-22.04.3-live-server-amd64.iso
```

#### Rufus使用（Windows環境）

```
1. Rufus起動
2. Device: USBメモリ選択（8GB以上）
3. Boot selection: ubuntu-22.04.3-live-server-amd64.iso
4. Partition scheme: MBR（BIOS/UEFI両対応）
5. File system: FAT32
6. START ボタンクリック
```

### Ubuntuインストール手順

#### 起動とインストーラ起動

1. Ubuntu インストールUSBをサーバに挿入
2. BIOSでUSBブート選択
3. "Try or Install Ubuntu Server" を選択

#### 言語選択

```
Language: English（推奨）
※日本語選択も可能だが、トラブルシューティング時に英語環境の方が情報が多い
```

#### キーボード選択

```
Keyboard configuration
Layout: Japanese
Variant: Japanese
```

#### ネットワーク接続

```
Network connections
eth0: DHCPv4（一時的、後で固定IPに変更）
```

#### Proxy設定

```
Proxy address: （空欄）
※プロキシ環境の場合、設定
```

#### Ubuntuアーカイブミラー

```
Mirror address: http://jp.archive.ubuntu.com/ubuntu（デフォルト）
```

#### ストレージ設定

##### 推奨: カスタムレイアウト

```
Storage configuration
→ "Custom storage layout" を選択

# パーティション作成
1. "/" - 50GB - ext4
2. "/home/partimag" - 400GB - ext4
3. "/backup" - 50GB - ext4
4. "swap" - 16GB - swap
```

##### または: ディスク全体使用（簡易）

```
Storage configuration
→ "Use an entire disk" を選択
→ ディスク選択
→ "Set up this disk as an LVM group" はオフ推奨
```

#### プロファイル設定

```
Your name: DRBL Admin
Your server's name: drbl-server
Pick a username: drbl
Choose a password: ********（強力なパスワード）
```

#### SSH設定

```
SSH Setup
→ "Install OpenSSH server" にチェック ON
→ "Import SSH identity" はスキップ
```

#### Featured Server Snaps

```
スキップ（何も選択しない）
```

#### インストール開始

1. "Done" を選択
2. インストール開始（10-20分）
3. 完了後、"Reboot Now" を選択
4. USBメディア取り外し

---

## ネットワーク設定

### 現在のネットワーク設定確認

```bash
# IPアドレス確認
ip addr show

# ネットワーク設定ファイル確認
ls /etc/netplan/
# 00-installer-config.yaml 等
```

### 固定IPアドレス設定（Netplan）

#### 設定ファイル編集

```bash
# 設定ファイル編集
sudo nano /etc/netplan/00-installer-config.yaml
```

#### 設定例

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:  # ネットワークインターフェース名（環境により異なる）
      dhcp4: no
      dhcp6: no
      addresses:
        - 192.168.1.10/24  # DRBLサーバ固定IPアドレス
      routes:
        - to: default
          via: 192.168.1.1  # デフォルトゲートウェイ
      nameservers:
        addresses:
          - 192.168.1.1  # DNSサーバ（ルーター等）
          - 8.8.8.8      # Googleパブリック DNS（フォールバック）
```

#### ネットワークインターフェース名確認

```bash
# インターフェース名確認
ip link show
# 例: ens33, eth0, enp0s3 等
```

#### 設定適用

```bash
# 設定テスト（構文エラー確認）
sudo netplan try

# 問題なければ、適用
sudo netplan apply

# IPアドレス確認
ip addr show ens33

# 接続確認
ping -c 4 192.168.1.1
ping -c 4 8.8.8.8
```

### ホスト名設定

```bash
# ホスト名確認
hostnamectl

# ホスト名変更（必要に応じて）
sudo hostnamectl set-hostname drbl-server

# /etc/hosts 編集
sudo nano /etc/hosts
```

```
127.0.0.1 localhost
192.168.1.10 drbl-server drbl-server.company.local

# IPv6
::1 ip6-localhost ip6-loopback
```

---

## DRBLリポジトリ追加

### GPGキー追加

```bash
# DRBLリポジトリGPGキーダウンロード
wget -q https://drbl.org/GPG-KEY-DRBL -O- | sudo apt-key add -

# または新しい方法（Ubuntu 22.04以降推奨）
wget -q https://drbl.org/GPG-KEY-DRBL -O /tmp/drbl-key.gpg
sudo gpg --dearmor -o /usr/share/keyrings/drbl-archive-keyring.gpg /tmp/drbl-key.gpg
```

### リポジトリ追加

```bash
# sources.list.d にDRBLリポジトリ追加
echo "deb [signed-by=/usr/share/keyrings/drbl-archive-keyring.gpg] http://free.nchc.org.tw/drbl-core drbl stable" | sudo tee /etc/apt/sources.list.d/drbl.list

# パッケージリスト更新
sudo apt update
```

---

## DRBLパッケージインストール

### 必須パッケージインストール

```bash
# DRBLパッケージインストール
sudo apt install -y drbl

# Clonezillaパッケージインストール
sudo apt install -y clonezilla

# 関連パッケージ確認
dpkg -l | grep drbl
dpkg -l | grep clonezilla
```

### 依存パッケージ自動インストール

DRBLインストール時、以下のパッケージが自動的にインストールされます：

- **isc-dhcp-server**: DHCPサーバ
- **tftpd-hpa**: TFTPサーバ
- **nfs-kernel-server**: NFSサーバ
- **udpcast**: マルチキャスト転送ツール
- **partclone**: パーティションクローンツール
- **pigz**: 並列gzip圧縮
- **pixz**: 並列xz圧縮

### インストール確認

```bash
# DRBLバージョン確認
drbl-ocs --version

# Clonezillaバージョン確認
clonezilla --version

# インストール済みパッケージ確認
dpkg -l | grep -E "drbl|clonezilla|dhcp|tftp|nfs"
```

---

## drblsrv初期設定

### drblsrv -i 実行

`drblsrv -i` は、DRBLサーバの初期設定を対話式ウィザードで実行します。

```bash
# 管理者権限で実行
sudo drblsrv -i
```

### 対話式ウィザード（質問と推奨回答）

#### Q1: ホスト名とドメイン名

```
Hostname [drbl-server]: （Enterでデフォルト）
Domain name []: company.local
```

#### Q2: ネットワークインターフェース選択

```
Please choose the ethernet interface for DRBL:
1. ens33 (192.168.1.10)
2. Exit

→ "1" を入力（DRBLサーバのネットワークインターフェース）
```

#### Q3: IPアドレス範囲（DHCPスコープ）

```
The initial IP address for DRBL clients [192.168.1.101]: （Enterでデフォルト）
The final IP address for DRBL clients [192.168.1.200]: （Enterまたは 192.168.1.250）
```

**推奨**: 192.168.1.101 - 192.168.1.250（最大150台）

#### Q4: サブネットマスク

```
Netmask [255.255.255.0]: （Enterでデフォルト）
```

#### Q5: DHCPサービス

```
Do you want to use the existing DHCP service in your network? [y/N]: N
```

- **N**: DRBLサーバでDHCPサーバを起動（推奨）
- **Y**: 既存DHCPサーバ使用（proxyDHCPモード）

#### Q6: DNSサーバ

```
DNS server for DRBL clients [192.168.1.1]: （Enterでデフォルト、またはカスタムDNS）
```

#### Q7: NFSサービス

```
Do you want to set the /etc/exports for NFS service? [y/N]: y
```

#### Q8: /tftpboot ディレクトリ

```
The directory /tftpboot exists, do you want to use it? [y/N]: y
```

#### Q9: PXEブートファイル

```
Do you want to download PXE boot files from internet? [y/N]: y
```

- **y**: インターネットから最新版ダウンロード（推奨）
- **N**: ローカルファイル使用

#### Q10: Clonezillaダウンロード

```
Do you want to download Clonezilla live from internet? [y/N]: y

# バージョン選択
1. stable (推奨)
2. testing
3. alternative stable

→ "1" を入力
```

#### Q11: セキュリティアップデート

```
Do you want to run apt-get update and upgrade? [y/N]: y
```

**推奨**: y（セキュリティアップデート実行）

#### Q12: 設定確認

```
The configuration is:
  Hostname: drbl-server
  Domain: company.local
  Network: 192.168.1.0/24
  DHCP range: 192.168.1.101 - 192.168.1.250
  ...

Is this OK? [y/N]: y
```

#### Q13: 設定適用開始

```
Press Enter to continue...
→ Enterキー
```

### drblsrv -i 実行中

- パッケージインストール
- ネットワーク設定
- DHCPサーバ設定
- TFTPサーバ設定
- NFSサーバ設定
- PXEブートファイルダウンロード
- Clonezillaダウンロード

**所要時間**: 10-20分（インターネット速度による）

### drblsrv -i 完了

```
DRBL server is ready!
Now run "drblpush -i" to setup the DRBL SSI/Clonezilla mode.
```

---

## drblpushクライアント設定

### drblpush -i 実行

`drblpush -i` は、クライアントPC設定を対話式ウィザードで実行します。

```bash
sudo drblpush -i
```

### 対話式ウィザード（質問と推奨回答）

#### Q1: モード選択

```
Which mode do you want to use?
1. Full DRBL mode (Full clonezilla and DRBL functionality)
2. DRBL SSI mode (Only clonezilla, diskless clients)
3. Do not provide any DRBL or Clonezilla service

→ "1" を入力（Full DRBL mode、推奨）
```

#### Q2: PXEブートメニュー言語

```
Which language do you want to use for the PXE menu?
1. en_US (English)
2. ja_JP (Japanese)
3. ...

→ "2" を入力（日本語メニュー）
```

#### Q3: クライアント台数

```
How many DRBL clients do you want to provide services for?
→ "50" を入力（推奨: 20-50台）
```

**注意**: 実際に同時展開する台数（10-20台）より多めに設定

#### Q4: グラフィカルPXEメニュー

```
Do you want to use graphical PXE menu? [y/N]: y
```

#### Q5: マルチキャスト使用

```
Do you want to use multicast to save the image? [y/N]: y
```

**推奨**: y（同時展開時にマルチキャスト使用）

#### Q6: マルチキャストアドレス

```
Multicast address [224.0.0.1]: （Enterでデフォルト）
```

#### Q7: マルチキャストポート

```
Multicast port [2232]: （Enterでデフォルト）
```

#### Q8: BT（BitTorrent）使用

```
Do you want to use BitTorrent to save/restore the image? [y/N]: N
```

**推奨**: N（LAN環境ではマルチキャストで十分）

#### Q9: クライアントPC起動メニュー

```
What do you want to put in the PXE menu for DRBL clients?
1. Clonezilla (Clone/restore disk or partition)
2. Clonezilla lite server
3. Only local boot

→ "1" を入力（Clonezilla、推奨）
```

#### Q10: クライアント自動起動

```
Do you want to set clonezilla as default boot option? [y/N]: N
```

**推奨**: N（手動でClonezilla選択）

#### Q11: タイムアウト

```
Timeout for PXE menu (in seconds) [70]: （Enterでデフォルト、または変更）
```

#### Q12: 設定確認

```
The configuration is:
  Mode: Full DRBL
  Language: ja_JP
  Clients: 50
  Multicast: Yes
  ...

Is this OK? [y/N]: y
```

#### Q13: 設定適用開始

```
Press Enter to continue...
→ Enterキー
```

### drblpush -i 実行中

- クライアント設定ファイル生成
- PXEブートメニュー作成
- DHCP設定更新
- NFS共有設定
- サービス再起動

**所要時間**: 5-10分

### drblpush -i 完了

```
DRBL push is done!
Now you can boot the DRBL clients via PXE.
```

---

## マスターイメージ格納先準備

### /home/partimag ディレクトリ作成

```bash
# ディレクトリ作成
sudo mkdir -p /home/partimag

# 権限設定
sudo chmod 755 /home/partimag
sudo chown root:root /home/partimag
```

### 専用パーティション使用（推奨）

#### パーティション確認

```bash
# ディスク確認
sudo fdisk -l

# マウント確認
df -h
```

#### パーティション作成（未作成の場合）

```bash
# fdisk でパーティション作成
sudo fdisk /dev/sda

# コマンド例
n   # 新規パーティション
p   # プライマリ
3   # パーティション番号
（デフォルト開始セクタ）
+400G  # サイズ 400GB
w   # 書き込み

# ファイルシステム作成
sudo mkfs.ext4 /dev/sda3

# UUID確認
sudo blkid /dev/sda3
# UUID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

#### /etc/fstab 編集（自動マウント）

```bash
sudo nano /etc/fstab
```

```
# /home/partimag
UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx /home/partimag ext4 defaults 0 2
```

#### マウント

```bash
# マウント
sudo mount -a

# 確認
df -h /home/partimag
```

### NFS共有設定

```bash
# /etc/exports 編集
sudo nano /etc/exports
```

```
# /home/partimag を NFSエクスポート
/home/partimag 192.168.1.0/24(rw,no_root_squash,async,no_subtree_check)
```

#### NFS再エクスポート

```bash
# NFSエクスポート更新
sudo exportfs -ra

# エクスポート確認
sudo exportfs -v
# /home/partimag  192.168.1.0/24(rw,wdelay,no_root_squash,no_subtree_check,sec=sys,rw,secure,no_root_squash,no_all_squash)
```

---

## ODJファイル格納先準備

### /srv/odj ディレクトリ作成

```bash
# ディレクトリ作成
sudo mkdir -p /srv/odj

# 権限設定（セキュリティ強化）
sudo chmod 700 /srv/odj
sudo chown drbl:drbl /srv/odj
```

### Webサーバ設定（Nginx）

ODJファイルをHTTP経由でダウンロードできるよう、Nginxを設定します。

#### Nginxインストール

```bash
sudo apt install -y nginx
```

#### Nginx設定

```bash
# 設定ファイル編集
sudo nano /etc/nginx/sites-available/default
```

```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name drbl-server;

    # ODJファイル公開
    location /odj/ {
        alias /srv/odj/;
        autoindex on;  # ディレクトリリスト表示（オプション）

        # セキュリティ: 社内LANのみアクセス許可
        allow 192.168.1.0/24;
        deny all;
    }

    # Flask API リバースプロキシ（オプション）
    location /api/ {
        proxy_pass http://127.0.0.1:5000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

#### Nginx再起動

```bash
# 設定テスト
sudo nginx -t

# Nginx再起動
sudo systemctl restart nginx

# 自動起動設定
sudo systemctl enable nginx
```

#### アクセステスト

```bash
# テストファイル作成
echo "ODJ Test File" | sudo tee /srv/odj/test.txt

# ブラウザでアクセス
# http://192.168.1.10/odj/test.txt
```

---

## systemd自動起動設定

### サービス確認

```bash
# DHCP サーバ
sudo systemctl status isc-dhcp-server

# TFTP サーバ
sudo systemctl status tftpd-hpa

# NFS サーバ
sudo systemctl status nfs-kernel-server

# DRBL サービス
sudo systemctl status drbl
```

### 自動起動有効化

```bash
# DHCP
sudo systemctl enable isc-dhcp-server
sudo systemctl start isc-dhcp-server

# TFTP
sudo systemctl enable tftpd-hpa
sudo systemctl start tftpd-hpa

# NFS
sudo systemctl enable nfs-kernel-server
sudo systemctl start nfs-kernel-server

# Nginx
sudo systemctl enable nginx
sudo systemctl start nginx
```

### サービス依存関係確認

```bash
# サービス依存関係確認
systemctl list-dependencies isc-dhcp-server
```

---

## ファイアウォール設定

### UFW（Uncomplicated Firewall）インストール

```bash
# UFWインストール
sudo apt install -y ufw
```

### 必要ポート開放

```bash
# SSHポート開放（リモート管理用）
sudo ufw allow 22/tcp

# DHCP
sudo ufw allow 67/udp
sudo ufw allow 68/udp

# TFTP
sudo ufw allow 69/udp

# NFS
sudo ufw allow 111/tcp
sudo ufw allow 111/udp
sudo ufw allow 2049/tcp
sudo ufw allow 2049/udp

# HTTP（ODJファイルダウンロード、Flask API）
sudo ufw allow 80/tcp

# Flask API（直接アクセスする場合）
sudo ufw allow 5000/tcp

# udpcast（マルチキャスト）
sudo ufw allow 2232/udp

# UFW有効化
sudo ufw enable

# ファイアウォール状態確認
sudo ufw status verbose
```

### ファイアウォールルール確認

```bash
# ルール一覧
sudo ufw status numbered

# 出力例
Status: active

     To                         Action      From
     --                         ------      ----
[ 1] 22/tcp                     ALLOW IN    Anywhere
[ 2] 67/udp                     ALLOW IN    Anywhere
[ 3] 68/udp                     ALLOW IN    Anywhere
[ 4] 69/udp                     ALLOW IN    Anywhere
[ 5] 111                        ALLOW IN    Anywhere
[ 6] 2049                       ALLOW IN    Anywhere
[ 7] 80/tcp                     ALLOW IN    Anywhere
[ 8] 5000/tcp                   ALLOW IN    Anywhere
[ 9] 2232/udp                   ALLOW IN    Anywhere
```

---

## 動作確認手順

### DHCPリース確認

```bash
# DHCPリースファイル確認
sudo cat /var/lib/dhcp/dhcpd.leases

# リアルタイムログ確認
sudo tail -f /var/log/syslog | grep dhcp
```

### TFTPファイル配信確認

```bash
# TFTP接続テスト（別PCから、またはlocalhost）
sudo apt install tftp-hpa
tftp 192.168.1.10
tftp> get pxelinux.0
tftp> quit

# ファイル取得確認
ls -l pxelinux.0
```

### NFS共有確認

```bash
# NFSエクスポート確認
sudo exportfs -v

# NFSマウントテスト（別PCから）
sudo apt install nfs-common
sudo mount -t nfs 192.168.1.10:/home/partimag /mnt
ls /mnt
sudo umount /mnt
```

### テストPCでPXEブート確認

#### 準備

1. テストPCをDRBLサーバと同一ネットワークに接続
2. テストPCのBIOS設定でネットワークブート有効化

#### PXEブート

1. テストPC電源投入
2. PXEブート選択（F12等）
3. DHCP IPアドレス取得確認
4. TFTPブート開始確認
5. Clonezillaメニュー表示確認

#### 期待される動作

```
PXE-E51: No DHCP offers received → 失敗（DHCPサーバ未起動）
PXE-E32: TFTP open timeout → 失敗（TFTPサーバ未起動）

成功例:
CLIENT MAC ADDR: AA:BB:CC:DD:EE:FF
CLIENT IP: 192.168.1.101
GATEWAY IP: 192.168.1.1
MASK: 255.255.255.0

Booting from network...
TFTP from 192.168.1.10
Loading pxelinux.0...

→ Clonezillaメニュー表示
```

---

## パフォーマンスチューニング

### NFS設定最適化

#### /etc/exports 編集

```bash
sudo nano /etc/exports
```

```
# パフォーマンス最適化
/home/partimag 192.168.1.0/24(rw,no_root_squash,async,no_subtree_check,no_wdelay,insecure)
```

**オプション説明**:
- `async`: 非同期書き込み（高速化）
- `no_wdelay`: 書き込み遅延なし
- `insecure`: 1024以上のポート許可

```bash
# NFS再エクスポート
sudo exportfs -ra
```

#### NFS設定ファイル編集

```bash
sudo nano /etc/default/nfs-kernel-server
```

```bash
# スレッド数増加（デフォルト8 → 16）
RPCNFSDCOUNT=16

# TCP使用
RPCMOUNTDOPTS="--manage-gids --no-udp"
```

```bash
# NFS再起動
sudo systemctl restart nfs-kernel-server
```

### マルチキャストバッファサイズ調整

#### udpcast設定

```bash
# /etc/drbl/drblpush.conf 編集
sudo nano /etc/drbl/drblpush.conf
```

```bash
# マルチキャスト最大待機時間（秒）
multicast_max_wait_time="3600"  # 60分

# udpcastバッファサイズ（MB）
udpcast_buf_size="1024"  # 1GB
```

### カーネルパラメータチューニング

#### /etc/sysctl.conf 編集

```bash
sudo nano /etc/sysctl.conf
```

```bash
# ネットワークバッファサイズ増加
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864

# マルチキャスト設定
net.ipv4.igmp_max_memberships=100

# ファイルディスクリプタ増加
fs.file-max=65536
```

```bash
# 設定適用
sudo sysctl -p
```

### ディスクI/O最適化

#### I/Oスケジューラ変更（SSD使用時）

```bash
# 現在のI/Oスケジューラ確認
cat /sys/block/sda/queue/scheduler

# none（SSD推奨）に変更
echo none | sudo tee /sys/block/sda/queue/scheduler

# 恒久的設定（/etc/default/grub）
sudo nano /etc/default/grub
# GRUB_CMDLINE_LINUX_DEFAULT="elevator=none"

sudo update-grub
sudo reboot
```

---

## バックアップ設定

### データベースバックアップ（Flask管理アプリ）

#### バックアップスクリプト作成

```bash
sudo nano /opt/backup-db.sh
```

```bash
#!/bin/bash

# バックアップ設定
BACKUP_DIR="/backup/db"
DB_FILE="/opt/flask-app/pc_setup.db"
DATE=$(date +%Y%m%d_%H%M%S)

# バックアップディレクトリ作成
mkdir -p $BACKUP_DIR

# SQLiteバックアップ
sqlite3 $DB_FILE ".backup '$BACKUP_DIR/pc_setup_$DATE.db'"

# 7日以上前のバックアップ削除
find $BACKUP_DIR -name "pc_setup_*.db" -mtime +7 -delete

echo "Database backup completed: pc_setup_$DATE.db"
```

```bash
# 実行権限付与
sudo chmod +x /opt/backup-db.sh

# 手動実行テスト
sudo /opt/backup-db.sh
```

#### cronジョブ設定

```bash
# cron設定
sudo crontab -e
```

```cron
# データベースバックアップ（毎日午前3時）
0 3 * * * /opt/backup-db.sh >> /var/log/db-backup.log 2>&1
```

### マスターイメージバックアップ

#### バックアップスクリプト作成

```bash
sudo nano /opt/backup-images.sh
```

```bash
#!/bin/bash

# バックアップ設定
SOURCE_DIR="/home/partimag"
BACKUP_DIR="/backup/images"
DATE=$(date +%Y%m%d)

# バックアップディレクトリ作成
mkdir -p $BACKUP_DIR

# rsyncでバックアップ
rsync -avz --delete $SOURCE_DIR/ $BACKUP_DIR/

echo "Image backup completed: $DATE"
```

```bash
# 実行権限付与
sudo chmod +x /opt/backup-images.sh

# 手動実行テスト
sudo /opt/backup-images.sh
```

#### cronジョブ設定

```bash
sudo crontab -e
```

```cron
# マスターイメージバックアップ（毎週日曜日午前2時）
0 2 * * 0 /opt/backup-images.sh >> /var/log/image-backup.log 2>&1
```

---

## トラブルシューティング

### drblsrv -i 失敗時

**症状**: drblsrv -i 実行中にエラー

**原因**: ネットワーク設定不正、パッケージ依存関係エラー

**対処**:

```bash
# ログ確認
sudo cat /var/log/drbl/drblsrv.log

# パッケージ依存関係修復
sudo apt --fix-broken install
sudo apt update
sudo apt upgrade

# drblsrv 再実行
sudo drblsrv -i
```

### DHCP起動失敗時

**症状**: isc-dhcp-server が起動しない

**原因**: 設定ファイルエラー、ポート競合

**対処**:

```bash
# DHCPログ確認
sudo journalctl -u isc-dhcp-server -n 50

# 設定ファイルテスト
sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf

# ポート使用確認
sudo netstat -tunlp | grep 67

# DHCP再起動
sudo systemctl restart isc-dhcp-server
```

### TFTP接続失敗時

**症状**: PXEブート時に "TFTP open timeout"

**原因**: TFTPサービス未起動、ファイアウォールブロック

**対処**:

```bash
# TFTPサービス確認
sudo systemctl status tftpd-hpa

# TFTP設定確認
cat /etc/default/tftpd-hpa
# TFTP_DIRECTORY="/var/lib/tftpboot"

# TFTPファイル確認
ls -l /var/lib/tftpboot/pxelinux.0

# ファイアウォール確認
sudo ufw allow 69/udp

# TFTP再起動
sudo systemctl restart tftpd-hpa
```

### NFS接続失敗時

**症状**: Clonezilla起動時に "NFS mount failed"

**原因**: NFSサービス未起動、エクスポート設定誤り

**対処**:

```bash
# NFSサービス確認
sudo systemctl status nfs-kernel-server

# エクスポート確認
sudo exportfs -v

# /etc/exports 確認
cat /etc/exports

# NFS再エクスポート
sudo exportfs -ra

# NFS再起動
sudo systemctl restart nfs-kernel-server
```

### マルチキャスト展開失敗時

**症状**: 複数台同時展開時、一部のPCだけ失敗

**原因**: ネットワークスイッチのマルチキャスト設定不適

**対処**:

```bash
# マルチキャスト設定確認
cat /etc/drbl/drblpush.conf | grep multicast

# スイッチ設定確認（管理画面）
# IGMP Snooping: Enabled

# マルチキャストタイムアウト延長
sudo nano /etc/drbl/drblpush.conf
# multicast_max_wait_time="3600"

# DRBL再起動
sudo systemctl restart drbl
```

### ディスク容量不足時

**症状**: マスターイメージ保存時に容量不足エラー

**対処**:

```bash
# ディスク使用状況確認
df -h /home/partimag

# 容量の大きいファイル特定
sudo du -sh /home/partimag/* | sort -h

# 古いイメージ削除
sudo rm -rf /home/partimag/old-image-*

# 不要なログ削除
sudo journalctl --vacuum-time=30d
```

---

**ドキュメントバージョン**: 1.0
**最終更新日**: 2025-11-17
**作成者**: IT部門

## 付録

### 参考リンク

- **DRBL公式サイト**: https://drbl.org
- **Clonezilla公式サイト**: https://clonezilla.org
- **Ubuntu公式ドキュメント**: https://ubuntu.com/server/docs

### よくある質問（FAQ）

#### Q: DRBLとClonezillaの違いは？

**A**:
- **DRBL**: ネットワークブート環境を提供するフレームワーク（DHCP, TFTP, NFS）
- **Clonezilla**: ディスククローンツール（DRBLと統合され、ネットワーク経由で展開可能）

#### Q: 最大何台まで同時展開可能？

**A**:
- **理論値**: 100台以上
- **推奨**: 10-20台（ネットワーク帯域、サーバスペックによる）
- **制約**: ネットワークスイッチのマルチキャスト対応、Gigabit Ethernet推奨

#### Q: マスターイメージ圧縮形式の選び方は？

**A**:
- **zstd (-z1p)**: バランス最良（推奨）
- **gzip (-z1)**: 高速展開優先
- **xz (-z5)**: 容量優先（展開が遅い）

#### Q: Sysprep実行回数制限は？

**A**:
- Windows 10/11: 最大8回（実運用では3回以下推奨）
- 制限超過時: 新規Windows再インストール必要

---

**以上で、DRBL/Clonezillaサーバ詳細導入手順書（Ubuntu版）は完了です。**
