# Clonezillaイメージパス設定 - クイックリファレンス

## 使い方

### Web UIから設定

1. **アクセス**
   ```
   http://localhost:5000/deployment/settings
   ```

2. **パス検証**
   - 「Clonezillaイメージパス設定」セクションを探す
   - パスを入力（例: `/mnt/Linux-ExHDD/Ubuntu-ExHDD`）
   - 「検証」ボタンをクリック
   - パス情報（容量、イメージ数など）が表示される

3. **パス更新**
   - パスを入力
   - 「更新」ボタンをクリック
   - 確認ダイアログで「OK」
   - 成功メッセージ表示後、ページがリロードされる

### APIから設定

#### 現在の設定を取得

```bash
curl http://localhost:5000/api/settings
```

#### パスを検証

```bash
curl -X POST http://localhost:5000/api/settings/image-path/validate \
  -H "Content-Type: application/json" \
  -d '{"path": "/mnt/Linux-ExHDD/Ubuntu-ExHDD"}'
```

#### パスを更新

```bash
curl -X POST http://localhost:5000/api/settings/image-path \
  -H "Content-Type: application/json" \
  -d '{"path": "/mnt/Linux-ExHDD/Ubuntu-ExHDD"}'
```

## ファイル構成

```
flask-app/
├── api/
│   ├── __init__.py          # settings import追加
│   └── settings.py          # 新規: Settings API
├── views/
│   └── deployment.py        # 更新: config渡し追加
├── templates/
│   └── deployment/
│       └── settings.html    # 更新: UI追加
├── .env                     # 新規: 開発環境設定
├── config.py                # 更新: .env読み込み改善
└── test_settings_api.py     # 新規: APIテスト
```

## デフォルト値

| 設定項目 | デフォルト値 |
|---------|-------------|
| イメージパス | `/mnt/Linux-ExHDD/Ubuntu-ExHDD` |
| ODJパス | `/srv/odj/` |
| APIホスト | `0.0.0.0` |
| APIポート | `5000` |

## 環境変数

### 開発環境 (.env)

```env
CLONEZILLA_IMAGE_PATH=/mnt/Linux-ExHDD/Ubuntu-ExHDD
```

### 本番環境 (.env.production)

```env
CLONEZILLA_IMAGE_PATH=/mnt/Linux-ExHDD/Ubuntu-ExHDD
```

## トラブルシューティング

| 問題 | 解決策 |
|------|--------|
| パスが存在しません | パスを確認、必要に応じて作成 |
| 書き込み権限がありません | `chmod 755 <パス>` で権限付与 |
| APIが応答しない | Flaskサーバーを再起動 |
| 更新が反映されない | ページをリロード、またはサーバー再起動 |

## よくある質問

### Q: パス変更は即座に反映されますか？

A: はい。APIを通じた変更は即座に反映され、.envファイルにも永続化されます。

### Q: どのようなパスが使用できますか？

A: 以下の条件を満たすパス:
- 存在するディレクトリ
- 読み取り権限あり
- 書き込み権限あり

### Q: パス変更後にサーバー再起動は必要ですか？

A: いいえ。設定はアプリケーションメモリ内で即座に更新されます。

### Q: 複数のイメージパスを設定できますか？

A: 現在のバージョンでは1つのパスのみです。将来の拡張で対応予定です。

## サポート

問題が発生した場合:
1. ログファイルを確認: `logs/app.log`
2. テストスクリプトを実行: `python test_settings_api.py`
3. パス権限を確認: `ls -la <パス>`
