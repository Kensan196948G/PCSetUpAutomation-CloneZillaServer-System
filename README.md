# 会社キッティング自動化フレームワーク

年間100台規模のWindows PCを完全自動でキッティングするシステム

## 概要

本プロジェクトは、「**LANに挿して電源を入れるだけ**」でWindows PCのキッティングを完全自動化するシステムです。Clonezilla Serverをベースとし、DHCP/TFTP/PXEブートを組み合わせることで、大規模なPC展開を効率化します。

## 主要機能

- 🚀 **完全自動デプロイ**: ネットワークに接続して電源を入れるだけで自動的にOSイメージを展開
- 🖥️ **マルチキャスト対応**: 最大40台を同時に高速展開可能
- 🔧 **カスタマイズ可能**: 部署別・用途別の設定を柔軟に適用
- 📊 **スケーラブル**: 年間100台規模の運用に対応
- 🔒 **セキュア**: ネットワーク分離とアクセス制御で安全性を確保
- 📝 **ログ管理**: 展開履歴とエラーログを自動記録

## システムアーキテクチャ

```
┌─────────────────────────────────────────────────┐
│           Clonezilla Server (Ubuntu)            │
│  ┌──────────┐ ┌──────────┐ ┌─────────────────┐ │
│  │  DHCP    │ │   TFTP   │ │   Clonezilla    │ │
│  │ Server   │ │  Server  │ │  SE (Multicast) │ │
│  └──────────┘ └──────────┘ └─────────────────┘ │
└─────────────────────────────────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        │    Gigabit Switch         │
        └─────────────┬─────────────┘
                      │
        ┌─────────────┴─────────────┐
        │   PXE Boot Enabled PCs    │
        │  (Target Machines 1-40)   │
        └───────────────────────────┘
```

## 前提条件

### ハードウェア要件

#### Clonezilla Server
- **CPU**: Intel Core i5以上 (推奨: Core i7 / Xeon)
- **RAM**: 8GB以上 (推奨: 16GB)
- **ストレージ**: 500GB以上 (推奨: 1TB SSD)
  - システム用: 50GB
  - イメージ保存用: 450GB以上
- **ネットワーク**: Gigabit Ethernet (必須)

#### ネットワークインフラ
- Gigabitスイッチ (推奨: 48ポート以上)
- 専用VLANまたは物理的に分離されたネットワーク
- キッティング専用のIPセグメント (例: 192.168.100.0/24)

#### ターゲットPC
- PXEブート対応のNIC
- BIOS/UEFIでネットワークブートを有効化
- 最低64GB以上のストレージ

### ソフトウェア要件

#### Clonezilla Server
- **OS**: Ubuntu Server 22.04 LTS (推奨)
- **Clonezilla SE**: 最新安定版
- **必須パッケージ**:
  - dnsmasq (DHCP/TFTP統合サーバー)
  - drbl (Diskless Remote Boot in Linux)
  - clonezilla

## インストール手順

### 1. サーバーのセットアップ

#### Ubuntu Serverのインストール

```bash
# システムを最新化
sudo apt update && sudo apt upgrade -y

# 必要なパッケージをインストール
sudo apt install -y git curl wget vim net-tools

# 静的IPアドレスの設定 (例: 192.168.100.1)
sudo nano /etc/netplan/00-installer-config.yaml
```

**Netplan設定例** (`/etc/netplan/00-installer-config.yaml`):
```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: no
      addresses:
        - 192.168.100.1/24
      gateway4: 192.168.100.254
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
```

```bash
# ネットワーク設定を適用
sudo netplan apply

# ファイアウォールの設定
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 67/udp   # DHCP
sudo ufw allow 69/udp   # TFTP
sudo ufw allow 111/tcp  # RPC
sudo ufw allow 111/udp  # RPC
sudo ufw allow 2049/tcp # NFS
sudo ufw enable
```

### 2. DRBL/Clonezillaのインストール

```bash
# DRBLリポジトリを追加
wget -q https://drbl.org/GPG-KEY-DRBL -O- | sudo apt-key add -
echo "deb http://free.nchc.org.tw/drbl-core drbl stable" | sudo tee /etc/apt/sources.list.d/drbl.list

# パッケージリストを更新
sudo apt update

# DRBL/Clonezillaをインストール
sudo apt install -y drbl clonezilla

# DRBLの初期設定
sudo /usr/sbin/drblsrv -i
```

**DRBL設定時の推奨パラメータ**:
- Network interface: `enp0s3` (実際のインターフェース名)
- Domain name: `kitting.local`
- NIS/YP domain name: `kitting`
- DHCP service: `yes`
- DHCP range: `192.168.100.10` ~ `192.168.100.100`
- DNS: `8.8.8.8`

```bash
# DRBLクライアント設定
sudo /usr/sbin/drblpush -i
```

**DRBLPush設定時の推奨パラメータ**:
- Client mode: `clonezilla-live`
- Clonezilla mode: `clonezilla-live`
- Multicast mode: `yes`
- Time to wait: `70` seconds
- Max clients: `40`

### 3. イメージディレクトリの準備

```bash
# イメージ保存ディレクトリを作成
sudo mkdir -p /home/partimag
sudo chmod 755 /home/partimag

# NFSエクスポート設定
echo "/home/partimag *(ro,async,no_wdelay,no_root_squash,insecure_locks,insecure)" | sudo tee -a /etc/exports

# NFSサービスを再起動
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
```

## 使用方法

### イメージの作成（マスターPCのキャプチャ）

1. **マスターPCの準備**
   - Windows 10/11をクリーンインストール
   - 必要なアプリケーションをインストール
   - Windows Updateを適用
   - ドライバーをインストール
   - Sysprepで一般化 (推奨)

2. **Clonezillaでイメージ作成**

サーバー側:
```bash
# Clonezilla SE起動
sudo dcs
```

ブラウザで `http://192.168.100.1:2556` にアクセスし、以下を設定:
- Mode: `Beginner`
- Task: `savedisk`
- Image name: `win11-base-2025` (例)
- Select disk: `sda` (ターゲットディスク)
- Compression: `z1p` (並列gzip圧縮)
- Clients: `1` (マスターPC1台のみ)

マスターPC側:
- PXEブートで起動
- Clonezillaが自動起動
- イメージ作成が完了するまで待機

3. **イメージの確認**

```bash
# 作成されたイメージを確認
ls -lh /home/partimag/win11-base-2025/

# イメージ情報を表示
cat /home/partimag/win11-base-2025/disk
cat /home/partimag/win11-base-2025/parts
```

### 大量展開（マルチキャスト）

1. **展開設定**

サーバー側:
```bash
# Clonezilla SE起動
sudo dcs
```

ブラウザで設定:
- Mode: `Beginner`
- Task: `restoredisk`
- Image name: `win11-base-2025`
- Target: `sda`
- Mode: `Multicast`
- Clients: `40` (展開台数に応じて調整)
- Time to wait: `600` seconds (10分)

2. **ターゲットPCの起動**

- すべてのターゲットPCをPXEブートで起動
- 自動的にClonezillaが起動し、待機状態になる
- 指定台数が揃うか、タイムアウト時間経過後に展開開始

3. **展開モニタリング**

```bash
# 進捗確認
sudo tail -f /var/log/clonezilla/clonezilla-*.log

# ネットワークトラフィック確認
sudo iftop -i enp0s3
```

### ワークフロー全体

```
┌─────────────────┐
│ マスターPC準備  │
│  - OS install   │
│  - App install  │
│  - Sysprep      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ イメージ作成    │
│  - savedisk     │
│  - 1台のみ      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ イメージ保存    │
│ /home/partimag  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 大量展開設定    │
│  - restoredisk  │
│  - multicast    │
│  - 最大40台     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ ターゲットPC    │
│  - PXE boot     │
│  - 自動展開     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 展開完了        │
│  - 自動再起動   │
│  - Windows起動  │
└─────────────────┘
```

## 高度な設定

### カスタムポストインストールスクリプト

展開後に自動実行されるスクリプトを配置できます。

**例**: コンピューター名の自動設定

`/home/partimag/scripts/post-deploy.bat`:
```batch
@echo off
REM コンピューター名を自動設定
set PREFIX=PC
for /f "tokens=1-2 delims=:-" %%a in ('getmac /fo csv /nh') do (
    set MAC=%%~a
    goto :break
)
:break
set PCNAME=%PREFIX%-%MAC:~-8%
wmic computersystem where name="%COMPUTERNAME%" call rename name="%PCNAME%"
shutdown /r /t 30
```

### 部署別イメージ管理

```bash
# イメージ命名規則
/home/partimag/
├── accounting-win11-2025/    # 経理部門用
├── sales-win11-2025/         # 営業部門用
├── engineering-win11-2025/   # 開発部門用
└── general-win11-2025/       # 一般用途
```

### 自動化スクリプト

**自動展開スクリプト** (`/usr/local/bin/auto-deploy.sh`):
```bash
#!/bin/bash
# 自動展開スクリプト

IMAGE_NAME="${1:-general-win11-2025}"
CLIENT_COUNT="${2:-10}"
TIMEOUT="${3:-600}"

echo "Starting automatic deployment..."
echo "Image: $IMAGE_NAME"
echo "Clients: $CLIENT_COUNT"
echo "Timeout: $TIMEOUT seconds"

# Clonezilla SE開始
/usr/sbin/dcs -h 192.168.100.1 -l en_US.UTF-8 -z 1 \
  -s "$IMAGE_NAME" -c restoredisk -r sda \
  -g auto -e1 auto -e2 -r -j2 -sc0 -p choose \
  -t 40 -i 2000 -m "$CLIENT_COUNT" -w "$TIMEOUT"

echo "Deployment started. Waiting for clients..."
```

使用方法:
```bash
sudo chmod +x /usr/local/bin/auto-deploy.sh
sudo /usr/local/bin/auto-deploy.sh general-win11-2025 20 600
```

## トラブルシューティング

### よくある問題と解決方法

#### 1. PXEブートが失敗する

**症状**: ターゲットPCがネットワークブートできない

**解決方法**:
```bash
# DHCPサービスの状態確認
sudo systemctl status dnsmasq

# DHCPリース確認
cat /var/lib/misc/dnsmasq.leases

# TFTPサービス確認
sudo netstat -ulnp | grep :69

# ファイアウォール確認
sudo ufw status
```

#### 2. マルチキャストが遅い

**症状**: 展開速度が想定より遅い

**解決方法**:
```bash
# ネットワーク帯域確認
sudo iftop -i enp0s3

# スイッチのマルチキャスト設定を確認
# IGMPスヌーピングが有効か確認

# パラメータ調整
sudo nano /etc/drbl/drbl.conf
# 以下を追加/変更
DRBL_MULTICAST_MAX_WAIT=70
DRBL_CLIENTS_BATCH_SIZE=40
```

#### 3. イメージ復元エラー

**症状**: `Partition table not found`などのエラー

**解決方法**:
```bash
# イメージの整合性確認
cd /home/partimag/win11-base-2025/
ls -lh

# 必須ファイル確認
# - disk (ディスク情報)
# - parts (パーティション情報)
# - sda*.gz (イメージデータ)

# イメージ再作成が必要な場合
sudo rm -rf /home/partimag/broken-image/
# イメージを再作成
```

#### 4. ディスク容量不足

**症状**: イメージ保存時に容量エラー

**解決方法**:
```bash
# ディスク使用状況確認
df -h /home/partimag

# 古いイメージの削除
sudo rm -rf /home/partimag/old-image-*/

# または外部ストレージをマウント
sudo mount /dev/sdb1 /mnt/images
sudo ln -s /mnt/images /home/partimag/archive
```

### ログファイル

```bash
# Clonezillaログ
/var/log/clonezilla/

# DRBLログ
/var/log/drbl/

# DHCPログ
journalctl -u dnsmasq -f

# システムログ
journalctl -xe
```

## パフォーマンス最適化

### ネットワーク最適化

```bash
# Jumbo Frame有効化 (スイッチ対応の場合)
sudo ip link set enp0s3 mtu 9000

# TCP/IP パラメータ調整
sudo sysctl -w net.core.rmem_max=134217728
sudo sysctl -w net.core.wmem_max=134217728
sudo sysctl -w net.ipv4.tcp_rmem="4096 87380 134217728"
sudo sysctl -w net.ipv4.tcp_wmem="4096 65536 134217728"
```

### ストレージ最適化

```bash
# SSDの場合、TRIMを有効化
sudo systemctl enable fstrim.timer

# I/Oスケジューラ最適化
echo "none" | sudo tee /sys/block/sda/queue/scheduler
```

## セキュリティ考慮事項

### ネットワーク分離

- キッティング用ネットワークは**必ず**本番環境から分離する
- VLAN分離または物理的な分離を推奨
- ファイアウォールで適切にアクセス制御

### アクセス制御

```bash
# SSH公開鍵認証のみ許可
sudo nano /etc/ssh/sshd_config
# 以下を設定
PasswordAuthentication no
PubkeyAuthentication yes

# rootログイン禁止
PermitRootLogin no

# SSHサービス再起動
sudo systemctl restart sshd
```

### イメージの暗号化

機密情報を含むイメージは暗号化を検討:

```bash
# イメージを暗号化
sudo ocs-sr -q2 -j2 -z9 -i 2000 -sfsck -senc -sc \
  -p reboot savedisk win11-secure sda
```

## 運用Tips

### 定期メンテナンス

```bash
# 週次: システム更新
sudo apt update && sudo apt upgrade -y

# 月次: イメージの棚卸し
ls -lht /home/partimag/ | head -20

# 四半期: マスターイメージの更新
# - Windows Update適用
# - アプリケーション更新
# - 新規イメージ作成
```

### バックアップ戦略

```bash
# イメージのバックアップ
sudo rsync -avz --progress /home/partimag/ /mnt/backup/partimag/

# システム設定のバックアップ
sudo tar czf /backup/drbl-config-$(date +%Y%m%d).tar.gz \
  /etc/drbl/ /etc/dnsmasq.d/ /etc/exports
```

### 展開記録の管理

```bash
# 展開ログの保存
echo "$(date),win11-base-2025,20,success" >> /var/log/deployment-history.csv

# CSV形式で管理
# 日時,イメージ名,台数,結果
```

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) を参照

## 貢献

プルリクエストを歓迎します。大きな変更の場合は、まずissueを開いて変更内容を議論してください。

## サポート

問題が発生した場合は、GitHubのIssuesで報告してください。

## 参考資料

- [Clonezilla Official Site](https://clonezilla.org/)
- [DRBL Project](https://drbl.org/)
- [Ubuntu Server Documentation](https://ubuntu.com/server/docs)

---

**作成者**: Kensan196948G  
**最終更新**: 2025年11月
