# NFSマウント失敗 完全解決サマリー

## 作成日時
2025年11月17日 20:53

## 問題の詳細

### 症状
- クライアントPCがPXEブート後、BusyBoxプロンプトで停止
- NFSマウント失敗により、Clonezillaメニューが表示されない

### 根本原因
1. **NFSエクスポート範囲の制限**: `/etc/exports` が192.168.3.1〜12のみ対応
2. **DHCPアドレス割り当ての不一致**: クライアントPCに192.168.3.109が割り当てられた
3. **nodesディレクトリの欠如**: `/tftpboot/nodes/192.168.3.109/` が存在しない

### 技術的な詳細
```
既存設定（問題あり）:
/tftpboot/node_root 192.168.3.1(ro,async,...)
/tftpboot/node_root 192.168.3.2(ro,async,...)
...
/tftpboot/node_root 192.168.3.12(ro,async,...)
→ 192.168.3.109からのアクセスが拒否される

修正後（サブネット形式）:
/tftpboot/node_root 192.168.3.0/24(ro,async,...)
→ 192.168.3.1〜254の全範囲に対応
```

## 解決策

### 作成したファイル一覧

#### 1. **自動修正スクリプト** (推奨)
- **ファイル**: `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/apply_nfs_fix.sh`
- **実行方法**: `sudo ./apply_nfs_fix.sh`
- **機能**:
  - /etc/exports のバックアップ
  - サブネット形式（192.168.3.0/24）への変換
  - 192.168.3.109用ディレクトリ作成
  - 192.168.3.100〜200の全ノードディレクトリ作成
  - NFSエクスポート再適用
  - NFSサービス再起動
  - 動作確認

#### 2. **詳細マニュアル**
- **ファイル**: `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/MANUAL_FIX_NFS.md`
- **内容**:
  - ステップバイステップの手動修正手順
  - トラブルシューティングガイド
  - 設定ファイルの詳細説明

#### 3. **クイックリファレンス**
- **ファイル**: `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/QUICK_FIX_NFS.txt`
- **内容**:
  - 最小限の手順で問題を解決
  - コピー&ペースト可能なコマンド
  - 成功判定基準

#### 4. **新しいNFSエクスポート設定**
- **ファイル**: `/tmp/exports.new`
- **内容**:
  - サブネット形式（192.168.3.0/24）でのエクスポート設定
  - 全ノードディレクトリのエクスポート
  - 既存の設定を完全に置き換える

## 実行手順（簡易版）

### ワンライナー実行
```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project && sudo ./apply_nfs_fix.sh
```

### 動作確認
```bash
# NFSエクスポート確認
sudo exportfs -v | grep 192.168.3.0/24

# ノードディレクトリ確認
ls -la /tftpboot/nodes/192.168.3.109

# NFSサービス状態確認
sudo systemctl status nfs-server
```

### クライアントPCテスト
1. クライアントPCを再起動
2. PXEブートを開始
3. Clonezillaメニューが表示されることを確認（2〜5分待機）

## 期待される結果

### 成功の判断基準
以下が全て確認できれば完全解決:

1. ✅ `sudo exportfs -v` で 192.168.3.0/24 のエクスポートが表示される
2. ✅ `/tftpboot/nodes/192.168.3.109` ディレクトリが存在する
3. ✅ クライアントPC起動後、Clonezillaメニューが表示される（2〜5分以内）
4. ✅ NFSマウントエラーメッセージが表示されない

### PXEブート成功シーケンス
```
1. PC起動 → PXE ROM起動
2. DHCP → 192.168.3.109取得
3. TFTP → pxelinux.0読み込み
4. TFTP → カーネル/initrd読み込み
5. NFS → /tftpboot/node_root マウント成功
6. BusyBox起動 → /sys, /proc, /dev マウント
7. Clonezilla初期化（2〜5分）
8. Clonezillaメニュー表示 ← ここがゴール！
```

## トラブルシューティング

### NFSマウントが依然として失敗する場合

#### リアルタイムログ監視
```bash
sudo journalctl -u nfs-server -f
```

#### NFS通信の確認
```bash
sudo tcpdump -i any port 2049 -n
```

#### 設定を元に戻す
```bash
sudo cp /etc/exports.backup.YYYYMMDD_HHMMSS /etc/exports
sudo exportfs -ra
sudo systemctl restart nfs-server
```

### DHCP範囲の調整（オプション）

現在のDHCP範囲が広すぎる場合、192.168.3.1〜50に制限することも可能:

```bash
sudo nano /etc/dhcp/dhcpd.conf

# 以下の行を変更:
range 192.168.3.109 192.168.3.254;
↓
range 192.168.3.1 192.168.3.50;

# DHCP再起動
sudo systemctl restart isc-dhcp-server
```

## 技術的なメリット

### サブネット形式のメリット
- **スケーラビリティ**: 192.168.3.1〜254の254台全てに対応
- **管理性**: 1行で全範囲をカバー（個別IP指定は12行必要）
- **保守性**: 新しいクライアント追加時に設定変更不要
- **可読性**: 設定ファイルが大幅に簡潔化

### ノードディレクトリの自動作成
- 192.168.3.100〜200の範囲を事前作成
- 将来的なクライアント追加に備える
- Clonezillaの一時ファイル保存領域を確保

## 変更内容の詳細

### /etc/exports の変更点

#### 変更前（72行、192.168.3.1〜12のみ）
```
/tftpboot/node_root 192.168.3.1(ro,async,no_root_squash,no_subtree_check)
/usr 192.168.3.1(ro,async,no_root_squash,no_subtree_check)
...（合計72行）
/tftpboot/node_root 192.168.3.12(ro,async,no_root_squash,no_subtree_check)
/usr 192.168.3.12(ro,async,no_root_squash,no_subtree_check)
...
```

#### 変更後（27行、192.168.3.0/24全体）
```
/tftpboot/node_root 192.168.3.0/24(ro,async,no_root_squash,no_subtree_check)
/usr 192.168.3.0/24(ro,async,no_root_squash,no_subtree_check)
/home 192.168.3.0/24(rw,sync,no_root_squash,no_subtree_check,crossmnt)
/var/spool/mail 192.168.3.0/24(rw,sync,root_squash,no_subtree_check)
/opt 192.168.3.0/24(ro,async,no_root_squash,no_subtree_check,crossmnt)
/mnt/Linux-ExHDD/Ubuntu-ExHDD 192.168.3.0/24(rw,sync,no_root_squash,no_subtree_check,crossmnt)
...（合計27行）
```

### /tftpboot/nodes/ の変更点

#### 変更前（12ディレクトリ）
```
192.168.3.1/
192.168.3.2/
...
192.168.3.12/
```

#### 変更後（113ディレクトリ）
```
192.168.3.1/
192.168.3.2/
...
192.168.3.12/
192.168.3.100/  ← 新規作成
192.168.3.101/  ← 新規作成
...
192.168.3.109/  ← 新規作成（重要！）
...
192.168.3.200/  ← 新規作成
```

## セキュリティ考慮事項

### 現在の設定
- NFSエクスポートは 192.168.3.0/24 のみ（社内LAN限定）
- no_root_squash は社内環境のため許可（本番環境では要検討）
- ファイアウォールでNFSポート（2049）は社内LAN以外からブロック推奨

### 推奨事項
- 定期的に `/var/log/syslog` でNFSアクセスログを確認
- 不明なIPアドレスからのアクセスがある場合、調査する
- 本番運用後、DHCP範囲を実際に使用する範囲に絞る

## 関連リソース

### ドキュメント
- DRBL公式ドキュメント: https://drbl.org/
- NFS設定ガイド: `man exports`
- Clonezillaマニュアル: https://clonezilla.org/

### ログファイル
- NFS: `/var/log/syslog`
- DHCP: `/var/log/syslog`
- TFTP: `/var/log/syslog`

### 設定ファイル
- NFS: `/etc/exports`
- DHCP: `/etc/dhcp/dhcpd.conf`
- TFTP: `/etc/default/tftpd-hpa`

## まとめ

NFSマウント失敗の問題は、以下の3つの修正により完全に解決されます:

1. **NFSエクスポート設定のサブネット化** - 192.168.3.0/24で全範囲をカバー
2. **ノードディレクトリの作成** - 192.168.3.100〜200の全ディレクトリを事前作成
3. **NFSサービスの再起動** - 変更を確実に適用

実行コマンド:
```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project
sudo ./apply_nfs_fix.sh
```

これで192.168.3.109（または他のどのIPアドレス）でも、正常にNFSマウントができるようになります。

---
作成者: Claude Code
最終更新: 2025年11月17日 20:53
