# PCマスターイメージ機能 クイックスタートガイド

## 概要

このガイドでは、PCマスターイメージの取り込み・展開機能を開発環境で素早く試す手順を説明します。

---

## 前提条件

- Python 3.8以上
- Flask アプリケーションが起動可能な状態
- (オプション) DRBLサーバが設定済み

---

## 1. 開発環境での起動

### 1.1 Flask アプリケーションの起動

```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/flask-app
python app.py
```

デフォルトでは `http://localhost:5000` でアクセス可能です。

### 1.2 初回セットアップ (データベース初期化)

アプリケーション起動時に自動的にデータベースが初期化されます。

---

## 2. テスト用イメージディレクトリの作成

DRBLサーバがない場合、テスト用のダミーイメージを作成できます。

### 2.1 イメージディレクトリの作成

```bash
# イメージホームディレクトリを作成
mkdir -p /tmp/partimag/test-win11-master-20251117

# 必須ファイルを作成 (Clonezillaイメージ形式)
cd /tmp/partimag/test-win11-master-20251117

# disk ファイル (ディスク名)
echo "sda" > disk

# parts ファイル (パーティション一覧)
echo "sda1 sda2 sda3" > parts

# dev-fs.list ファイル (ファイルシステム情報)
cat > dev-fs.list << 'EOF'
/dev/sda1 vfat
/dev/sda2 ntfs
/dev/sda3 ntfs
EOF

# clonezilla-img ファイル (メタデータ)
cat > clonezilla-img << 'EOF'
Clonezilla image version: 2.0
Created by: Clonezilla
Image name: test-win11-master-20251117
Created: 2025-11-17 12:00:00
EOF

# ダミーイメージファイルを作成 (サイズ確認用)
dd if=/dev/zero of=sda1.ntfs-ptcl-img.gz.aa bs=1M count=100
dd if=/dev/zero of=sda2.ntfs-ptcl-img.gz.aa bs=1M count=500
dd if=/dev/zero of=sda3.ntfs-ptcl-img.gz.aa bs=1M count=1000
```

### 2.2 Flaskアプリでカスタムパスを使用

`app.py` または環境変数で設定:

```python
# 開発環境用の設定
from utils.drbl_client import DRBLClient

drbl_client = DRBLClient(image_home='/tmp/partimag')
```

または環境変数:

```bash
export DRBL_IMAGE_HOME=/tmp/partimag
python app.py
```

---

## 3. 画面操作

### 3.1 イメージ管理画面へのアクセス

ブラウザで以下のURLにアクセス:

```
http://localhost:5000/deployment/images
```

### 3.2 イメージ一覧の確認

- テスト用イメージ `test-win11-master-20251117` が表示されることを確認
- サイズ、作成日時が正しく表示されることを確認

### 3.3 イメージのアップロードテスト

1. 「イメージアップロード」ボタンをクリック
2. モーダルが表示される
3. テスト用のtar.gzファイルを選択してアップロード

**テスト用アーカイブの作成**:

```bash
cd /tmp/partimag
tar czf test-image.tar.gz test-win11-master-20251117/
```

### 3.4 展開設定画面へのアクセス

```
http://localhost:5000/deployment
```

1. イメージ選択ドロップダウンからイメージを選択
2. 展開モード (マルチキャスト/ユニキャスト) を選択
3. 対象PCを選択 (事前にPC Masterデータベースに登録が必要)
4. 「展開を開始」ボタンをクリック

---

## 4. API直接テスト

### 4.1 イメージ一覧取得

```bash
curl http://localhost:5000/api/images | jq
```

期待されるレスポンス:

```json
{
  "success": true,
  "count": 1,
  "images": [
    {
      "name": "test-win11-master-20251117",
      "path": "/tmp/partimag/test-win11-master-20251117",
      "size_bytes": 1677721600,
      "size_human": "1.6 GB",
      "created": "2025-11-17 12:00:00",
      "disk_count": 1
    }
  ]
}
```

### 4.2 イメージ詳細取得

```bash
curl http://localhost:5000/api/images/test-win11-master-20251117 | jq
```

### 4.3 展開設定作成

```bash
curl -X POST http://localhost:5000/api/deployment \
  -H "Content-Type: application/json" \
  -d '{
    "name": "テスト展開",
    "image_name": "test-win11-master-20251117",
    "mode": "multicast",
    "target_serials": ["ABC123", "DEF456"],
    "created_by": "admin"
  }' | jq
```

期待されるレスポンス:

```json
{
  "success": true,
  "message": "Deployment created successfully",
  "deployment": {
    "id": 1,
    "name": "テスト展開",
    "image_name": "test-win11-master-20251117",
    "mode": "multicast",
    "target_count": 2,
    "status": "pending",
    "progress": 0
  }
}
```

### 4.4 展開開始

```bash
curl -X POST http://localhost:5000/api/deployment/1/start | jq
```

---

## 5. トラブルシューティング

### 5.1 イメージが表示されない

**原因**: イメージディレクトリのパスが間違っている

**解決策**:

```bash
# パスを確認
ls -la /tmp/partimag

# または DRBLClient のデフォルトパスを確認
ls -la /home/partimag
```

### 5.2 アップロードに失敗する

**原因**: ファイルサイズ制限またはディスク容量不足

**解決策**:

```bash
# ディスク容量を確認
df -h /tmp

# Flaskの最大アップロードサイズを確認 (app.py)
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024 * 1024  # 16GB
```

### 5.3 展開が開始されない

**原因**: DRBLサーバが起動していない、または接続できない

**解決策**:

```bash
# DRBLサーバの状態を確認
systemctl status drbl-server  # (DRBL環境の場合)

# または開発環境ではシミュレーションモードを確認
# utils/drbl_client.py の drbl_installed フラグを確認
```

### 5.4 PC情報が表示されない

**原因**: PC Masterテーブルにデータが登録されていない

**解決策**:

```bash
# テストデータを登録
curl -X POST http://localhost:5000/api/pc \
  -H "Content-Type: application/json" \
  -d '{
    "serial": "TEST123",
    "pcname": "20251117M",
    "odj_path": "/srv/odj/20251117M.txt"
  }'
```

---

## 6. 本番環境への移行

### 6.1 環境設定の変更

```python
# config.py または環境変数
DRBL_IMAGE_HOME = '/home/partimag'
DRBL_ODJ_HOME = '/srv/odj'
DRBL_BIN = '/opt/drbl/sbin'
```

### 6.2 DRBLサーバとの連携確認

```bash
# DRBLコマンドが利用可能か確認
which dcs
which drbl-ocs

# イメージディレクトリの権限確認
ls -la /home/partimag
```

### 6.3 セキュリティ設定

- HTTPS通信の有効化
- API認証の実装
- ファイルアップロードサイズ制限の設定
- CORS設定の確認

---

## 7. 次のステップ

1. **実機でのテスト**
   - 実際のClonezillaイメージを使用
   - PXEブート環境での展開テスト

2. **機能拡張**
   - デフォルトイメージ設定機能の実装
   - WebSocketによるリアルタイム進捗表示
   - 展開ログのダウンロード機能

3. **ドキュメント整備**
   - ユーザーマニュアルの作成
   - 運用手順書の作成
   - トラブルシューティングガイドの充実

---

## サポート

問題が発生した場合は、以下のログを確認してください:

```bash
# Flaskログ
tail -f /var/log/flask-app/app.log

# DRBLログ (DRBL環境)
tail -f /var/log/clonezilla/*.log
```

詳細な実装状況は `IMPLEMENTATION_REPORT.md` を参照してください。

---

**作成日**: 2025-11-17
**対象バージョン**: 1.0
