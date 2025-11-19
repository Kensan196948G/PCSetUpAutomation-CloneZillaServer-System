# 本番環境運用ガイド

## 概要

本ディレクトリは、PCキッティング自動化フレームワークの本番環境です。
年間100台規模のWindows PCを完全自動でキッティングするシステムを提供します。

## ディレクトリ構成

```
production/
├── flask-app/           # Flask Webアプリケーション（本番用）
├── powershell-scripts/  # Windows自動セットアップスクリプト
├── drbl-server/         # DRBL/Clonezilla設定（本番用）
├── configs/             # 本番環境用設定ファイル
│   ├── database.prod.yaml
│   ├── api.prod.yaml
│   ├── drbl.prod.conf
│   └── nginx.conf       # Nginx設定
├── data/                # 本番用データ
│   ├── images/          # 本番用Clonezillaイメージ
│   ├── odj/             # 本番用ODJファイル
│   └── db/              # 本番データベース
├── logs/                # 本番環境ログ
│   ├── flask/
│   ├── nginx/
│   └── drbl/
├── backups/             # バックアップ保存先
│   ├── daily/
│   ├── weekly/
│   └── monthly/
├── scripts/             # 本番環境用スクリプト
│   ├── start-prod.sh    # 本番サーバ起動
│   ├── stop-prod.sh     # 本番サーバ停止
│   ├── backup.sh        # バックアップスクリプト
│   ├── restore.sh       # リストアスクリプト
│   └── health-check.sh  # ヘルスチェック
├── systemd/             # systemdサービスファイル
│   ├── flask-app.service
│   └── drbl-server.service
├── .env.production      # 本番環境変数
├── docker-compose.prod.yml  # Docker本番環境（オプション）
└── README_PRODUCTION.md     # 本ファイル
```

## 本番環境セットアップ手順

### 前提条件

- Ubuntu Server 22.04 LTS以上
- 2コア以上のCPU
- 4GB以上のメモリ
- 500GB以上のディスク容量
- 固定IPアドレスの設定
- ドメイン参加可能なネットワーク環境

### 1. DRBL/Clonezillaのインストール

```bash
# DRBLリポジトリの追加
sudo add-apt-repository universe
sudo wget -q http://drbl.org/GPG-KEY-DRBL -O- | sudo apt-key add -
sudo sh -c 'echo "deb http://drbl.sourceforge.net/drbl-core drbl stable" > /etc/apt/sources.list.d/drbl.list'

# DRBL/Clonezillaのインストール
sudo apt update
sudo apt install -y drbl clonezilla

# DRBL初期設定
sudo /usr/sbin/drblsrv -i
sudo /usr/sbin/drblpush -i
```

### 2. Flask Webアプリケーションのセットアップ

```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production

# Python仮想環境のセットアップ
python3 -m venv venv
source venv/bin/activate
pip install -r flask-app/requirements.txt

# 環境変数の設定
sudo cp .env.production.template .env.production
sudo nano .env.production  # 本番用設定を入力

# データベース初期化
cd flask-app
flask db init
flask db migrate
flask db upgrade
```

### 3. Nginxのセットアップ

```bash
# Nginxのインストール
sudo apt install -y nginx

# Nginx設定のコピー
sudo cp configs/nginx.conf /etc/nginx/sites-available/pcsetup
sudo ln -s /etc/nginx/sites-available/pcsetup /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 4. systemdサービスの登録

```bash
# Flask Webアプリケーションのサービス化
sudo cp systemd/flask-app.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable flask-app.service
sudo systemctl start flask-app.service

# ステータス確認
sudo systemctl status flask-app.service
```

### 5. バックアップスクリプトの設定

```bash
# バックアップスクリプトに実行権限を付与
chmod +x scripts/backup.sh
chmod +x scripts/restore.sh

# cronで自動バックアップを設定
sudo crontab -e
# 以下を追加（毎日午前2時にバックアップ）
# 0 2 * * * /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/scripts/backup.sh
```

## 運用手順

### マスターイメージの配置

```bash
# Clonezillaで作成したマスターイメージを配置
sudo cp -r /path/to/master-image /home/partimag/
sudo chown -R root:root /home/partimag/
```

### ODJファイルの配置

```bash
# Active DirectoryでODJファイルを作成
djoin.exe /provision /domain <ドメイン名> /machine <PC名> /savefile <ファイル名>.txt

# ODJファイルをDRBLサーバに転送
scp <ファイル名>.txt user@drbl-server:/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/data/odj/
```

### PC情報の一括登録

```bash
# CSVファイルを準備（serial, pcname, odj_path）
# 例: ABC123456,20251116M,/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/data/odj/20251116M.txt

# Web管理画面からCSVインポート、またはコマンドラインから
cd flask-app
python scripts/import_csv.py ../data/pc_master.csv
```

### PXEブートの実行

1. 対象PCをDRBLサーバと同じネットワークに接続
2. PCの電源を入れてPXEブート
3. Clonezillaメニューから自動展開を選択
4. イメージ展開完了後、自動的に再起動
5. PowerShellスクリプトが自動実行されてセットアップ完了

### ログの確認

```bash
# Flask Webアプリケーションのログ
tail -f logs/flask/app.log

# Nginxのログ
tail -f logs/nginx/access.log
tail -f logs/nginx/error.log

# DRBLのログ
tail -f logs/drbl/drbl.log
```

### ヘルスチェック

```bash
# 手動ヘルスチェック
./scripts/health-check.sh

# または、Web API経由で確認
curl http://localhost/api/health
```

### バックアップとリストア

```bash
# 手動バックアップ
sudo ./scripts/backup.sh

# リストア（慎重に実施）
sudo ./scripts/restore.sh /path/to/backup-file.tar.gz
```

## トラブルシューティング

### PXEブートできない

1. DHCPサーバの設定を確認
2. TFTPサーバのステータス確認: `sudo systemctl status tftpd-hpa`
3. ネットワークケーブルの接続を確認

### API応答がない

```bash
# Flask Webアプリケーションのステータス確認
sudo systemctl status flask-app.service

# ログ確認
tail -f logs/flask/app.log

# 再起動
sudo systemctl restart flask-app.service
```

### ODJ適用失敗

1. ODJファイルのパスが正しいか確認
2. ODJファイルの権限を確認: `ls -l data/odj/`
3. Active Directoryとの接続を確認
4. ログを確認して詳細エラーを特定

### データベースエラー

```bash
# データベースの整合性チェック
cd flask-app
flask db check

# 必要に応じてマイグレーション実行
flask db migrate
flask db upgrade
```

## セキュリティ対策

1. **ファイアウォール設定**: 必要なポートのみ開放（80, 443, TFTP, PXE）
2. **アクセス制限**: 社内LANからのみアクセス許可
3. **ログ監視**: 不審なアクセスを定期的に確認
4. **定期バックアップ**: 毎日自動バックアップを実施
5. **セキュリティパッチ**: OSとアプリケーションの定期更新

## パフォーマンス要件

- **API応答時間**: 200ms以下
- **同時展開**: 10〜20台
- **展開時間**: 60〜90分以内
- **展開失敗率**: 1%未満

## メンテナンス

### 定期メンテナンス（月次）

1. ログファイルのローテーション
2. バックアップファイルの整理（3ヶ月以上前のものを削除）
3. ディスク使用量の確認
4. パフォーマンスメトリクスの確認

### 四半期メンテナンス

1. OSとパッケージのアップデート
2. マスターイメージの更新
3. セキュリティ監査

## 関連ドキュメント

- [開発環境セットアップガイド](../development/README_DEVELOPMENT.md)
- [API仕様書](../docs/API_SPECIFICATION.md)
- [データベーススキーマ](../docs/DATABASE_SCHEMA.md)
- [PowerShellスクリプト仕様](../docs/POWERSHELL_SCRIPTS.md)
- [システムアーキテクチャ](../docs/SYSTEM_ARCHITECTURE.md)

## 緊急連絡先

- システム管理者: [管理者メールアドレス]
- インフラ担当: [担当者メールアドレス]
- エスカレーション先: [上位管理者メールアドレス]

## バージョン履歴

- v1.0.0 (2025-11-16): 初回リリース
