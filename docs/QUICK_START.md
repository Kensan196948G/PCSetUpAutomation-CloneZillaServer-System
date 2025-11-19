# クイックスタートガイド

このガイドでは、最速でClonezilla Serverを使ったPCキッティングシステムを立ち上げる手順を説明します。

## 前提条件

- Ubuntu Server 22.04 LTSがインストール済み
- サーバーにGigabit Ethernetのネットワークインターフェースがある
- 最低500GBのストレージがある
- キッティング専用のネットワークセグメントまたはVLANがある

## 30分セットアップ

### ステップ1: リポジトリのクローン（2分）

```bash
cd ~
git clone https://github.com/Kensan196948G/PCSetUpAutomation-CloneZillaServer-System.git
cd PCSetUpAutomation-CloneZillaServer-System
```

### ステップ2: ネットワーク設定（5分）

```bash
# ネットワークインターフェース名を確認
ip addr show

# Netplan設定ファイルをコピー
sudo cp configs/netplan-example.yaml /etc/netplan/00-installer-config.yaml

# 実際のインターフェース名に合わせて編集
sudo nano /etc/netplan/00-installer-config.yaml

# 設定を適用
sudo netplan apply

# 確認
ip addr show
```

### ステップ3: サーバーセットアップ（15分）

```bash
# セットアップスクリプトに実行権限を付与
chmod +x scripts/*.sh

# サーバーセットアップを実行
sudo ./scripts/01-server-setup.sh
```

このスクリプトは以下を自動的に行います：
- システムの更新
- 必要なパッケージのインストール
- DRBL/Clonezillaのインストール
- NFS設定
- ファイアウォール設定

### ステップ4: DRBL初期設定（5分）

```bash
# DRBL初期設定
sudo /usr/sbin/drblsrv -i
```

**推奨設定値:**
- Network interface: `enp0s3` (実際のインターフェース名)
- Domain name: `kitting.local`
- NIS/YP domain name: `kitting`
- DHCP service: `yes`
- DHCP range: `192.168.100.10` to `192.168.100.100`
- DNS: `8.8.8.8`

### ステップ5: DRBLクライアント設定（3分）

```bash
# DRBLクライアント設定
sudo /usr/sbin/drblpush -i
```

**推奨設定値:**
- Client mode: `clonezilla-live`
- Clonezilla mode: `clonezilla-live`
- Multicast mode: `yes`
- Time to wait: `70` seconds
- Max clients: `40`

### ステップ6: 動作確認

```bash
# ステータス確認スクリプトを実行
./scripts/05-check-status.sh
```

以下がすべて ✓ になっていることを確認：
- NFS Server: ✓ 起動中
- Dnsmasq (DHCP/TFTP): ✓ 起動中
- DHCP (67/udp): ✓ リスニング中
- TFTP (69/udp): ✓ リスニング中
- NFS (2049/tcp): ✓ リスニング中

## 最初のイメージ作成

### 1. マスターPCの準備

1. Windows 10/11をクリーンインストール
2. 必要なアプリケーションをインストール
3. Windows Updateを適用
4. （推奨）Sysprepを実行

### 2. イメージ作成

サーバーで実行：

```bash
sudo ./scripts/02-create-image.sh win11-base-2025
```

ブラウザで `http://192.168.100.1:2556` にアクセスし、以下を設定：
- Mode: **Beginner**
- Task: **savedisk**
- Image name: **win11-base-2025**
- Select disk: **sda**
- Compression: **z1p**
- Clients: **1**

マスターPCをPXEブートで起動すると、自動的にイメージが作成されます。

### 3. イメージ確認

```bash
./scripts/04-list-images.sh win11-base-2025
```

## 最初の展開

### 1. 展開スクリプト実行

```bash
sudo ./scripts/03-deploy-multicast.sh win11-base-2025 5 600
```

パラメータ:
- イメージ名: `win11-base-2025`
- 台数: `5`
- タイムアウト: `600`秒（10分）

### 2. ターゲットPCの起動

1. すべてのターゲットPCをキッティングネットワークに接続
2. PXEブートで起動（BIOS設定でネットワークブートを最優先に）
3. 自動的にClonezillaが起動し、イメージ展開が開始されます

### 3. 進捗確認

別のターミナルで：

```bash
# ログ確認
sudo tail -f /var/log/clonezilla/clonezilla-*.log

# ネットワークトラフィック確認
sudo iftop -i enp0s3
```

## トラブルシューティング

### PXEブートできない

```bash
# DHCPサービス確認
sudo systemctl status dnsmasq

# DHCPリース確認
cat /var/lib/misc/dnsmasq.leases

# TFTPサービス確認
sudo netstat -ulnp | grep :69
```

### イメージが見つからない

```bash
# イメージ一覧確認
./scripts/04-list-images.sh

# パーミッション確認
ls -la /home/partimag/
```

### ネットワークが遅い

```bash
# ネットワーク帯域確認
sudo iftop -i enp0s3

# リンク速度確認
ethtool enp0s3 | grep Speed
```

## 次のステップ

- [README.md](../README.md) で詳細な設定を確認
- [WORKFLOWS.md](./WORKFLOWS.md) で運用ワークフローを確認
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) でトラブルシューティングの詳細を確認

## 参考リンク

- [Clonezilla 公式サイト](https://clonezilla.org/)
- [DRBL プロジェクト](https://drbl.org/)
- [Ubuntu Server ドキュメント](https://ubuntu.com/server/docs)
