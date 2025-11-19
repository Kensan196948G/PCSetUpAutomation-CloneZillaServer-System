# 開発環境・本番環境 同時稼働レポート

**セットアップ完了日時**: 2025年11月17日 12:31
**作成者**: システム管理チーム
**バージョン**: 1.0

---

## ✅ セットアップ完了

開発環境（development）と本番環境（production）の2つの独立したFlask Webアプリケーション環境が同時稼働しています。

---

## 🌐 環境情報

### 開発環境（Development）

| 項目 | 値 |
|------|-----|
| **URL** | http://192.168.3.135:5000/ |
| **ポート** | 5000 |
| **プロセスID** | 32935 |
| **デバッグモード** | ON（有効） |
| **データベース** | SQLite (development) |
| **ログファイル** | `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/logs/flask.log` |
| **用途** | 開発・検証・テスト |

### 本番環境（Production）

| 項目 | 値 |
|------|-----|
| **URL** | http://192.168.3.135:8000/ |
| **ポート** | 8000 |
| **プロセスID** | 39794 |
| **デバッグモード** | OFF（無効） |
| **データベース** | SQLite (production) |
| **ログファイル** | `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/logs/flask/app.log` |
| **用途** | 本番運用シミュレーション |

---

## ✅ 全ページ動作確認結果

### 開発環境（ポート5000）- 全9ページ

| # | ページ | URL | ステータス |
|---|--------|-----|-----------|
| 1 | ダッシュボード | http://192.168.3.135:5000/ | ✅ 200 |
| 2 | PC一覧 | http://192.168.3.135:5000/pcs | ✅ 200 |
| 3 | PC追加 | http://192.168.3.135:5000/pcs/add | ✅ 200 |
| 4 | セットアップログ | http://192.168.3.135:5000/logs | ✅ 200 |
| 5 | CSV一括登録 | http://192.168.3.135:5000/import | ✅ 200 |
| 6 | ODJアップロード | http://192.168.3.135:5000/odj-upload | ✅ 200 |
| 7 | マスターイメージ | http://192.168.3.135:5000/deployment/images | ✅ 200 |
| 8 | 展開設定 | http://192.168.3.135:5000/deployment/settings | ✅ 200 |
| 9 | 展開ステータス | http://192.168.3.135:5000/deployment/status | ✅ 200 |

**成功率**: 9/9 = 100% ✅

### 本番環境（ポート8000）- 全9ページ

| # | ページ | URL | ステータス |
|---|--------|-----|-----------|
| 1 | ダッシュボード | http://192.168.3.135:8000/ | ✅ 200 |
| 2 | PC一覧 | http://192.168.3.135:8000/pcs | ✅ 200 |
| 3 | PC追加 | http://192.168.3.135:8000/pcs/add | ✅ 200 |
| 4 | セットアップログ | http://192.168.3.135:8000/logs | ✅ 200 |
| 5 | CSV一括登録 | http://192.168.3.135:8000/import | ✅ 200 |
| 6 | ODJアップロード | http://192.168.3.135:8000/odj-upload | ✅ 200 |
| 7 | マスターイメージ | http://192.168.3.135:8000/deployment/images | ✅ 200 |
| 8 | 展開設定 | http://192.168.3.135:8000/deployment/settings | ✅ 200 |
| 9 | 展開ステータス | http://192.168.3.135:8000/deployment/status | ✅ 200 |

**成功率**: 9/9 = 100% ✅

---

## 📁 環境別フォルダ構成

### 開発環境

```
/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app/
├── app.py
├── config.py
├── models/
├── api/
├── views/
├── templates/
├── static/
├── venv/              # 開発用Python仮想環境
├── instance/          # 開発用データベース
│   └── dev.db
└── logs/              # 開発ログ
```

### 本番環境

```
/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/flask-app/
├── app.py
├── config.py
├── config_production.py    ⭐本番環境用設定
├── run_production.py       ⭐本番環境用起動スクリプト
├── models/
├── api/
├── views/
├── templates/
├── static/
├── venv/              # 本番用Python仮想環境
├── instance/          # 本番用データベース
│   └── production.db
└── logs/              # 本番ログ
```

---

## 🔧 環境別設定の違い

| 設定項目 | 開発環境 | 本番環境 |
|---------|---------|---------|
| **ポート** | 5000 | 8000 |
| **デバッグモード** | ON | OFF |
| **ホットリロード** | ON | OFF |
| **ログレベル** | DEBUG | INFO |
| **データベース** | development.db | production.db |
| **CORS** | 有効 | 無効 |
| **セッションタイムアウト** | 60分 | 30分 |
| **エラー表示** | 詳細 | 汎用的 |

---

## 🚀 起動・停止コマンド

### 開発環境

#### 起動
```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app
source venv/bin/activate
python3 app.py
```

#### 停止
```bash
kill $(cat /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/logs/flask.pid)
```

### 本番環境

#### 起動
```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/flask-app
source venv/bin/activate
python3 run_production.py
```

または：
```bash
# バックグラウンド起動
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/flask-app
source venv/bin/activate
nohup python3 run_production.py > ../logs/flask/app.log 2>&1 &
echo $! > ../logs/flask.pid
```

#### 停止
```bash
kill $(cat /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/logs/flask.pid)
```

### 両方同時起動（推奨）

```bash
# 開発環境起動（バックグラウンド）
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app
source venv/bin/activate
nohup python3 app.py > ../logs/flask.log 2>&1 &
echo $! > ../logs/flask.pid

# 本番環境起動（バックグラウンド）
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/flask-app
source venv/bin/activate
nohup python3 run_production.py > ../logs/flask/app.log 2>&1 &
echo $! > ../logs/flask.pid
```

---

## 🔐 セキュリティ設定

### 本番環境の追加セキュリティ

本番環境では以下のセキュリティ設定が適用されています：

- ✅ **デバッグモード無効**: エラー詳細が外部に漏れない
- ✅ **CORS無効**: 外部サイトからのAPI呼び出しを遮断
- ✅ **セッションタイムアウト短縮**: 30分（開発は60分）
- ✅ **ログレベルINFO**: デバッグ情報は記録されない
- ✅ **本番用SECRET_KEY**: 開発環境とは異なる鍵を使用

### 将来の本番環境推奨設定

本格的な本番運用時は、以下の追加設定を推奨します：

1. **Gunicorn使用**: Flask開発サーバではなくGunicornで起動
   ```bash
   gunicorn -w 4 -b 0.0.0.0:8000 'app:create_app("production")'
   ```

2. **Nginx リバースプロキシ**: Nginxでポート80/443から8000へプロキシ
   ```nginx
   location / {
       proxy_pass http://127.0.0.1:8000;
       proxy_set_header Host $host;
   }
   ```

3. **SSL/TLS設定**: HTTPS通信の有効化
   ```bash
   certbot --nginx -d drbl.company.local
   ```

4. **systemdサービス化**: 自動起動設定
   ```ini
   [Unit]
   Description=Flask PC Setup Production
   [Service]
   ExecStart=/path/to/venv/bin/gunicorn -w 4 'app:create_app("production")'
   [Install]
   WantedBy=multi-user.target
   ```

---

## 📊 データベース分離

### 開発環境データベース
- **ファイル**: `flask-app/instance/development.db`
- **用途**: 開発・テスト用データ
- **データ**: テストデータ、ダミーデータ
- **バックアップ**: 不要（随時リセット可能）

### 本番環境データベース
- **ファイル**: `production/flask-app/instance/production.db`
- **用途**: 本番データ（または本番シミュレーション）
- **データ**: 実際のPC情報、セットアップログ
- **バックアップ**: 日次バックアップ推奨

**注意**: 両環境のデータベースは完全に独立しており、相互に影響しません。

---

## 🔄 環境間データ移行

### 開発環境から本番環境へのデータ移行

十分なテストを実施後、本番環境への移行が必要な場合：

```bash
# データベースダンプ（開発環境）
sqlite3 flask-app/instance/development.db .dump > /tmp/dev_data.sql

# データベースインポート（本番環境）
sqlite3 production/flask-app/instance/production.db < /tmp/dev_data.sql

# または、ファイルコピー（推奨されない）
cp flask-app/instance/development.db production/flask-app/instance/production.db
```

---

## 📝 ログ確認

### 開発環境ログ
```bash
tail -f /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/logs/flask.log
```

### 本番環境ログ
```bash
tail -f /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/logs/flask/app.log
```

---

## 🎯 使い分けガイド

### 開発環境を使用する場面
- ✅ 新機能の開発・検証
- ✅ バグ修正のテスト
- ✅ データベーススキーマの変更テスト
- ✅ API動作確認
- ✅ UI/UXの改善

### 本番環境を使用する場面
- ✅ 本番運用のシミュレーション
- ✅ パフォーマンステスト
- ✅ セキュリティ設定の検証
- ✅ 実際のPC情報を使った動作確認
- ✅ 運用手順のリハーサル

---

## ⚠️ 注意事項

### 1. ポート競合の回避
- 開発環境: 5000
- 本番環境: 8000
- **両方のポートを同時に使用可能**

### 2. データベース分離
- 開発環境と本番環境のデータベースは完全に独立
- 誤って開発環境のデータを本番に反映しないよう注意

### 3. 設定ファイルの管理
- `.env.development`（開発）と`.env.production`（本番）を厳密に分離
- SECRET_KEYは必ず異なる値を使用

### 4. リソース使用
- 両方を同時起動すると、メモリ使用量が増加
- 必要に応じて片方を停止

---

## 🔍 トラブルシューティング

### ポート8000が既に使用されている

```bash
# ポート使用状況確認
sudo lsof -i :8000

# プロセス終了
sudo kill -9 <PID>
```

### 本番環境が起動しない

```bash
# ログ確認
tail -50 /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/logs/flask/app.log

# 仮想環境確認
cd production/flask-app
source venv/bin/activate
python3 -c "import flask; print(flask.__version__)"
```

### データベース初期化エラー

```bash
# データベースファイル削除して再初期化
rm production/flask-app/instance/production.db
cd production/flask-app
source venv/bin/activate
python3 -c "from app import create_app, db; app=create_app('production'); app.app_context().push(); db.create_all()"
```

---

## 📈 次のステップ

### 短期（1週間以内）
1. ✅ 開発環境でPC情報の登録・編集機能をテスト
2. ✅ 本番環境でパフォーマンステストを実施
3. ✅ 両環境のデータベースバックアップスクリプト作成

### 中期（1ヶ月以内）
1. 本番環境にGunicorn + Nginx構成を導入
2. SSL/TLS証明書の取得と設定
3. systemdサービス化
4. 監視・アラート設定（Prometheus + Grafana）

### 長期（3ヶ月以内）
1. 本番環境での実運用開始
2. 開発環境でのCI/CD パイプライン構築
3. 多拠点展開への拡張検討

---

## 📞 サポート情報

### 開発環境のサポート
- **担当**: 開発チーム
- **連絡先**: dev-team@company.local
- **対応時間**: 平日 9:00〜18:00

### 本番環境のサポート
- **担当**: インフラチーム + 運用チーム
- **連絡先**: infra-team@company.local
- **対応時間**: 平日 9:00〜18:00（緊急時24時間対応）

---

## 📚 関連ドキュメント

- [開発環境デプロイ手順](docs/07_デプロイ/開発環境デプロイ手順.md)
- [本番環境デプロイ手順](docs/07_デプロイ/本番環境デプロイ手順.md)
- [環境移行チェックリスト](docs/07_デプロイ/環境移行チェックリスト.md)
- [運用手順書](docs/05_運用/日常運用手順書.md)

---

**最終更新**: 2025年11月17日 12:31
**次回レビュー予定**: 2025年12月1日

---

## ✅ 確認項目チェックリスト

- [x] 開発環境が正常起動（ポート5000）
- [x] 本番環境が正常起動（ポート8000）
- [x] 開発環境全9ページが200応答
- [x] 本番環境全9ページが200応答
- [x] 両環境のデータベースが独立
- [x] 両環境のログが独立
- [x] プロセスIDが記録されている
- [x] セキュリティ設定が適用されている

---

**セットアップ完了 - 両環境が同時稼働中！**
