# 自宅環境でのPXEブート構築ガイド

**作成日**: 2025年11月17日
**対象環境**: 自宅ネットワーク（192.168.3.x/24）
**バージョン**: 1.0

---

## 🏠 現在のネットワーク構成

### デバイス一覧

| デバイス | IPアドレス | MACアドレス | 用途 |
|---------|-----------|------------|------|
| **ホームルータ** | 192.168.3.1 | - | DHCP/ゲートウェイ |
| **Ubuntu（DRBLサーバ）** | 192.168.3.135 | 44:8A:5B:4B:13:1A | Clonezillaサーバ |
| **Windows 11（操作ホスト）** | 192.168.3.92 | 98:90:96:B8:AC:B9 | 管理端末 |
| **MacOS** | 192.168.3.8 | 6C:F2:D8:F5:9A:A3 | - |
| **Windowsマスターイメージ搭載PC** | 192.168.3.139 | 8C:AA:B5:1A:48:6D | 展開対象PC ⭐ |

### ネットワーク図

```
[ホームルータ 192.168.3.1]
    │ DHCP範囲: 192.168.3.2 - 192.168.3.254
    │
    ├─[Ubuntu DRBL 192.168.3.135] ← ClonezillaサーバPXEブート提供
    │
    ├─[Windows 11 192.168.3.92] ← 管理端末
    │
    ├─[MacOS 192.168.3.8]
    │
    └─[Windows展開対象PC 192.168.3.139] ← PXEブートでイメージ展開 ⭐
```

---

## 🔍 PXEブート方式の選択

家庭用ルータの多くはPXEブート専用機能を持っていません。そのため、以下の2つの方式から選択します：

### 方式1: Ubuntu DRBLサーバで独自DHCPサーバを起動（推奨）⭐

**メリット**:
- ✅ 家庭用ルータの機能に依存しない
- ✅ 完全なPXEブート環境を構築可能
- ✅ マルチキャスト展開対応

**デメリット**:
- ⚠️ ルータのDHCP機能と競合する可能性
- ⚠️ ネットワーク設定の調整が必要

**適用条件**:
- DRBLサーバ（192.168.3.135）でDHCPサーバを起動
- ルータのDHCP範囲を調整、またはDRBL専用の静的割り当て

---

### 方式2: ルータのDHCP機能を拡張（ルータ依存）

**メリット**:
- ✅ 既存のDHCP環境を活用
- ✅ ネットワーク競合なし

**デメリット**:
- ❌ 家庭用ルータがPXEオプション（Option 66, 67）に対応していない場合が多い
- ❌ ルータのファームウェアカスタマイズが必要な場合がある

**適用条件**:
- ルータがDHCPオプション設定に対応している
- または、ルータにカスタムファームウェア（OpenWrt等）を導入可能

---

## ✅ 推奨方式: Ubuntu DRBLサーバで独自DHCPサーバを起動

自宅環境では**方式1（Ubuntu DRBLサーバで独自DHCP）**を推奨します。

### 前提条件

- Ubuntu DRBL サーバ（192.168.3.135）が稼働中
- DRBLパッケージがインストール済み
- ルータのDHCP設定を調整可能

---

## 🔧 設定手順

### ステップ1: ホームルータのDHCP範囲調整

**目的**: DRBLサーバのDHCPと競合しないようにする

**方法A: ルータのDHCP範囲を狭める（推奨）**

ルータ管理画面（http://192.168.3.1/）にアクセスし、以下のように設定：

**変更前**:
```
DHCP範囲: 192.168.3.2 - 192.168.3.254
```

**変更後**:
```
DHCP範囲: 192.168.3.2 - 192.168.3.99
```

これにより、`192.168.3.100 - 192.168.3.254` の範囲がDRBLサーバ専用になります。

**方法B: ルータのDHCPを完全に無効化**

DRBL専用ネットワークの場合、ルータのDHCPを完全に無効化することも可能です。

**注意**: この場合、すべてのデバイス（Windows、Mac等）も静的IPに変更する必要があります。

---

### ステップ2: Ubuntu DRBLサーバでDHCPサーバ設定

#### 2.1 DRBLインストール確認

```bash
# DRBLがインストールされているか確認
which drblsrv
# /opt/drbl/sbin/drblsrv と表示されればOK

# DRBLバージョン確認
drbl-live --version
```

#### 2.2 DHCP設定ファイル編集

**ファイル**: `/etc/dhcp/dhcpd.conf`

```bash
sudo nano /etc/dhcp/dhcpd.conf
```

**設定内容**:
```conf
# グローバル設定
ddns-update-style none;
default-lease-time 600;
max-lease-time 7200;
authoritative;

# PXEブート設定
option space pxelinux;
option pxelinux.magic code 208 = string;
option pxelinux.configfile code 209 = text;
option pxelinux.pathprefix code 210 = text;
option pxelinux.reboottime code 211 = unsigned integer 32;

# サブネット設定（自宅ネットワーク用）
subnet 192.168.3.0 netmask 255.255.255.0 {
    # DRBLサーバ専用のDHCP範囲
    range 192.168.3.100 192.168.3.200;

    # ゲートウェイ（ホームルータ）
    option routers 192.168.3.1;

    # DNSサーバ（ホームルータ）
    option domain-name-servers 192.168.3.1, 8.8.8.8;

    # PXEブート設定
    next-server 192.168.3.135;  # TFTPサーバIP（DRBL）
    filename "pxelinux.0";       # ブートファイル

    # 特定のPC（192.168.3.139）に固定IP割り当て
    host windows-master-pc {
        hardware ethernet 8C:AA:B5:1A:48:6D;
        fixed-address 192.168.3.139;
    }
}
```

#### 2.3 DHCPサーバインターフェース設定

**ファイル**: `/etc/default/isc-dhcp-server`

```bash
sudo nano /etc/default/isc-dhcp-server
```

**設定内容**:
```conf
# DHCPサーバが使用するネットワークインターフェース
INTERFACESv4="ens33"  # または eth0、enp0s3 等（ifconfig で確認）
INTERFACESv6=""
```

**ネットワークインターフェース確認**:
```bash
ip addr show | grep "inet 192.168.3.135"
# 3: ens33: ... inet 192.168.3.135/24 ... のように表示される
```

#### 2.4 DHCPサーバ起動

```bash
# DHCP設定ファイルの構文チェック
sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf

# DHCPサーバ起動
sudo systemctl start isc-dhcp-server

# 自動起動設定
sudo systemctl enable isc-dhcp-server

# ステータス確認
sudo systemctl status isc-dhcp-server
```

**期待される出力**:
```
● isc-dhcp-server.service - ISC DHCP IPv4 server
   Loaded: loaded (/lib/systemd/system/isc-dhcp-server.service; enabled)
   Active: active (running) since ...
```

---

### ステップ3: TFTPサーバ設定

#### 3.1 TFTPサーバインストール確認

```bash
which in.tftpd
# /usr/sbin/in.tftpd と表示されればOK

# TFTPサーバ起動確認
sudo systemctl status tftpd-hpa
```

#### 3.2 TFTP設定

**ファイル**: `/etc/default/tftpd-hpa`

```bash
sudo nano /etc/default/tftpd-hpa
```

**設定内容**:
```conf
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/tftpboot"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure --create --timeout 300"
```

#### 3.3 TFTPサーバ起動

```bash
sudo systemctl start tftpd-hpa
sudo systemctl enable tftpd-hpa
sudo systemctl status tftpd-hpa
```

---

### ステップ4: PXEブートファイル配置

#### 4.1 pxelinux.0とメニュー設定

```bash
# pxelinux.0 存在確認
ls -lh /tftpboot/pxelinux.0

# PXEメニュー設定ファイル確認
ls -lh /tftpboot/pxelinux.cfg/default
```

**pxelinux.cfg/default内容例**:
```
DEFAULT menu.c32
PROMPT 0
TIMEOUT 300
MENU TITLE DRBL/Clonezilla Network Boot Menu

LABEL clonezilla
  MENU LABEL Clonezilla Live (Network)
  KERNEL vmlinuz-clonezilla
  APPEND initrd=initrd-clonezilla.img boot=live config components quiet noswap edd=on nomodeset nodmraid locales= keyboard-layouts= ocs_live_run="ocs-live-general" ocs_live_extra_param="" ocs_live_batch=no net_default_server="192.168.3.135" ocs_server="192.168.3.135"

LABEL local
  MENU LABEL Boot from local drive
  LOCALBOOT 0
```

---

### ステップ5: ファイアウォール設定

```bash
# ファイアウォール状態確認
sudo ufw status

# DHCP（UDP 67, 68）許可
sudo ufw allow 67/udp
sudo ufw allow 68/udp

# TFTP（UDP 69）許可
sudo ufw allow 69/udp

# NFS（TCP 2049）許可
sudo ufw allow 2049/tcp

# Flask管理GUI（TCP 5000, 8000）許可
sudo ufw allow 5000/tcp
sudo ufw allow 8000/tcp

# ファイアウォール再読み込み
sudo ufw reload
```

---

### ステップ6: PXEブート動作確認

#### 6.1 展開対象PC（192.168.3.139）のBIOS設定

**手順**:
1. PC（192.168.3.139）の電源を入れる
2. BIOS/UEFI画面に入る（F2、F12、Delキー等）
3. **Boot順序**を以下に設定:
   - 1位: Network Boot / PXE Boot
   - 2位: HDD/SSD
4. **Secure Boot**: 無効化（Clonezilla要件）
5. **UEFIモード**: 有効（推奨）
6. 設定保存して再起動

#### 6.2 PXEブート試行

**手順**:
1. PC再起動
2. PXEブートが開始される（画面に「PXE-E...」メッセージ表示）
3. 以下のいずれかが表示されれば成功:

**成功例**:
```
PXE-M0F: Exiting PXE ROM.
PXELINUX 6.03 ...
Clonezilla Live Menu
```

**失敗例**:
```
PXE-E53: No boot filename received
PXE-E32: TFTP open timeout
PXE-M0F: Exiting PXE ROM.
Booting from local drive...
```

#### 6.3 トラブルシューティング

**問題1: PXE-E53（No boot filename received）**

**原因**: DHCPサーバがPXEブート情報を返していない

**対処**:
```bash
# Ubuntu DRBLサーバで確認
sudo systemctl status isc-dhcp-server

# DHCPログ確認
sudo tail -f /var/log/syslog | grep dhcpd

# PC（192.168.3.139）を再起動してDHCP要求を確認
# 以下のようなログが出力されるか確認:
# DHCPDISCOVER from 8c:aa:b5:1a:48:6d via ens33
# DHCPOFFER on 192.168.3.139 to 8c:aa:b5:1a:48:6d via ens33
```

**問題2: PXE-E32（TFTP open timeout）**

**原因**: TFTPサーバが応答していない

**対処**:
```bash
# TFTPサーバ確認
sudo systemctl status tftpd-hpa

# TFTPポート確認
sudo netstat -ulnp | grep :69

# ファイアウォール確認
sudo ufw status | grep 69

# TFTPファイル存在確認
ls -lh /tftpboot/pxelinux.0
```

---

## 🏠 家庭用ルータのPXEブート対応確認方法

### 方法1: ルータ管理画面で確認

#### アクセス
```
URL: http://192.168.3.1/
ユーザー名: user
パスワード: user
```

#### 確認項目

1. **DHCP設定メニュー**を探す
   - LAN設定 → DHCP設定
   - ネットワーク設定 → DHCP
   - 詳細設定 → DHCP Server

2. **PXE関連の設定項目**を確認:
   - ☐ DHCP Option 66（TFTP Server Name）
   - ☐ DHCP Option 67（Bootfile Name）
   - ☐ PXE Server設定
   - ☐ Network Boot設定

3. **カスタムDHCPオプション**が設定可能か確認

#### 設定例（対応ルータの場合）

```
DHCP Option 66: 192.168.3.135  # TFTPサーバIP
DHCP Option 67: pxelinux.0     # ブートファイル名
```

### 方法2: ルータの型番を調査

ルータの型番が分かれば、PXEブート対応可否を確認できます。

**確認方法**:
```bash
# ルータのHTMLから型番抽出
curl -s http://192.168.3.1/ | grep -i "model\|router\|product"

# または、ルータ背面のラベルを確認
# 型番: [ここに記載]
```

**一般的なメーカー別対応状況**:

| メーカー | PXEブート対応 | 備考 |
|---------|-------------|------|
| **BUFFALO** | 一部モデルのみ | ビジネスモデルは対応 |
| **NEC（Aterm）** | 非対応 | カスタムファームウェア必要 |
| **TP-Link** | 一部モデルのみ | OpenWrt対応モデルあり |
| **ASUS** | 対応（一部） | 詳細設定で可能 |
| **Netgear** | 対応（一部） | ビジネスモデルは対応 |

---

## 🛠️ 実装手順（方式1: DRBL独自DHCP）

### ステップ1: ホームルータのDHCP範囲変更

**設定目標**:
```
ルータDHCP範囲: 192.168.3.2 - 192.168.3.99
DRBL DHCP範囲: 192.168.3.100 - 192.168.3.200
```

**ルータ設定**（管理画面で実施）:
1. http://192.168.3.1/ にアクセス
2. LAN設定 → DHCP設定
3. DHCP開始IP: `192.168.3.2`
4. DHCP終了IP: `192.168.3.99`
5. 設定保存・再起動

**既存デバイスのIP調整**:
- Ubuntu DRBL: 192.168.3.135（変更不要、DRBL範囲内）
- Windows 11: 192.168.3.92（変更不要、ルータ範囲内）
- MacOS: 192.168.3.8（変更不要、ルータ範囲内）
- Windows展開対象PC: 192.168.3.139（DRBL範囲内、PXEブート時に自動割り当て）

---

### ステップ2: Ubuntu DRBLサーバでDHCP起動

```bash
# DHCP設定ファイル確認
sudo cat /etc/dhcp/dhcpd.conf | grep subnet

# 設定が正しいことを確認:
# subnet 192.168.3.0 netmask 255.255.255.0 {
#     range 192.168.3.100 192.168.3.200;
#     next-server 192.168.3.135;
#     filename "pxelinux.0";
# }

# DHCPサーバ起動
sudo systemctl restart isc-dhcp-server

# ステータス確認
sudo systemctl status isc-dhcp-server
```

**期待される出力**:
```
● isc-dhcp-server.service - ISC DHCP IPv4 server
   Active: active (running)
```

---

### ステップ3: TFTPサーバ起動確認

```bash
# TFTPサーバ起動
sudo systemctl restart tftpd-hpa

# ステータス確認
sudo systemctl status tftpd-hpa

# TFTPポート確認
sudo netstat -ulnp | grep :69
```

---

### ステップ4: PXEブートテスト

#### 4.1 展開対象PC（192.168.3.139）で実施

**手順**:
1. PCの電源を入れる
2. BIOS設定でPXEブートを最優先に設定済みであることを確認
3. PC再起動
4. 画面に「PXE」関連のメッセージが表示されるか確認

**成功時の画面表示例**:
```
>> Checking Media Presence......
>> Media Present......
>> Start PXE over IPv4.
  Station IP address is 192.168.3.139
  Server IP address is 192.168.3.135
  NBP filename is pxelinux.0
  NBP filesize is 42821 Bytes
  Downloading NBP file...

  PXELINUX 6.03 20171011 ...

  [Clonezilla Live Menu]
  1. Clonezilla live (Default)
  2. Boot from local drive
```

#### 4.2 DRBLサーバ側のログ確認

**リアルタイムログ監視**:
```bash
# ターミナル1: DHCPログ監視
sudo tail -f /var/log/syslog | grep dhcpd

# ターミナル2: TFTPログ監視
sudo tail -f /var/log/syslog | grep tftpd
```

**期待されるログ出力**:
```
# DHCP
Nov 17 13:00:01 drbl dhcpd[1234]: DHCPDISCOVER from 8c:aa:b5:1a:48:6d via ens33
Nov 17 13:00:02 drbl dhcpd[1234]: DHCPOFFER on 192.168.3.139 to 8c:aa:b5:1a:48:6d via ens33
Nov 17 13:00:03 drbl dhcpd[1234]: DHCPREQUEST for 192.168.3.139 from 8c:aa:b5:1a:48:6d via ens33
Nov 17 13:00:04 drbl dhcpd[1234]: DHCPACK on 192.168.3.139 to 8c:aa:b5:1a:48:6d via ens33

# TFTP
Nov 17 13:00:05 drbl in.tftpd[5678]: RRQ from 192.168.3.139 filename pxelinux.0
Nov 17 13:00:06 drbl in.tftpd[5678]: RRQ from 192.168.3.139 filename pxelinux.cfg/default
```

---

## 📋 PXEブート動作確認チェックリスト

### Ubuntu DRBLサーバ側

- [ ] DRBLインストール完了（`drblsrv --version`）
- [ ] DHCP設定完了（`/etc/dhcp/dhcpd.conf`）
- [ ] DHCP範囲設定（192.168.3.100-200）
- [ ] next-server設定（192.168.3.135）
- [ ] DHCPサーバ起動（`systemctl status isc-dhcp-server`）
- [ ] TFTPサーバ起動（`systemctl status tftpd-hpa`）
- [ ] pxelinux.0存在（`/tftpboot/pxelinux.0`）
- [ ] ファイアウォール設定（ポート67, 68, 69開放）

### ホームルータ側

- [ ] DHCP範囲調整（192.168.3.2-99）または無効化
- [ ] 設定保存・再起動

### 展開対象PC側

- [ ] BIOS設定（PXEブート最優先）
- [ ] Secure Boot無効化
- [ ] LANケーブル接続確認
- [ ] ネットワークブート有効化

---

## 🔍 トラブルシューティング

### 問題0: Docker干渉によるDRBL設定失敗（最重要）

**症状**:
- `drblpush -i` 実行時に `docker0` (172.17.0.1) が誤検出される
- `/tftpboot/nbi_img/` ディレクトリが作成されない
- PXEブート環境が正しく構築されない

**原因**:
Docker が作成する `docker0` 仮想ネットワークインターフェースとDRBLが競合

**解決方法**:

```bash
# 自動修正スクリプトを実行
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project
sudo ./scripts/fix_drbl_docker_issue.sh
```

**詳細**: [DRBL_FIX_DOCKER_GUIDE.md](./DRBL_FIX_DOCKER_GUIDE.md)

**対応時間**: 15-20分

---

### 問題1: ルータとDRBLのDHCPが競合する

**症状**: PCがルータからIPを取得してしまい、PXEブートしない

**対処法A: ルータDHCP範囲変更**（推奨）
```
ルータDHCP: 192.168.3.2 - 192.168.3.99
DRBL DHCP: 192.168.3.100 - 192.168.3.200
```

**対処法B: DHCP優先度調整**
```bash
# DRBLサーバのDHCP応答を高速化
sudo nano /etc/dhcp/dhcpd.conf
# authoritative; を追加（既に設定済み）
```

**対処法C: ルータDHCP完全無効化**
- ルータ管理画面でDHCP機能を無効化
- すべてのデバイスを静的IPに変更

### 問題2: PXEブートメニューが表示されない

**原因**: TFTPファイルの配置ミス

**対処**:
```bash
# DRBLの自動設定を実行
sudo /opt/drbl/sbin/drblsrv -i

# クライアント設定
sudo /opt/drbl/sbin/drblpush -i
```

---

## 💡 代替案: dnsmasqによるDHCP/TFTP統合サーバ

ルータのDHCPと競合させたくない場合、**dnsmasq**による統合サーバも検討できます。

### dnsmasqのメリット

- ✅ DHCP + TFTP + DNSを1つのデーモンで提供
- ✅ 設定がシンプル
- ✅ 軽量・高速

### dnsmasqインストール

```bash
sudo apt install dnsmasq

# 設定ファイル
sudo nano /etc/dnsmasq.conf
```

**設定例**:
```conf
# DHCP設定
interface=ens33
dhcp-range=192.168.3.100,192.168.3.200,12h
dhcp-option=3,192.168.3.1  # ゲートウェイ（ルータ）
dhcp-option=6,192.168.3.1  # DNS（ルータ）

# PXEブート設定
dhcp-boot=pxelinux.0,drbl-server,192.168.3.135
enable-tftp
tftp-root=/tftpboot
```

---

## 📊 ネットワーク診断コマンド

### Ubuntu DRBLサーバで実行

```bash
# ネットワークインターフェース確認
ip addr show

# ルーティングテーブル確認
ip route show

# DNSサーバ確認
cat /etc/resolv.conf

# ネットワーク疎通確認
ping -c 3 192.168.3.1  # ルータ
ping -c 3 192.168.3.139  # 展開対象PC

# DHCPリース確認
cat /var/lib/dhcp/dhcpd.leases

# TFTPサーバテスト
tftp 192.168.3.135
tftp> get pxelinux.0
```

---

## 🎯 推奨設定（自宅環境用）

### 最小構成

1. **ルータDHCP範囲**: 192.168.3.2 - 192.168.3.99
2. **DRBL DHCP範囲**: 192.168.3.100 - 192.168.3.200
3. **静的IP設定**:
   - DRBL: 192.168.3.135（固定）
   - Windows 11: 192.168.3.92（ルータDHCP範囲内）

### 検証手順

1. ホームルータのDHCP範囲を変更
2. Ubuntu DRBLサーバのDHCPを起動
3. 展開対象PC（192.168.3.139）でPXEブート試行
4. Clonezillaメニューが表示されることを確認

---

## 📞 サポート情報

### ルータ設定変更時の注意

⚠️ **重要**: ルータのDHCP設定変更後、以下のデバイスが一時的にネットワークから切断される可能性があります:
- スマートフォン
- IoTデバイス（スマート家電等）

**推奨時間帯**: 深夜・早朝（デバイス使用が少ない時間帯）

### バックアップ

ルータ設定変更前に、現在の設定をバックアップしてください（ルータ管理画面の「バックアップ/復元」機能）。

---

## 関連ドキュメント

- [DRBL_Clonezillaサーバ構築手順.md](./DRBL_Clonezillaサーバ構築手順.md)
- [PXEブート環境構築手順.md](./PXEブート環境構築手順.md)
- [ネットワーク構成手順.md](./ネットワーク構成手順.md)

---

**作成日**: 2025年11月17日
**作成者**: システム管理チーム

---

## 更新履歴

| 日付 | バージョン | 更新内容 |
|------|-----------|---------|
| 2025-11-19 | 1.1 | Docker干渉問題のトラブルシューティングを追加 |
| 2025-11-17 | 1.0 | 初版作成 |
