# トラブルシューティングガイド

PCキッティング自動化システムで発生する可能性のある問題と解決方法をまとめています。

## 目次

1. [PXEブート関連](#pxeブート関連)
2. [DHCP関連](#dhcp関連)
3. [TFTP関連](#tftp関連)
4. [イメージ作成・復元関連](#イメージ作成復元関連)
5. [ネットワークパフォーマンス](#ネットワークパフォーマンス)
6. [ディスク関連](#ディスク関連)
7. [システム全般](#システム全般)

---

## PXEブート関連

### 問題: PXEブートが開始されない

**症状:**
```
PXE-E51: No DHCP or proxyDHCP offers were received
```

**原因と対処法:**

1. **DHCPサーバーが起動していない**
   ```bash
   # DHCPサービス状態確認
   sudo systemctl status dnsmasq
   
   # 起動していない場合
   sudo systemctl start dnsmasq
   sudo systemctl enable dnsmasq
   ```

2. **ネットワーク接続の問題**
   ```bash
   # リンク状態確認
   ip link show enp0s3
   
   # スイッチのリンクLEDが点灯しているか確認
   # ケーブルを交換してみる
   ```

3. **BIOS設定の問題**
   ```
   - PXE Bootが有効になっているか確認
   - Network Bootの優先順位を最上位に設定
   - Legacy Boot / UEFI Bootの設定確認
   ```

4. **ファイアウォールの問題**
   ```bash
   # ポート67(DHCP)が開いているか確認
   sudo ufw status | grep 67
   
   # 開いていない場合
   sudo ufw allow 67/udp
   ```

---

### 問題: PXEブートは開始するがClonezillaが起動しない

**症状:**
```
TFTP timeout
PXE-E32: TFTP open timeout
```

**原因と対処法:**

1. **TFTPサーバーが起動していない**
   ```bash
   # TFTPポート確認
   sudo netstat -ulnp | grep :69
   
   # 何も表示されない場合、dnsmasqを再起動
   sudo systemctl restart dnsmasq
   ```

2. **TFTPルートディレクトリの問題**
   ```bash
   # TFTPルートディレクトリの確認
   ls -la /tftpboot/
   
   # pxelinux.0が存在するか確認
   ls -la /tftpboot/pxelinux.0
   
   # ない場合、drblpushを再実行
   sudo /usr/sbin/drblpush -i
   ```

3. **ファイアウォールの問題**
   ```bash
   # ポート69(TFTP)が開いているか確認
   sudo ufw status | grep 69
   
   # 開いていない場合
   sudo ufw allow 69/udp
   ```

---

## DHCP関連

### 問題: DHCPでIPアドレスが取得できない

**診断コマンド:**
```bash
# DHCPリース確認
cat /var/lib/misc/dnsmasq.leases

# DHCPログ確認
journalctl -u dnsmasq -n 50

# リアルタイムログ確認
sudo tail -f /var/log/syslog | grep dnsmasq
```

**対処法:**

1. **DHCPレンジの枯渇**
   ```bash
   # リース数確認
   wc -l /var/lib/misc/dnsmasq.leases
   
   # 設定されているレンジ確認
   grep "dhcp-range" /etc/dnsmasq.d/*.conf
   
   # レンジを拡大する場合
   sudo nano /etc/dnsmasq.d/drbl-dhcp.conf
   # dhcp-range=192.168.100.10,192.168.100.150,12h
   
   sudo systemctl restart dnsmasq
   ```

2. **他のDHCPサーバーとの競合**
   ```bash
   # ネットワーク上のDHCPサーバーを検出
   sudo nmap --script broadcast-dhcp-discover
   
   # 競合している場合、ネットワークを分離する必要あり
   ```

3. **dnsmasq設定の問題**
   ```bash
   # 設定ファイルの構文チェック
   sudo dnsmasq --test
   
   # エラーがある場合、設定ファイルを確認
   sudo nano /etc/dnsmasq.d/drbl-dhcp.conf
   ```

---

## TFTP関連

### 問題: TFTPでファイル転送が失敗する

**診断コマンド:**
```bash
# TFTPサーバーのテスト
tftp localhost
> get pxelinux.0
> quit

# 成功すれば、ローカルにpxelinux.0がダウンロードされる
ls -lh pxelinux.0
```

**対処法:**

1. **パーミッションの問題**
   ```bash
   # TFTPルートディレクトリのパーミッション確認
   ls -la /tftpboot/
   
   # 読み取り権限がない場合
   sudo chmod -R 755 /tftpboot/
   ```

2. **SELinuxの問題（CentOSなど）**
   ```bash
   # SELinuxステータス確認
   getenforce
   
   # Enforcingの場合、Permissiveに変更してテスト
   sudo setenforce 0
   ```

---

## イメージ作成・復元関連

### 問題: イメージ作成時に容量不足エラー

**症状:**
```
No space left on device
```

**診断コマンド:**
```bash
# ディスク使用状況確認
df -h /home/partimag

# イメージディレクトリの内容確認
du -sh /home/partimag/*
```

**対処法:**

1. **古いイメージの削除**
   ```bash
   # イメージ一覧確認
   ./scripts/04-list-images.sh
   
   # 古いイメージを削除（注意: 削除前にバックアップ推奨）
   sudo rm -rf /home/partimag/old-image-name
   ```

2. **圧縮率の向上**
   ```bash
   # より高圧縮のオプションを使用
   # z9p (最高圧縮, 遅い) 代わりに z1p (低圧縮, 速い) を使用
   
   # イメージ作成時に指定
   sudo ./scripts/02-create-image.sh win11-base z9p
   ```

3. **外部ストレージの追加**
   ```bash
   # 外部ディスクをマウント
   sudo mkdir -p /mnt/images
   sudo mount /dev/sdb1 /mnt/images
   
   # シンボリックリンク作成
   sudo ln -s /mnt/images /home/partimag/external
   ```

---

### 問題: イメージ復元時にパーティションエラー

**症状:**
```
Partition table not found
Target disk is too small
```

**原因と対処法:**

1. **ターゲットディスクが小さい**
   ```bash
   # イメージ情報確認
   cat /home/partimag/<イメージ名>/disk
   
   # ターゲットディスクはマスターディスクと同じか、それ以上のサイズが必要
   ```

2. **イメージファイルの破損**
   ```bash
   # イメージの整合性確認
   cd /home/partimag/<イメージ名>/
   
   # 必須ファイルの存在確認
   ls -lh disk parts *.gz
   
   # ファイルサイズが0でないか確認
   find . -type f -size 0
   
   # 破損している場合、イメージを再作成
   ```

3. **互換性の問題（GPT vs MBR）**
   ```bash
   # パーティションタイプ確認
   cat /home/partimag/<イメージ名>/parts
   
   # GPTとMBRの混在は通常サポートされない
   # 同じパーティションタイプのディスクを使用
   ```

---

### 問題: マルチキャスト展開でクライアントが待機状態のまま

**症状:**
- 一部のクライアントがイメージ受信を開始しない
- "Waiting for other clients..." のまま進まない

**診断:**
```bash
# Clonezillaログ確認
sudo tail -f /var/log/clonezilla/clonezilla-*.log

# ネットワークトラフィック確認
sudo tcpdump -i enp0s3 multicast
```

**対処法:**

1. **マルチキャストルーティングの問題**
   ```bash
   # マルチキャストルート確認
   ip mroute show
   
   # マルチキャストを有効化
   sudo sysctl -w net.ipv4.ip_forward=1
   ```

2. **スイッチのIGMP Snooping設定**
   ```
   スイッチの管理画面で以下を確認:
   - IGMP Snoopingが有効か
   - マルチキャストフラッディングが適切に設定されているか
   
   問題が続く場合、一時的にユニキャストで展開
   ```

3. **クライアント台数の調整**
   ```bash
   # 台数を減らして再試行
   sudo ./scripts/03-deploy-multicast.sh <イメージ名> 10 600
   
   # 複数バッチに分けて展開
   ```

---

## ネットワークパフォーマンス

### 問題: 展開速度が非常に遅い（100Mbps未満）

**診断コマンド:**
```bash
# リンク速度確認
ethtool enp0s3 | grep Speed

# ネットワーク使用状況確認
sudo iftop -i enp0s3

# マルチキャストトラフィック確認
sudo tcpdump -i enp0s3 -n multicast | head -20
```

**対処法:**

1. **リンク速度が100Mbpsに制限されている**
   ```bash
   # 現在の速度確認
   ethtool enp0s3
   
   # 1000Mbps (Gigabit) でないことを確認した場合:
   # - ケーブルをCat5e以上に交換
   # - スイッチポートがGigabitに対応しているか確認
   # - NICドライバーを更新
   ```

2. **スイッチの帯域不足**
   ```bash
   # 同時展開台数を減らす
   sudo ./scripts/03-deploy-multicast.sh <イメージ名> 20 600
   
   # バックプレーン帯域が不足している可能性
   # より高性能なスイッチへのアップグレードを検討
   ```

3. **サーバーのディスクI/O遅延**
   ```bash
   # ディスクI/O確認
   sudo iostat -x 1
   
   # %util が 90% 以上の場合、ディスクがボトルネック
   # SSDへの移行を検討
   ```

4. **MTU設定の最適化**
   ```bash
   # 現在のMTU確認
   ip link show enp0s3
   
   # Jumbo Frame対応スイッチの場合、MTUを9000に設定
   sudo ip link set enp0s3 mtu 9000
   
   # 恒久的な設定
   sudo nano /etc/netplan/00-installer-config.yaml
   # mtu: 9000 を追加
   sudo netplan apply
   ```

---

## ディスク関連

### 問題: ディスク不良によるエラー

**症状:**
```
I/O error
Read error at sector XXXXX
```

**診断コマンド:**
```bash
# ディスクヘルス確認（サーバー側）
sudo smartctl -H /dev/sda
sudo smartctl -a /dev/sda

# ディスクエラーログ確認
sudo dmesg | grep -i "error\|fail"
```

**対処法:**

1. **サーバー側ディスクの問題**
   ```bash
   # S.M.A.R.T.テスト実行
   sudo smartctl -t short /dev/sda
   
   # テスト結果確認（5分後）
   sudo smartctl -a /dev/sda
   
   # エラーが多い場合、ディスク交換を検討
   ```

2. **クライアント側ディスクの問題**
   ```
   - 該当PCのディスクを交換
   - または、Clonezillaの-rescue オプションを使用
   ```

---

## システム全般

### 問題: サービスが起動時に自動起動しない

**診断:**
```bash
# 自動起動設定確認
systemctl is-enabled nfs-kernel-server
systemctl is-enabled dnsmasq

# 起動失敗ログ確認
journalctl -xe
```

**対処法:**
```bash
# 自動起動を有効化
sudo systemctl enable nfs-kernel-server
sudo systemctl enable dnsmasq

# 起動順序の問題がある場合
sudo systemctl edit dnsmasq
# [Unit]
# After=network-online.target
# Wants=network-online.target
```

---

### 問題: メモリ不足

**症状:**
```
Cannot allocate memory
Out of memory
```

**診断:**
```bash
# メモリ使用状況確認
free -h

# プロセス別メモリ使用量
ps aux --sort=-%mem | head -20
```

**対処法:**

1. **スワップ領域の追加**
   ```bash
   # 現在のスワップ確認
   swapon --show
   
   # スワップファイル作成（8GB）
   sudo fallocate -l 8G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   
   # 恒久的な設定
   echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
   ```

2. **メモリの増設**
   ```
   物理メモリを16GB以上に増設することを推奨
   ```

---

### 問題: 時刻同期の問題

**症状:**
- ログのタイムスタンプがずれている
- 認証エラーが発生する

**対処法:**
```bash
# NTPサービス確認
timedatectl status

# NTPを有効化
sudo timedatectl set-ntp true

# 時刻同期確認
sudo systemctl status systemd-timesyncd

# 手動で時刻同期
sudo ntpdate -u ntp.nict.jp
```

---

## 緊急時の対処

### 完全リセット手順

すべてがうまくいかない場合の最終手段:

```bash
# 1. すべてのサービスを停止
sudo systemctl stop dnsmasq
sudo systemctl stop nfs-kernel-server

# 2. 設定ファイルのバックアップ
sudo tar czf ~/drbl-backup-$(date +%Y%m%d).tar.gz \
  /etc/drbl/ /etc/dnsmasq.d/ /etc/exports

# 3. DRBLの再設定
sudo /usr/sbin/drblsrv -i
sudo /usr/sbin/drblpush -i

# 4. サービスの再起動
sudo systemctl restart nfs-kernel-server
sudo systemctl restart dnsmasq

# 5. 動作確認
./scripts/05-check-status.sh
```

---

## ログファイル一覧

トラブルシューティング時に確認すべきログ:

```bash
# システムログ
/var/log/syslog

# Clonezillaログ
/var/log/clonezilla/

# DRBLログ
/var/log/drbl/

# DHCPログ
journalctl -u dnsmasq

# NFSログ
journalctl -u nfs-kernel-server

# カーネルログ
dmesg

# 認証ログ
/var/log/auth.log
```

---

## サポート情報の収集

問題を報告する際に収集すべき情報:

```bash
# システム情報収集スクリプト
#!/bin/bash

echo "===== System Information =====" > ~/support-info.txt
uname -a >> ~/support-info.txt
cat /etc/os-release >> ~/support-info.txt

echo -e "\n===== Network Configuration =====" >> ~/support-info.txt
ip addr show >> ~/support-info.txt

echo -e "\n===== Service Status =====" >> ~/support-info.txt
systemctl status dnsmasq >> ~/support-info.txt
systemctl status nfs-kernel-server >> ~/support-info.txt

echo -e "\n===== DHCP Leases =====" >> ~/support-info.txt
cat /var/lib/misc/dnsmasq.leases >> ~/support-info.txt

echo -e "\n===== Disk Usage =====" >> ~/support-info.txt
df -h >> ~/support-info.txt

echo -e "\n===== Recent Errors =====" >> ~/support-info.txt
journalctl -p err -n 50 >> ~/support-info.txt

echo "Support information saved to ~/support-info.txt"
```

---

## 関連ドキュメント

- [README.md](../README.md) - システム概要
- [QUICK_START.md](./QUICK_START.md) - クイックスタート
- [WORKFLOWS.md](./WORKFLOWS.md) - 運用ワークフロー
