# DRBL トラブルシューティング

## Docker干渉問題の修正（2025-11-19）

### 問題
- `drblpush -i` 実行時にdocker0インターフェース（172.17.0.1）が検出される
- `/tftpboot/nbi_img/` ディレクトリ不在
- カーネル検出エラー
- dnsmasqサービス起動失敗

### 原因
Dockerサービスがdocker0仮想NICを作成し、DRBLがこれをDRBL環境用として誤認識

### 解決方法

#### 1. 修正スクリプト実行
```bash
sudo ./fix_drbl_docker_issue.sh
```

#### 2. DRBLサーバ初期化
```bash
sudo /usr/sbin/drblsrv -i
```

#### 3. DRBL環境設定
```bash
sudo /usr/sbin/drblpush -i
```

**重要な選択**:
- パブリックIP用NIC: `enp2s0` （docker0は選択しない）
- ディスクレスLinux: `[2]` 提供しない
- Clonezilla: `[3]` Clonezilla Liveを使用
- Clonezillaブランチ: `[2]` 別の安定版 (Ubuntu)

### 確認コマンド
```bash
# docker0不在確認
ip addr show docker0  # エラーになればOK

# TFTP確認
ls -la /tftpboot/nbi_img/pxelinux.cfg/default

# サービス確認
sudo systemctl status isc-dhcp-server
sudo systemctl status tftpd-hpa
sudo systemctl status nfs-server
```

### ファイル
- 修正スクリプト: `fix_drbl_docker_issue.sh`
- ガイド: `DRBL_FIX_DOCKER_GUIDE.md`
- 設定ファイル: `configs/drblpush_auto_config.conf`
