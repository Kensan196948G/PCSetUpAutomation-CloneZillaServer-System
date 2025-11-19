# REST API仕様

## ベースURL

### 開発環境
```
http://192.168.3.135:5000
```

### 本番環境
```
http://192.168.3.135:8000
```

---

## エンドポイント一覧

### 1. GET /api/pcinfo
Serial番号からPC名とODJファイルパスを取得

#### リクエスト
```http
GET /api/pcinfo?serial=ABC123456
```

#### クエリパラメータ
| パラメータ名 | 型 | 必須 | 説明 |
|------------|---|------|------|
| serial | string | ✓ | PCシリアル番号 |

#### レスポンス（成功時）
```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "pcname": "20251116M",
  "odj_path": "/srv/odj/20251116M.txt"
}
```

#### レスポンス（失敗時）
```json
HTTP/1.1 404 Not Found
Content-Type: application/json

{
  "error": "PC not found",
  "serial": "ABC123456"
}
```

#### エラーコード
- `200 OK`: 成功
- `400 Bad Request`: serialパラメータが不足
- `404 Not Found`: 該当PCが見つからない
- `500 Internal Server Error`: サーバエラー

#### 使用例（curl）
```bash
curl "http://localhost:5000/api/pcinfo?serial=ABC123456"
```

#### 使用例（PowerShell）
```powershell
$serial = (Get-CimInstance Win32_BIOS).SerialNumber
$response = Invoke-RestMethod -Uri "http://192.168.3.135:5000/api/pcinfo?serial=$serial"
$pcname = $response.pcname
$odjPath = $response.odj_path
```

---

### 2. POST /api/log
セットアップログを記録

#### リクエスト
```http
POST /api/log
Content-Type: application/json

{
  "serial": "ABC123456",
  "pcname": "20251116M",
  "status": "completed",
  "timestamp": "2025-11-16 12:33:22",
  "logs": "Setup completed successfully",
  "step": "finalize"
}
```

#### リクエストボディ
| フィールド名 | 型 | 必須 | 説明 |
|------------|---|------|------|
| serial | string | ✓ | PCシリアル番号 |
| pcname | string | ✓ | PC名 |
| status | string | ✓ | セットアップ状態 |
| timestamp | string | ✓ | タイムスタンプ（YYYY-MM-DD HH:MM:SS形式） |
| logs | string | - | ログ文字列（詳細情報） |
| step | string | - | セットアップステップ |

#### status の値
- `started`: セットアップ開始
- `imaging`: イメージ展開中
- `boot`: 初回起動
- `pc_name_set`: PC名設定完了
- `odj_applied`: ドメイン参加完了
- `windows_update`: Windows Update実行中
- `app_installation`: アプリインストール中
- `completed`: セットアップ完了
- `failed`: セットアップ失敗

#### step の値
- `pxe_boot`: PXEブート
- `clonezilla`: Clonezillaイメージ展開
- `first_boot`: 初回起動
- `pc_rename`: PC名変更
- `odj`: Offline Domain Join
- `windows_update`: Windows Update
- `app_install`: アプリケーションインストール
- `finalize`: 最終処理

#### レスポンス（成功時）
```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "result": "ok"
}
```

#### レスポンス（失敗時）
```json
HTTP/1.1 400 Bad Request
Content-Type: application/json

{
  "error": "Invalid request",
  "message": "Missing required field: serial"
}
```

#### エラーコード
- `200 OK`: 成功
- `400 Bad Request`: リクエストボディが不正
- `500 Internal Server Error`: サーバエラー

#### 使用例（curl）
```bash
curl -X POST http://localhost:5000/api/log \
  -H "Content-Type: application/json" \
  -d '{
    "serial": "ABC123456",
    "pcname": "20251116M",
    "status": "completed",
    "timestamp": "2025-11-16 12:33:22",
    "logs": "Setup completed successfully",
    "step": "finalize"
  }'
```

#### 使用例（PowerShell）
```powershell
$logData = @{
    serial = $serial
    pcname = $pcname
    status = "completed"
    timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    logs = "Setup completed successfully"
    step = "finalize"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://192.168.3.135:5000/api/log" `
    -Method POST `
    -ContentType "application/json" `
    -Body $logData
```

---

### 3. GET /api/pc (CRUD API)
PC情報一覧取得

#### リクエスト
```http
GET /api/pc
```

#### レスポンス
```json
HTTP/1.1 200 OK
Content-Type: application/json

[
  {
    "id": 1,
    "serial": "ABC123456",
    "pcname": "20251116M",
    "odj_path": "/srv/odj/20251116M.txt",
    "created_at": "2025-11-16 10:00:00"
  },
  {
    "id": 2,
    "serial": "DEF789012",
    "pcname": "20251117M",
    "odj_path": "/srv/odj/20251117M.txt",
    "created_at": "2025-11-17 09:30:00"
  }
]
```

---

### 4. POST /api/pc (CRUD API)
PC情報登録

#### リクエスト
```http
POST /api/pc
Content-Type: application/json

{
  "serial": "ABC123456",
  "pcname": "20251116M",
  "odj_path": "/srv/odj/20251116M.txt"
}
```

#### レスポンス
```json
HTTP/1.1 201 Created
Content-Type: application/json

{
  "id": 1,
  "serial": "ABC123456",
  "pcname": "20251116M",
  "odj_path": "/srv/odj/20251116M.txt",
  "created_at": "2025-11-16 10:00:00"
}
```

---

### 5. PUT /api/pc/<id> (CRUD API)
PC情報更新

#### リクエスト
```http
PUT /api/pc/1
Content-Type: application/json

{
  "pcname": "20251118M",
  "odj_path": "/srv/odj/20251118M.txt"
}
```

#### レスポンス
```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": 1,
  "serial": "ABC123456",
  "pcname": "20251118M",
  "odj_path": "/srv/odj/20251118M.txt",
  "created_at": "2025-11-16 10:00:00"
}
```

---

### 6. DELETE /api/pc/<id> (CRUD API)
PC情報削除

#### リクエスト
```http
DELETE /api/pc/1
```

#### レスポンス
```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "result": "ok",
  "message": "PC deleted successfully"
}
```

---

## 共通仕様

### HTTPヘッダー
```
Content-Type: application/json
```

### CORS設定
- すべてのオリジンからのアクセスを許可（開発環境）
- 本番環境では特定オリジンのみ許可

### タイムスタンプ形式
```
YYYY-MM-DD HH:MM:SS
例: 2025-11-16 12:33:22
```

### エラーレスポンス形式
```json
{
  "error": "エラータイプ",
  "message": "詳細なエラーメッセージ"
}
```

---

## レート制限
- 現在は制限なし
- 本番環境では将来的に実装を検討

---

## 認証・認可
- 現在は認証なし（社内LAN限定）
- 将来的にAPIキー認証を実装予定

---

## パフォーマンス要件
- **応答時間**: 200ms以下（LAN環境）
- **同時接続**: 20台同時接続に対応
