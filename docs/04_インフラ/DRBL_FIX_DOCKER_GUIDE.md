# DRBL Docker問題修正ガイド

**最終更新**: 2025-11-19
**対象**: Docker干渉によるDRBL設定エラーの修正

---

## 🔴 問題の概要

**症状**:
- `drblpush -i` 実行時に `docker0` インターフェース（172.17.0.1）が検出される
- `/tftpboot/nbi_img/` ディレクトリが存在せず、PXELinux設定に失敗
- カーネル検出エラー: `Unable to find kernel for client!!!`
- dnsmasqサービス起動失敗

**原因**:
- Dockerサービスが `docker0` 仮想ネットワークインターフェースを作成
- DRBLがこれをDRBL環境用NICとして誤認識
- 本来の物理NIC（`enp2s0`）との設定が混乱

---

## ✅ 修正手順

### ステップ1: 修正スクリプトを実行

```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project
sudo ./fix_drbl_docker_issue.sh
```

**パスワード**: ELzion1969

**スクリプトの実行内容**:
1. ✅ Dockerサービスを停止・無効化
2. ✅ docker0インターフェースを無効化
3. ✅ `/tftpboot/nbi_img/` ディレクトリを作成
4. ✅ DRBL設定ファイルを修正（enp2s0明示指定）
5. ✅ 既存のDRBL設定をクリーンアップ
6. ✅ ネットワーク設定を確認

---

### ステップ2: DRBLサーバを初期化

```bash
sudo /usr/sbin/drblsrv -i
```

**対話モード**: すべて **デフォルト値でEnterキー** でOK

**所要時間**: 約3-5分

---

### ステップ3: DRBL環境を設定

```bash
sudo /usr/sbin/drblpush -i
```

**重要な選択肢**:

| 質問 | 選択 | 理由 |
|------|------|------|
| **ドメイン名** | `drbl.org` | デフォルトでOK |
| **NIS/YPドメイン名** | `penguinzilla` | デフォルトでOK |
| **ホスト名プレフィックス** | `kensan196948G` | 任意の名前 |
| **パブリックIP用NIC** | `enp2s0` | **重要: docker0は選択しない** |
| **MAC収集** | `N` (No) | 不要 |
| **固定IP** | `N` (No) | DHCPで自動割り当て |
| **クライアントIP開始番号** | `1` | デフォルトでOK |
| **クライアント数** | `1` | 最小構成（テスト用） |
| **ディスクレスLinux** | `[2]` 提供しない | **重要** |
| **Clonezilla** | `[3]` Clonezilla Liveを使用 | **重要** |
| **Clonezillaブランチ** | `[2]` 別の安定版 (Ubuntu) | 推奨 |
| **イメージ保存先** | `/opt/clonezilla-images` | デフォルトでOK |
| **PXEパスワード** | `N` (No) | パスワードなし |
| **起動プロンプト** | `Y` (Yes) | デフォルトでOK |
| **プロンプトタイムアウト** | `70` (7.0秒) | デフォルトでOK |
| **グラフィカルPXE** | `N` (No) | テキストメニュー使用 |
| **NATサーバ** | `Y` (Yes) | インターネット接続用 |
| **既存設定保持** | `n` (No) | クリーンインストール |

**所要時間**: 約10-15分（Clonezilla Live ISOダウンロード含む）

---

### ステップ4: 動作確認

```bash
# サービス状態確認
sudo systemctl status isc-dhcp-server
sudo systemctl status tftpd-hpa
sudo systemctl status nfs-server
sudo systemctl status dnsmasq

# ネットワーク確認
ip addr show enp2s0
ip addr show docker0  # docker0が存在しないことを確認

# TFTP確認
ls -la /tftpboot/nbi_img/

# PXELinux設定確認
cat /tftpboot/nbi_img/pxelinux.cfg/default

# Clonezilla Live確認
ls -la /tftpboot/node_root/clonezilla-live/
```

---

## 🔍 トラブルシューティング

### docker0が再び出現する場合

```bash
# Dockerサービスが自動起動している
sudo systemctl stop docker
sudo systemctl disable docker

# docker0を強制削除
sudo ip link delete docker0
```

### dnsmasq起動失敗

```bash
# 設定確認
sudo systemctl status dnsmasq -l

# ログ確認
sudo journalctl -u dnsmasq -n 50

# ポート競合確認
sudo netstat -tulpn | grep :53
sudo netstat -tulpn | grep :67

# systemd-resolvedと競合している場合
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
```

### カーネル検出エラー

```bash
# カーネルイメージを確認
ls -la /boot/vmlinuz-*

# drblsrv -i を再実行
sudo /usr/sbin/drblsrv -i
```

### NFS起動失敗

```bash
# NFS設定確認
cat /etc/exports

# NFSサービス再起動
sudo systemctl restart nfs-kernel-server
sudo systemctl status nfs-kernel-server

# マウント確認
sudo showmount -e localhost
```

---

## 📋 チェックリスト

設定完了後、以下を確認してください：

- [ ] Dockerサービスが停止・無効化されている
- [ ] `ip addr` でdocker0が表示されない
- [ ] `/tftpboot/nbi_img/` ディレクトリが存在する
- [ ] `/tftpboot/nbi_img/pxelinux.cfg/default` ファイルが存在する
- [ ] `/tftpboot/node_root/clonezilla-live/filesystem.squashfs` が存在する
- [ ] DHCPサーバ（isc-dhcp-server）が起動している
- [ ] TFTPサーバ（tftpd-hpa）が起動している
- [ ] NFSサーバ（nfs-kernel-server）が起動している
- [ ] dnsmasqが起動している（またはプロキシDHCP無効）

---

## 🚀 次のステップ

修正完了後、以下のガイドに従ってPXEブート環境をテストしてください：

1. **START_HERE.md** - クイックスタートガイド
2. **docs/04_インフラ/自宅環境PXEブート構築ガイド.md** - 詳細手順

---

## 📞 問題が解決しない場合

以下の情報を収集してください：

```bash
# システム情報
sudo /usr/sbin/drbl-bug-report

# ログファイル
sudo journalctl -u isc-dhcp-server -n 100 > dhcp.log
sudo journalctl -u dnsmasq -n 100 > dnsmasq.log
sudo journalctl -u nfs-server -n 100 > nfs.log

# ネットワーク設定
ip addr > network.log
ip route >> network.log
cat /etc/exports >> network.log
```

---

**修正スクリプト作成日**: 2025-11-19
**対象環境**: Ubuntu 22.04 LTS + DRBL + Clonezilla
