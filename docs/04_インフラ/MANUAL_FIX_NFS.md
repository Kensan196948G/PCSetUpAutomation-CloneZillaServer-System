# NFSマウント失敗 完全解決マニュアル

## 問題の原因
- 現在のNFSエクスポート設定が192.168.3.1〜12のみ対応
- クライアントPCに192.168.3.109が割り当てられたが、NFSアクセスが拒否されている
- 192.168.3.109用のnodesディレクトリが存在しない

## 解決手順

### ステップ1: 既存設定のバックアップ
```bash
sudo cp /etc/exports /etc/exports.backup.$(date +%Y%m%d_%H%M%S)
```

### ステップ2: 新しい設定の適用
```bash
# 新しい設定ファイルを適用
sudo cp /tmp/exports.new /etc/exports

# 適用後の内容確認
cat /etc/exports
```

### ステップ3: 必要なnodesディレクトリを作成
```bash
# 192.168.3.109用ディレクトリ作成
sudo mkdir -p /tftpboot/nodes/192.168.3.109

# 既存ディレクトリをコピーして構造を再現
sudo cp -a /tftpboot/nodes/192.168.3.1/* /tftpboot/nodes/192.168.3.109/

# パーミッション設定
sudo chmod 755 /tftpboot/nodes/192.168.3.109
sudo chown -R root:root /tftpboot/nodes/192.168.3.109

# 確認
ls -la /tftpboot/nodes/192.168.3.109
```

### ステップ4: 追加のIPアドレス用ディレクトリ作成（オプション）
将来的に192.168.3.100〜200の範囲でIPが割り当てられる可能性があるため、先に作成しておく：

```bash
# 100〜200の範囲でディレクトリ作成
for i in {100..200}; do
    if [ ! -d /tftpboot/nodes/192.168.3.$i ]; then
        sudo mkdir -p /tftpboot/nodes/192.168.3.$i
        sudo cp -a /tftpboot/nodes/192.168.3.1/* /tftpboot/nodes/192.168.3.$i/ 2>/dev/null || true
        sudo chmod 755 /tftpboot/nodes/192.168.3.$i
    fi
done

# 作成数確認
ls -d /tftpboot/nodes/192.168.3.* | wc -l
```

### ステップ5: NFSサービスの再エクスポート
```bash
# NFSエクスポートテーブルを再読み込み
sudo exportfs -ra

# エクスポート状況確認
sudo exportfs -v | grep 192.168.3.0/24
```

### ステップ6: NFSサービスの再起動
```bash
# NFSサーバー再起動
sudo systemctl restart nfs-server
sudo systemctl restart nfs-kernel-server

# サービス状態確認
sudo systemctl status nfs-server --no-pager
```

### ステップ7: 最終確認
```bash
# NFSエクスポートが正しく設定されているか確認
sudo exportfs -v

# 期待される出力例:
# /tftpboot/node_root
#         192.168.3.0/24(ro,async,wdelay,no_root_squash,no_subtree_check,...)
# /usr    192.168.3.0/24(ro,async,wdelay,no_root_squash,no_subtree_check,...)
# ...
```

### ステップ8: クライアントPCでテスト
1. クライアントPCを再起動
2. PXEブートを開始
3. 以下の順序で進行することを確認:
   - DHCP成功（192.168.3.109取得）
   - TFTPでブートイメージ取得
   - NFSマウント成功（/sys, /proc, /dev のマウント）
   - BusyBoxプロンプト表示後、Clonezillaメニュー起動（2〜5分待機）

## トラブルシューティング

### NFSマウントが依然として失敗する場合
```bash
# NFSサーバー側でログ確認
sudo journalctl -u nfs-server -f

# リアルタイムでNFSアクセス状況を確認
sudo tcpdump -i any port 2049 -n
```

### /etc/exportsの構文エラーがある場合
```bash
# 構文チェック
sudo exportfs -ra

# エラーが出た場合、バックアップから復元
sudo cp /etc/exports.backup.YYYYMMDD_HHMMSS /etc/exports
sudo exportfs -ra
```

## 成功の判断基準

以下が全て達成されればNFSマウント問題は解決:
1. `sudo exportfs -v` で 192.168.3.0/24 のエクスポートが表示される
2. `/tftpboot/nodes/192.168.3.109` ディレクトリが存在する
3. クライアントPC起動後、Clonezillaメニューが表示される（2〜5分以内）
4. NFSマウントエラーメッセージが表示されない

## 設定ファイルの場所

- 新しいNFSエクスポート設定: `/tmp/exports.new`
- 既存のNFSエクスポート設定: `/etc/exports`
- バックアップ: `/etc/exports.backup.YYYYMMDD_HHMMSS`
- nodesディレクトリ: `/tftpboot/nodes/`

## 補足説明

### サブネット形式のメリット
- 個別IP指定: 各IPごとに行を追加する必要がある（管理が煩雑）
- サブネット形式: 192.168.3.0/24 で 192.168.3.1〜254 全てをカバー（管理が簡単）

### Per-nodeディレクトリの役割
- Clonezillaがクライアントごとの一時ファイルを保存する場所
- 各クライアントIPに対応するディレクトリが必要
- 存在しない場合、NFSマウント後にエラーが発生する可能性がある
