# DRBL/Clonezillaサーバ構築手順

## 目次
1. [概要](#概要)
2. [前提条件](#前提条件)
3. [Ubuntu 22.04インストール](#ubuntu-2204インストール)
4. [DRBLインストール](#drblインストール)
5. [Clonezilla設定](#clonezilla設定)
6. [マスターイメージ管理](#マスターイメージ管理)
7. [マルチキャスト設定](#マルチキャスト設定)
8. [自動起動設定](#自動起動設定)
9. [動作確認](#動作確認)
10. [トラブルシューティング](#トラブルシューティング)

---

## 概要

### DRBLとは
**DRBL (Diskless Remote Boot in Linux)** は、ディスクレスシステムとクローニングを提供するLinuxベースのソリューションです。

### Clonezillaとは
**Clonezilla** は、Partition ImageやTrue Imageに似たディスククローニングツールで、DRBLと統合されています。

### システム構成
- **OS**: Ubuntu 22.04 LTS Server
- **DRBL**: 最新版（2.x系）
- **Clonezilla**: 最新版
- **ストレージ**: マスターイメージ保存用に500GB以上推奨

---

## 前提条件

### ハードウェア要件

| コンポーネント | 最小要件 | 推奨要件 |
|---------------|---------|---------|
| CPU | 2コア 2GHz以上 | 4コア 3GHz以上 |
| メモリ | 4GB | 8GB以上 |
| ストレージ | 100GB | 500GB以上（SSD推奨） |
| NIC | 1Gbps x1 | 1Gbps x2（管理用+配信用） |

### ネットワーク要件
- **固定IPアドレス**: 192.168.1.100/24（例）
- **DHCPサーバー機能**: DRBLが提供
- **マルチキャスト対応スイッチ**: 推奨
- **専用VLAN**: 推奨（キッティング専用ネットワーク）

### 必要な情報
```bash
# サーバーIPアドレス設定
SERVER_IP="192.168.1.100"
NETMASK="255.255.255.0"
GATEWAY="192.168.1.1"
DNS_SERVER="8.8.8.8"

# DHCPスコープ設定
DHCP_START="192.168.1.150"
DHCP_END="192.168.1.200"
```

---

## Ubuntu 22.04インストール

### 1. Ubuntu Server 22.04 LTSのダウンロード

```bash
# ISOイメージダウンロード
wget https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso
```

### 2. インストール設定

**インストール時の推奨設定**:
- **パーティション構成**:
  - `/` - 50GB
  - `/home/partimag` - 残り全て（マスターイメージ保存先）
  - スワップ - メモリと同量

- **ネットワーク設定**: 固定IP
- **パッケージ選択**: OpenSSH Server

### 3. 初期設定

```bash
# システムアップデート
sudo apt update
sudo apt upgrade -y

# 必要なパッケージのインストール
sudo apt install -y \
    net-tools \
    vim \
    curl \
    wget \
    htop \
    nfs-kernel-server \
    isc-dhcp-server \
    tftpd-hpa \
    syslinux \
    pxelinux

# ホスト名設定
sudo hostnamectl set-hostname drbl-server

# /etc/hostsの編集
sudo tee -a /etc/hosts << EOF
192.168.1.100 drbl-server
EOF
```

### 4. ネットワーク設定（Netplan）

```bash
# ネットワーク設定ファイルの編集
sudo vim /etc/netplan/00-installer-config.yaml
```

**設定内容**:
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    # メインネットワークインターフェース
    ens33:
      addresses:
        - 192.168.1.100/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
```

```bash
# 設定適用
sudo netplan apply

# 確認
ip addr show
ping -c 4 8.8.8.8
```

---

## DRBLインストール

### 1. DRBLリポジトリの追加

```bash
# DRBLのGPGキーを追加
wget -q https://drbl.org/GPG-KEY-DRBL -O- | sudo apt-key add -

# DRBLリポジトリを追加
sudo tee /etc/apt/sources.list.d/drbl.list << EOF
deb http://free.nchc.org.tw/drbl-core drbl stable
EOF

# パッケージリストの更新
sudo apt update
```

### 2. DRBLのインストール

```bash
# DRBLパッケージのインストール
sudo apt install -y drbl

# インストール確認
dpkg -l | grep drbl
```

### 3. DRBL初期設定（drblsrv -i）

```bash
# DRBL サーバーの初期設定を実行
sudo /usr/sbin/drblsrv -i
```

**対話的設定の流れ**:

```
1. インストールモードの選択
   → [1] Full DRBL mode を選択

2. ネットワークインターフェースの選択
   → ens33（使用するNIC）を選択

3. DHCPサーバーの設定
   → Do you want to use the existing DHCP service? [y/N]: N
   → 新しいDHCPサーバーを設定

4. DHCPレンジの設定
   → Starting IP address: 192.168.1.150
   → Ending IP address: 192.168.1.200

5. DNS設定
   → DNS server: 8.8.8.8

6. NISドメイン設定（必要に応じて）
   → Use NIS? [y/N]: N

7. クライアントOSの選択
   → [1] Use clients' partitions for them to boot

8. インストール確認
   → Are you sure you want to continue? [y/N]: y
```

**設定ログ**:
```bash
# 設定が完了すると以下に保存される
/var/log/drbl/drblsrv.log
```

### 4. DRBLクライアント設定（drblpush -i）

```bash
# クライアント設定の実行
sudo /usr/sbin/drblpush -i
```

**対話的設定の流れ**:

```
1. モード選択
   → [0] Clonezilla box mode (for cloning, NOT diskless)
   ※ ディスククローニング用モード

2. クライアント数の設定
   → How many clients per group? : 20
   ※ 同時展開台数

3. Clonezilla設定
   → Use multicast mode? [Y/n]: Y
   → Compression method: [2] gzip
   → Image directory: /home/partimag

4. PXEブートメニュー設定
   → Do you want to use graphic background? [Y/n]: n
   → Boot prompt timeout (seconds): 10

5. 確認と適用
   → Are you ready to continue? [y/N]: y
```

**設定完了後の確認**:
```bash
# DHCPサーバーの起動確認
sudo systemctl status isc-dhcp-server

# TFTPサーバーの起動確認
sudo systemctl status tftpd-hpa

# NFSサーバーの起動確認
sudo systemctl status nfs-kernel-server
```

---

## Clonezilla設定

### 1. マスターイメージ保存ディレクトリの設定

```bash
# マスターイメージ保存先の作成
sudo mkdir -p /home/partimag

# 権限設定
sudo chmod 755 /home/partimag
sudo chown -R partimag:partimag /home/partimag

# ディスク容量確認
df -h /home/partimag
```

### 2. Clonezilla Live イメージの配置

```bash
# Clonezilla Live ISOのダウンロード
cd /tmp
wget https://sourceforge.net/projects/clonezilla/files/clonezilla_live_stable/clonezilla-live-latest-amd64.iso

# ISOマウントポイント作成
sudo mkdir -p /mnt/clonezilla

# ISOをマウント
sudo mount -o loop clonezilla-live-latest-amd64.iso /mnt/clonezilla

# 必要なファイルをコピー
sudo cp -r /mnt/clonezilla/live /tftpboot/nbi_img/

# アンマウント
sudo umount /mnt/clonezilla
```

### 3. PXEブートメニューの編集

```bash
# PXEメニューファイルの編集
sudo vim /tftpboot/nbi_img/pxelinux.cfg/default
```

**設定例**:
```
DEFAULT clonezilla
TIMEOUT 100
PROMPT 0

LABEL clonezilla
  MENU LABEL Clonezilla Live (Multicast Mode)
  KERNEL /live/vmlinuz
  APPEND initrd=/live/initrd.img boot=live union=overlay username=user config components noswap edd=on nomodeset nodmraid locales=ja_JP.UTF-8 keyboard-layouts=jp ocs_live_run="ocs-sr" ocs_live_extra_param="" ocs_live_batch=yes net.ifnames=0 nosplash i915.blacklist=yes radeonhd.blacklist=yes nouveau.blacklist=yes vmwgfx.enable_fbdev=1

LABEL local
  MENU LABEL Boot from local disk
  LOCALBOOT 0
```

### 4. Clonezilla起動スクリプトの作成

```bash
# マルチキャスト展開スクリプト
sudo tee /usr/local/bin/start-clonezilla-multicast.sh << 'EOF'
#!/bin/bash

# Clonezilla マルチキャスト展開スクリプト

IMAGE_NAME="win11-master-$(date +%Y%m%d)"
IMAGE_DIR="/home/partimag"
MAX_CLIENTS=20

# マルチキャストセッション開始
/usr/sbin/drbl-ocs \
  -b -g auto -e1 auto -e2 -r -j2 -c -p poweroff \
  --max-time-to-wait 300 \
  multicast_restore \
  "$IMAGE_NAME" \
  "ask_user"

EOF

sudo chmod +x /usr/local/bin/start-clonezilla-multicast.sh
```

---

## マスターイメージ管理

### 1. マスターイメージの作成

**Windowsマスターイメージの保存手順**:

```bash
# クライアントPCをPXEブートし、Clonezillaメニューから
# "savedisk" を選択

# または、サーバー側から実行
sudo /usr/sbin/drbl-ocs \
  -b -q2 -c -j2 -z1p -i 4096 -sfsck -senc -p true \
  savedisk \
  win11-master-20251116 \
  sda
```

**イメージ保存先**:
```bash
/home/partimag/win11-master-20251116/
├── Info-dmi.txt
├── Info-lshw.txt
├── Info-packages.txt
├── blkdev.list
├── blkid.list
├── clonezilla-img
├── dev-fs.list
├── disk
├── parts
├── sda-chs.sf
├── sda-gpt-1st
├── sda-gpt-2nd
├── sda-pt.sf
├── sda1.ext4-ptcl-img.gz.aa
└── sda2.ntfs-ptcl-img.gz.aa
```

### 2. マスターイメージの管理

```bash
# イメージ一覧表示
sudo ls -lh /home/partimag/

# イメージサイズ確認
sudo du -sh /home/partimag/*

# イメージの圧縮率確認
sudo cat /home/partimag/win11-master-20251116/Info-img-id.txt

# 古いイメージの削除
sudo rm -rf /home/partimag/old-image-name
```

### 3. イメージのバージョン管理

```bash
# イメージ命名規則
# win11-master-YYYYMMDD-vX

# 例
/home/partimag/
├── win11-master-20251101-v1/  # 初版
├── win11-master-20251115-v2/  # 更新版
└── win11-master-20251116-v3/  # 最新版

# シンボリックリンクで最新版を指定
sudo ln -s \
  /home/partimag/win11-master-20251116-v3 \
  /home/partimag/win11-master-latest
```

### 4. イメージのバックアップ

```bash
# 外部ストレージへのバックアップ
sudo rsync -avz --progress \
  /home/partimag/win11-master-20251116 \
  /mnt/backup/drbl-images/

# または tar.gz で圧縮
sudo tar czf \
  /mnt/backup/win11-master-20251116.tar.gz \
  /home/partimag/win11-master-20251116
```

---

## マルチキャスト設定

### 1. マルチキャスト用ネットワーク設定

```bash
# マルチキャストルーティングの有効化
sudo tee -a /etc/sysctl.conf << EOF
# Multicast settings for Clonezilla
net.ipv4.icmp_echo_ignore_broadcasts = 0
net.ipv4.conf.all.mc_forwarding = 1
EOF

# 設定適用
sudo sysctl -p
```

### 2. udpcastの設定

```bash
# udpcast設定ファイルの編集
sudo vim /etc/drbl/drbl.conf
```

**設定内容**:
```bash
# Multicast設定
MULTICAST_NETWORK="239.0.0.1"
MULTICAST_PORT_START="9000"
MAX_WAIT_TIME="300"  # クライアント接続待ち時間（秒）
MIN_CLIENTS="1"      # 最小クライアント数
```

### 3. マルチキャスト展開の実行

```bash
# マルチキャスト展開コマンド
sudo /usr/sbin/drbl-ocs \
  -b -g auto -e1 auto -e2 -r -j2 -c -p reboot \
  --max-time-to-wait 300 \
  --clients-to-wait 10 \
  multicast_restore \
  win11-master-20251116 \
  "ask_user"
```

**パラメータ説明**:
- `-b`: バッチモード（対話なし）
- `-g auto`: グラフィックカード自動検出
- `-e1 auto -e2`: ディスクチェック設定
- `-r`: 復元後に再起動
- `-j2`: ファイルシステムチェックをスキップ
- `-c`: クライアント台数確認
- `-p reboot`: 完了後の動作（reboot/poweroff/wait）
- `--max-time-to-wait 300`: 最大待機時間（秒）
- `--clients-to-wait 10`: 待機するクライアント数

---

## 自動起動設定

### 1. Systemdサービスファイルの作成

```bash
# DRBL自動起動サービス
sudo tee /etc/systemd/system/drbl-services.service << 'EOF'
[Unit]
Description=DRBL Services
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/drbl-all-service start
ExecStop=/usr/sbin/drbl-all-service stop

[Install]
WantedBy=multi-user.target
EOF
```

### 2. サービスの有効化

```bash
# サービスを有効化
sudo systemctl daemon-reload
sudo systemctl enable drbl-services.service

# 個別サービスの有効化
sudo systemctl enable isc-dhcp-server
sudo systemctl enable tftpd-hpa
sudo systemctl enable nfs-kernel-server

# 起動確認
sudo systemctl start drbl-services.service
sudo systemctl status drbl-services.service
```

### 3. 自動展開スクリプト（オプション）

```bash
# 定時展開スクリプト
sudo tee /usr/local/bin/scheduled-deployment.sh << 'EOF'
#!/bin/bash

# 定時自動展開スクリプト（例: 毎朝9時に20台展開）

LOG_FILE="/var/log/drbl/scheduled-deployment.log"
IMAGE_NAME="win11-master-latest"

echo "[$(date)] 自動展開開始" >> "$LOG_FILE"

/usr/sbin/drbl-ocs \
  -b -g auto -e1 auto -e2 -r -j2 -c -p poweroff \
  --max-time-to-wait 600 \
  --clients-to-wait 20 \
  multicast_restore \
  "$IMAGE_NAME" \
  "ask_user" \
  >> "$LOG_FILE" 2>&1

echo "[$(date)] 自動展開完了" >> "$LOG_FILE"
EOF

sudo chmod +x /usr/local/bin/scheduled-deployment.sh

# cronに登録（毎朝9時実行）
sudo crontab -e
# 0 9 * * * /usr/local/bin/scheduled-deployment.sh
```

---

## 動作確認

### 1. サービス起動確認

```bash
# 各サービスの状態確認
sudo systemctl status isc-dhcp-server
sudo systemctl status tftpd-hpa
sudo systemctl status nfs-kernel-server

# ポート確認
sudo netstat -tuln | grep -E ':67|:69|:2049'

# DHCP
67/udp - DHCP Server
# TFTP
69/udp - TFTP Server
# NFS
2049/tcp - NFS Server
```

### 2. PXEブート確認

```bash
# TFTPファイルの確認
ls -l /tftpboot/nbi_img/
ls -l /tftpboot/nbi_img/pxelinux.cfg/default

# PXEブートログの確認
sudo tail -f /var/log/syslog | grep -i dhcp
sudo tail -f /var/log/syslog | grep -i tftp
```

### 3. クライアントPCでのテスト

**手順**:
1. クライアントPCのBIOS設定でPXEブートを有効化
2. ネットワークブートを実行
3. DHCP経由でIPアドレス取得を確認
4. PXEメニューが表示されることを確認
5. Clonezillaが起動することを確認

**期待される表示**:
```
PXE-E51: No DHCP or proxyDHCP offers were received
↓
DHCP........
IP Address: 192.168.1.150
Gateway: 192.168.1.1
↓
Loading Clonezilla...
```

### 4. ログ確認

```bash
# DRBLログ
sudo tail -f /var/log/drbl/drbl.log

# Clonezillaログ
sudo tail -f /var/log/drbl/clonezilla.log

# DHCPリース確認
sudo cat /var/lib/dhcp/dhcpd.leases
```

---

## トラブルシューティング

### 問題0: Docker干渉によるDRBL設定エラー（重要）

**症状**:
- `drblpush -i` 実行時に `docker0` インターフェース（172.17.0.1）が検出される
- `/tftpboot/nbi_img/` ディレクトリが存在せず、PXELinux設定に失敗
- カーネル検出エラー: `Unable to find kernel for client!!!`
- atftpdとtftpd-hpaの競合

**原因**:
- Dockerサービスが `docker0` 仮想ネットワークインターフェースを作成
- DRBLがこれをDRBL環境用NICとして誤認識
- atftpdがインストールされている場合、tftpd-hpaと競合

**解決策**:

```bash
# 自動修正スクリプトを実行
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project
sudo ./scripts/fix_drbl_docker_issue.sh

# または手動で修正:
# 1. Dockerサービスを停止・無効化
sudo systemctl stop docker.socket docker containerd
sudo systemctl disable docker.socket docker containerd

# 2. docker0インターフェースを無効化
sudo ip link set docker0 down

# 3. atftpdを削除、tftpd-hpaを使用
sudo apt remove atftpd
sudo apt install tftpd-hpa
sudo systemctl start tftpd-hpa
sudo systemctl enable tftpd-hpa

# 4. DRBL設定をクリーンアップして再実行
sudo /usr/sbin/drblsrv -i
sudo /usr/sbin/drblpush -i
```

**詳細ガイド**: [DRBL_FIX_DOCKER_GUIDE.md](./DRBL_FIX_DOCKER_GUIDE.md)

**緊急度**: 最高
**対応所要時間**: 15-20分

---

### 問題1: クライアントがDHCPからIPを取得できない

**症状**:
```
PXE-E51: No DHCP or proxyDHCP offers were received
```

**解決策**:
```bash
# DHCPサーバーの状態確認
sudo systemctl status isc-dhcp-server

# DHCPサーバーの再起動
sudo systemctl restart isc-dhcp-server

# DHCP設定ファイルの確認
sudo vim /etc/dhcp/dhcpd.conf

# 正しいインターフェースが指定されているか確認
sudo vim /etc/default/isc-dhcp-server
# INTERFACESv4="ens33"

# ファイアウォール確認
sudo ufw status
sudo ufw allow 67/udp
```

### 問題2: TFTPブートイメージが転送されない

**症状**:
```
TFTP timeout
```

**解決策**:
```bash
# TFTPサーバーの確認
sudo systemctl status tftpd-hpa

# TFTP設定ファイル確認
sudo cat /etc/default/tftpd-hpa

# パーミッション確認
sudo ls -l /tftpboot/nbi_img/
sudo chmod -R 755 /tftpboot/

# ファイアウォール確認
sudo ufw allow 69/udp

# 手動テスト
tftp localhost
tftp> get pxelinux.0
```

### 問題3: マルチキャストが動作しない

**症状**:
クライアントが接続待機のまま進まない

**解決策**:
```bash
# スイッチでIGMP Snoopingが有効か確認

# マルチキャストルーティング確認
ip maddr show

# udpcast設定確認
sudo vim /etc/drbl/drbl.conf

# 手動でユニキャスト展開に切り替え
sudo /usr/sbin/drbl-ocs \
  -b -g auto -e1 auto -e2 -r -j2 -p reboot \
  restore \
  win11-master-20251116 \
  sda
```

### 問題4: イメージ復元が失敗する

**症状**:
```
Error: partition table not found
```

**解決策**:
```bash
# イメージファイルの整合性確認
sudo ls -l /home/partimag/win11-master-20251116/

# 必要なファイルが存在するか確認
# - disk
# - parts
# - sda-pt.sf
# - sda1.*.gz.*

# イメージの再作成を検討
# ディスクタイプ（MBR/GPT）の確認
sudo gdisk -l /dev/sda
```

### 問題5: NFSマウントエラー

**症状**:
```
mount.nfs: access denied
```

**解決策**:
```bash
# NFS設定確認
sudo cat /etc/exports

# NFSサーバー再起動
sudo systemctl restart nfs-kernel-server

# エクスポート一覧確認
sudo exportfs -v

# クライアント側で手動マウントテスト
sudo mount -t nfs 192.168.1.100:/home/partimag /mnt
```

### ログの確認方法

```bash
# 総合ログ
sudo journalctl -xe

# DHCPログ
sudo journalctl -u isc-dhcp-server -f

# TFTPログ
sudo journalctl -u tftpd-hpa -f

# NFSログ
sudo journalctl -u nfs-kernel-server -f
```

---

## メンテナンス

### 定期メンテナンス項目

```bash
# ディスク容量確認（週次）
df -h /home/partimag

# 古いイメージの削除（月次）
sudo find /home/partimag -name "win11-master-*" -mtime +90 -exec rm -rf {} \;

# ログローテーション設定
sudo vim /etc/logrotate.d/drbl

# システムアップデート（月次）
sudo apt update && sudo apt upgrade -y
```

---

## 参考資料

- [DRBL公式サイト](https://drbl.org/)
- [Clonezilla公式サイト](https://clonezilla.org/)
- [DRBLドキュメント](https://drbl.org/documentation/)

---

## 更新履歴

| 日付 | バージョン | 更新内容 |
|------|-----------|---------|
| 2025-11-19 | 1.1 | Docker干渉問題のトラブルシューティングセクションを追加 |
| 2025-11-17 | 1.0 | 初版作成 |
