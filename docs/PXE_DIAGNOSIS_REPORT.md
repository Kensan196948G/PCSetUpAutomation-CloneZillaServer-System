# PXEブート環境診断レポート

## 診断日時
2025-11-17 20:10 JST

## 発見された問題（優先度順）

### 1. [CRITICAL] TFTP Root Directory Mismatch - THE ROOT CAUSE
**問題**: DHCPが指示するファイルパスとTFTPサーバのルートディレクトリが不整合

**詳細**:
- DHCP設定 (`/etc/dhcp/dhcpd.conf`):
  - `filename "pxelinux.0";` → クライアントは `/pxelinux.0` を要求
  - `next-server 192.168.3.135;` → TFTP サーバアドレス正常

- TFTP設定 (`/etc/default/tftpd-hpa`):
  - `TFTP_DIRECTORY="/tftpboot"` → ルートは `/tftpboot`

- 実際のTFTPプロセス:
  - **`/usr/sbin/in.tftpd --listen --user tftp --address 0.0.0.0:69 /tftpboot/nbi_img`**
  - **ルートは `/tftpboot/nbi_img` に設定されている！**

**問題の流れ**:
1. クライアントがDHCPから `filename "pxelinux.0"` を受信
2. クライアントがTFTP要求: `GET /pxelinux.0`
3. TFTPサーバは `/tftpboot/nbi_img/pxelinux.0` を探す → **存在する**
4. しかし、`/etc/default/tftpd-hpa` は `/tftpboot` と指定
5. 実際のプロセスは `/tftpboot/nbi_img` を使用（DRBLが手動起動？）

**なぜTFTPログがないのか**:
- DHCPログで192.168.3.100（pool range内）割り当て成功
- しかし、**クライアントがTFTP要求を送信していない**
- 理由: クライアントのPXE ROMが次-serverからのファイル取得に失敗し、即座に諦めている可能性

### 2. [HIGH] TFTP Service Status - 表面的な問題
**問題**: `systemctl status tftpd-hpa.service` が FAILED

**詳細**:
```
× tftpd-hpa.service - LSB: HPA's tftp server
     Active: failed (Result: exit-code) since Mon 2025-11-17 18:00:14
```

**しかし実際には**:
- TFTPプロセスは起動中: `PID 117668`
- ポート69でリスニング中: `udp 0.0.0.0:69`
- DRBLが独自に起動したと推測

### 3. [MEDIUM] DHCP Configuration Inconsistency
**問題**: `/etc/dhcp/dhcpd.conf` と `/etc/default/tftpd-hpa` の不整合

**詳細**:
- DHCP: `filename "pxelinux.0";` (ルートからの相対パス)
- TFTP config: `TFTP_DIRECTORY="/tftpboot"`
- 実際のプロセス: `/tftpboot/nbi_img`

### 4. [LOW] Multiple DHCP Offers
**問題**: クライアントが2つのDHCP OFFERを受信

**ログ例**:
```
19:58:00 DHCPOFFER on 192.168.3.2 to ec:b1:d7:72:e8:38 via drbl0
20:01:33 DHCPOFFER on 192.168.3.100 to ec:b1:d7:72:e8:38 via enp2s0
```

**影響**: クライアントは192.168.3.100を選択（pool range内）しているが、本来は192.168.3.2に固定すべき

## 現在の環境状態

### ネットワーク構成
- ホームルータ: 192.168.3.1 (DHCP: 有効、範囲不明)
- Ubuntu DRBLサーバ:
  - enp2s0: 192.168.3.135
  - drbl0: 192.168.3.251 (仮想IF)
- 展開対象PC:
  - MAC: ec:b1:d7:72:e8:38
  - 割り当てIP: 192.168.3.100 (最近) または 192.168.3.2 (過去成功時)

### サービス状態
- ✅ DHCP: 起動中 (PID 118833, 両IFリスニング)
- ✅ TFTP: 実質起動中 (PID 117668, port 69リスニング)
  - ただし systemctl では FAILED
  - ルート: `/tftpboot/nbi_img`
- ✅ NFS: 起動中 (8プロセス)

### ファイル配置状態
- ✅ `/tftpboot/pxelinux.0` → symlink to `/tftpboot/nbi_img/pxelinux.0`
- ✅ `/tftpboot/nbi_img/pxelinux.0` → 実ファイル (42,392 bytes)
- ✅ `/tftpboot/nbi_img/pxelinux.cfg/default` → 実ファイル (6,276 bytes)
- ✅ `/tftpboot/nbi_img/vmlinuz-pxe` → symlink (likely)
- ✅ `/tftpboot/nbi_img/initrd-pxe.img` → symlink to initrd-pxe.6.8.0-87-generic.img

### 過去の成功時との差分
**成功時 (BusyBox起動まで到達)**:
- DHCP割り当て: 192.168.3.2 (drbl0経由)
- TFTP要求: あり（ログに記録されていた可能性）
- NFSマウント: 試行まで到達

**現在 (失敗)**:
- DHCP割り当て: 192.168.3.100 (enp2s0経由、pool range)
- TFTP要求: **一切なし**
- クライアント動作: "PXE-M0F Exiting Intel Boot Agent" → ローカルディスク起動

## 根本原因の推定

**最も可能性が高い原因**:
1. **TFTPルートディレクトリの不整合により、クライアントがファイルを取得できない**
2. クライアントのPXE ROMがTFTP失敗後、即座にローカルブート(M0F)にフォールバック
3. TFTP要求すら発生しないため、ログに痕跡が残らない

**なぜ過去に成功したのか**:
- 過去のセットアップ時、TFTP rootが `/tftpboot` に正しく設定されていた
- または、DHCP設定で `filename "nbi_img/pxelinux.0";` と指定されていた可能性

## 修正方針

### 最優先: TFTP設定の統一

**オプション1 (推奨): TFTP rootを `/tftpboot` に戻す**
- `/etc/default/tftpd-hpa` で `TFTP_DIRECTORY="/tftpboot"`
- DHCP設定で `filename "nbi_img/pxelinux.0";` に変更
- または symlink `/tftpboot/pxelinux.0` を活用（既に存在）

**オプション2: DHCP設定を現行TFTP rootに合わせる**
- DHCP設定で `filename "pxelinux.0";` のまま
- `/etc/default/tftpd-hpa` で `TFTP_DIRECTORY="/tftpboot/nbi_img"`
- 既に実プロセスがこの設定で動作中

### 副次的修正

1. **TFTP serviceの修復**:
   - 現在は手動起動プロセスが動作中
   - systemctl経由で正常に起動するよう修正

2. **DHCP host宣言の追加**:
   - クライアントMAC (ec:b1:d7:72:e8:38) を固定IP (192.168.3.2) に紐付け
   - pool rangeからの割り当てを回避

3. **ホームルータDHCPとの競合回避**:
   - ルータDHCP範囲を192.168.3.100以降に限定
   - または、DRBLサーバを優先させるためルータDHCPを無効化

## 期待される結果

修正後の動作:
1. クライアント起動 → PXEブート開始
2. DHCP Discover → DRBL DHCPサーバから 192.168.3.2 取得
3. TFTP要求: `RRQ from 192.168.3.2 filename pxelinux.0`
4. TFTPサーバ: `/tftpboot/nbi_img/pxelinux.0` を返送 (または `/tftpboot/pxelinux.0` symlink経由)
5. クライアント画面: "PXELINUX 6.03 ..." 表示
6. pxelinux.cfg/default メニュー表示
7. Clonezilla起動

## 追加検証項目

1. **ホームルータDHCP範囲の確認**:
   ```bash
   # ルータ管理画面で確認
   ```

2. **TFTP要求の手動テスト**:
   ```bash
   tftp 192.168.3.135 -c get pxelinux.0
   tftp 192.168.3.135 -c get nbi_img/pxelinux.0
   ```

3. **tcpdumpでTFTPパケット監視**:
   ```bash
   sudo tcpdump -i enp2s0 -n port 69 -vv
   ```

## 参考情報

- Client MAC: ec:b1:d7:72:e8:38
- PXE Architecture: 00000 (Legacy BIOS)
- DHCP Vendor ID: "PXEClient:Arch:00000:UNDI:002001"
- 成功時IP: 192.168.3.2 (drbl0経由)
- 失敗時IP: 192.168.3.100 (enp2s0経由)
