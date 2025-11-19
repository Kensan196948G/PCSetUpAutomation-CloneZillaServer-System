# API仕様書

## 目次
1. [概要](#概要)
2. [認証](#認証)
3. [共通仕様](#共通仕様)
4. [エンドポイント一覧](#エンドポイント一覧)
5. [エラーレスポンス](#エラーレスポンス)
6. [使用例](#使用例)

---

## 概要

### API概要
PC自動セットアップシステムのREST API仕様書です。DRBL管理サーバーが提供するAPIで、クライアントPCからのPC情報取得、セットアップログの記録を行います。

### ベースURL
```
http://drbl-server:5000/api
```

### バージョン
```
Version: 1.0
Last Updated: 2025-11-16
```

### プロトコル
- **HTTP/1.1**
- **Content-Type**: application/json
- **Charset**: UTF-8

---

## 認証

### Bearer Token認証

すべてのAPIリクエストには、Authorizationヘッダーに Bearer Token を含める必要があります。

```http
Authorization: Bearer YOUR_API_TOKEN
```

### トークンの取得

トークンは環境変数またはサーバー管理者から取得してください。

```bash
# .envファイルに記載
API_TOKEN=your-secret-api-token-here
```

### 認証エラー

トークンが無効または欠落している場合：

```json
{
  "error": "Unauthorized",
  "message": "有効なAPIトークンが必要です"
}
```

**HTTPステータス**: `401 Unauthorized`

---

## 共通仕様

### リクエストヘッダー

```http
Content-Type: application/json
Authorization: Bearer YOUR_API_TOKEN
Accept: application/json
```

### レスポンス形式

すべてのレスポンスはJSON形式です。

**成功時**:
```json
{
  "status": "success",
  "data": { ... }
}
```

**エラー時**:
```json
{
  "status": "error",
  "error": "エラータイプ",
  "message": "エラーメッセージ"
}
```

### HTTPステータスコード

| コード | 説明 |
|--------|------|
| 200 | OK - リクエスト成功 |
| 201 | Created - リソース作成成功 |
| 400 | Bad Request - リクエストが不正 |
| 401 | Unauthorized - 認証エラー |
| 404 | Not Found - リソースが見つからない |
| 409 | Conflict - リソースの競合 |
| 500 | Internal Server Error - サーバーエラー |
| 503 | Service Unavailable - サービス利用不可 |

### タイムスタンプ形式

```
YYYY-MM-DD HH:MM:SS
例: 2025-11-16 14:30:00
```

### レート制限

- **制限**: 100リクエスト/分
- **制限超過時**: `429 Too Many Requests`

---

## エンドポイント一覧

### 1. PC情報取得

#### エンドポイント
```
GET /api/pcinfo
```

#### 説明
シリアル番号からPC名とODJファイルパスを取得します。

#### リクエストパラメータ

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| serial | string | Yes | PCのシリアル番号 |

#### リクエスト例

```http
GET /api/pcinfo?serial=ABC123456 HTTP/1.1
Host: drbl-server:5000
Authorization: Bearer your-api-token
Accept: application/json
```

#### レスポンス

**成功時** (200 OK):
```json
{
  "status": "success",
  "data": {
    "serial": "ABC123456",
    "pcname": "20251116M",
    "odj_path": "/srv/odj/20251116M.txt"
  }
}
```

**シリアル番号が見つからない場合** (404 Not Found):
```json
{
  "status": "error",
  "error": "NotFound",
  "message": "シリアル番号 ABC123456 は登録されていません"
}
```

**パラメータ不足** (400 Bad Request):
```json
{
  "status": "error",
  "error": "BadRequest",
  "message": "serialパラメータが必要です"
}
```

#### curlコマンド例

```bash
curl -X GET \
  "http://drbl-server:5000/api/pcinfo?serial=ABC123456" \
  -H "Authorization: Bearer your-api-token" \
  -H "Accept: application/json"
```

#### PowerShellコマンド例

```powershell
$Headers = @{
    "Authorization" = "Bearer your-api-token"
    "Accept" = "application/json"
}

$Response = Invoke-RestMethod `
    -Uri "http://drbl-server:5000/api/pcinfo?serial=ABC123456" `
    -Method GET `
    -Headers $Headers

Write-Output $Response
```

---

### 2. セットアップログ記録

#### エンドポイント
```
POST /api/log
```

#### 説明
PCセットアップのログを記録します。

#### リクエストボディ

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| serial | string | Yes | PCのシリアル番号 |
| pcname | string | Yes | PC名 |
| status | string | Yes | セットアップ状態 (started, in_progress, completed, failed) |
| timestamp | string | Yes | タイムスタンプ (YYYY-MM-DD HH:MM:SS) |
| logs | string | No | 詳細ログメッセージ |

#### リクエスト例

```http
POST /api/log HTTP/1.1
Host: drbl-server:5000
Authorization: Bearer your-api-token
Content-Type: application/json

{
  "serial": "ABC123456",
  "pcname": "20251116M",
  "status": "completed",
  "timestamp": "2025-11-16 14:30:00",
  "logs": "セットアップ正常完了。Windows Update適用済み。"
}
```

#### レスポンス

**成功時** (201 Created):
```json
{
  "status": "success",
  "data": {
    "id": 123,
    "serial": "ABC123456",
    "pcname": "20251116M",
    "status": "completed",
    "timestamp": "2025-11-16 14:30:00"
  }
}
```

**バリデーションエラー** (400 Bad Request):
```json
{
  "status": "error",
  "error": "ValidationError",
  "message": "statusフィールドは started, in_progress, completed, failed のいずれかである必要があります"
}
```

#### curlコマンド例

```bash
curl -X POST \
  "http://drbl-server:5000/api/log" \
  -H "Authorization: Bearer your-api-token" \
  -H "Content-Type: application/json" \
  -d '{
    "serial": "ABC123456",
    "pcname": "20251116M",
    "status": "completed",
    "timestamp": "2025-11-16 14:30:00",
    "logs": "セットアップ完了"
  }'
```

#### PowerShellコマンド例

```powershell
$Headers = @{
    "Authorization" = "Bearer your-api-token"
    "Content-Type" = "application/json"
}

$Body = @{
    serial = "ABC123456"
    pcname = "20251116M"
    status = "completed"
    timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    logs = "セットアップ完了"
} | ConvertTo-Json

$Response = Invoke-RestMethod `
    -Uri "http://drbl-server:5000/api/log" `
    -Method POST `
    -Headers $Headers `
    -Body $Body

Write-Output $Response
```

---

### 3. デプロイメント状態取得（オプション）

#### エンドポイント
```
GET /api/deployments
```

#### 説明
すべてのPCのデプロイメント状態を取得します。管理者用エンドポイント。

#### リクエストパラメータ

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| status | string | No | フィルタ条件 (started, completed, failed) |
| limit | integer | No | 取得件数制限 (デフォルト: 100) |
| offset | integer | No | オフセット (デフォルト: 0) |

#### リクエスト例

```http
GET /api/deployments?status=completed&limit=10 HTTP/1.1
Host: drbl-server:5000
Authorization: Bearer your-api-token
Accept: application/json
```

#### レスポンス

**成功時** (200 OK):
```json
{
  "status": "success",
  "data": {
    "total": 25,
    "count": 10,
    "deployments": [
      {
        "serial": "ABC123456",
        "pcname": "20251116M",
        "status": "completed",
        "timestamp": "2025-11-16 14:30:00"
      },
      {
        "serial": "DEF789012",
        "pcname": "20251117M",
        "status": "completed",
        "timestamp": "2025-11-17 09:15:00"
      }
    ]
  }
}
```

#### curlコマンド例

```bash
curl -X GET \
  "http://drbl-server:5000/api/deployments?status=completed&limit=10" \
  -H "Authorization: Bearer your-api-token" \
  -H "Accept: application/json"
```

---

### 4. PC情報登録

#### エンドポイント
```
POST /api/pcinfo
```

#### 説明
新しいPC情報を登録します。

#### リクエストボディ

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| serial | string | Yes | PCのシリアル番号 |
| pcname | string | Yes | PC名 (YYYYMMDDM形式) |
| odj_path | string | Yes | ODJファイルパス |

#### リクエスト例

```http
POST /api/pcinfo HTTP/1.1
Host: drbl-server:5000
Authorization: Bearer your-api-token
Content-Type: application/json

{
  "serial": "ABC123456",
  "pcname": "20251116M",
  "odj_path": "/srv/odj/20251116M.txt"
}
```

#### レスポンス

**成功時** (201 Created):
```json
{
  "status": "success",
  "data": {
    "id": 456,
    "serial": "ABC123456",
    "pcname": "20251116M",
    "odj_path": "/srv/odj/20251116M.txt",
    "created_at": "2025-11-16 14:30:00"
  }
}
```

**重複エラー** (409 Conflict):
```json
{
  "status": "error",
  "error": "Conflict",
  "message": "シリアル番号 ABC123456 は既に登録されています"
}
```

#### curlコマンド例

```bash
curl -X POST \
  "http://drbl-server:5000/api/pcinfo" \
  -H "Authorization: Bearer your-api-token" \
  -H "Content-Type: application/json" \
  -d '{
    "serial": "ABC123456",
    "pcname": "20251116M",
    "odj_path": "/srv/odj/20251116M.txt"
  }'
```

---

### 5. CSVインポート

#### エンドポイント
```
POST /api/import
```

#### 説明
CSVファイルから複数のPC情報を一括登録します。

#### リクエスト

**Content-Type**: `multipart/form-data`

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| file | file | Yes | CSVファイル |

**CSVフォーマット**:
```csv
serial,pcname,odj_path
ABC123456,20251116M,/srv/odj/20251116M.txt
DEF789012,20251117M,/srv/odj/20251117M.txt
GHI345678,20251118M,/srv/odj/20251118M.txt
```

#### リクエスト例

```http
POST /api/import HTTP/1.1
Host: drbl-server:5000
Authorization: Bearer your-api-token
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary

------WebKitFormBoundary
Content-Disposition: form-data; name="file"; filename="pcs.csv"
Content-Type: text/csv

serial,pcname,odj_path
ABC123456,20251116M,/srv/odj/20251116M.txt
------WebKitFormBoundary--
```

#### レスポンス

**成功時** (201 Created):
```json
{
  "status": "success",
  "data": {
    "imported": 3,
    "failed": 0,
    "errors": []
  }
}
```

**部分的成功** (207 Multi-Status):
```json
{
  "status": "partial_success",
  "data": {
    "imported": 2,
    "failed": 1,
    "errors": [
      {
        "row": 3,
        "serial": "ABC123456",
        "message": "既に登録されています"
      }
    ]
  }
}
```

#### curlコマンド例

```bash
curl -X POST \
  "http://drbl-server:5000/api/import" \
  -H "Authorization: Bearer your-api-token" \
  -F "file=@pcs.csv"
```

---

## エラーレスポンス

### エラーレスポンス形式

```json
{
  "status": "error",
  "error": "ErrorType",
  "message": "詳細なエラーメッセージ",
  "details": {
    "field": "問題のあるフィールド",
    "value": "問題のある値"
  }
}
```

### エラータイプ一覧

| エラータイプ | HTTPステータス | 説明 |
|-------------|---------------|------|
| Unauthorized | 401 | 認証エラー |
| BadRequest | 400 | リクエストパラメータ不正 |
| ValidationError | 400 | バリデーションエラー |
| NotFound | 404 | リソースが見つからない |
| Conflict | 409 | リソースの重複 |
| InternalServerError | 500 | サーバー内部エラー |
| ServiceUnavailable | 503 | サービス利用不可 |

### エラーレスポンス例

#### 認証エラー (401)
```json
{
  "status": "error",
  "error": "Unauthorized",
  "message": "有効なAPIトークンが必要です"
}
```

#### バリデーションエラー (400)
```json
{
  "status": "error",
  "error": "ValidationError",
  "message": "PC名の形式が不正です",
  "details": {
    "field": "pcname",
    "value": "invalid_name",
    "expected": "YYYYMMDDM形式（例: 20251116M）"
  }
}
```

#### リソース不在 (404)
```json
{
  "status": "error",
  "error": "NotFound",
  "message": "シリアル番号 XYZ999999 は登録されていません"
}
```

#### サーバーエラー (500)
```json
{
  "status": "error",
  "error": "InternalServerError",
  "message": "データベース接続エラーが発生しました"
}
```

---

## 使用例

### シナリオ1: PC初回起動時のセットアップ

```powershell
# PowerShellスクリプト例

# 1. シリアル番号取得
$Serial = (Get-CimInstance Win32_BIOS).SerialNumber

# 2. PC情報取得
$Headers = @{
    "Authorization" = "Bearer your-api-token"
}

try {
    $PCInfo = Invoke-RestMethod `
        -Uri "http://drbl-server:5000/api/pcinfo?serial=$Serial" `
        -Method GET `
        -Headers $Headers

    # 3. PC名設定
    Rename-Computer -NewName $PCInfo.data.pcname -Force

    # 4. 完了ログ送信
    $LogBody = @{
        serial = $Serial
        pcname = $PCInfo.data.pcname
        status = "completed"
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        logs = "セットアップ完了"
    } | ConvertTo-Json

    Invoke-RestMethod `
        -Uri "http://drbl-server:5000/api/log" `
        -Method POST `
        -Headers $Headers `
        -Body $LogBody `
        -ContentType "application/json"

} catch {
    Write-Error "セットアップエラー: $_"
}
```

### シナリオ2: 管理者によるPC情報一括登録

```bash
# Bashスクリプト例

API_TOKEN="your-api-token"
API_BASE_URL="http://drbl-server:5000/api"

# CSVファイルから一括登録
curl -X POST \
  "$API_BASE_URL/import" \
  -H "Authorization: Bearer $API_TOKEN" \
  -F "file=@pc_list.csv"

# 結果確認
curl -X GET \
  "$API_BASE_URL/deployments?limit=10" \
  -H "Authorization: Bearer $API_TOKEN"
```

### シナリオ3: エラーハンドリング付きリクエスト

```powershell
function Get-PCInfoWithRetry {
    param(
        [string]$Serial,
        [int]$MaxRetries = 3
    )

    $Headers = @{
        "Authorization" = "Bearer your-api-token"
    }

    for ($i = 0; $i -lt $MaxRetries; $i++) {
        try {
            $Response = Invoke-RestMethod `
                -Uri "http://drbl-server:5000/api/pcinfo?serial=$Serial" `
                -Method GET `
                -Headers $Headers `
                -TimeoutSec 30

            return $Response.data

        } catch {
            $StatusCode = $_.Exception.Response.StatusCode.value__

            switch ($StatusCode) {
                401 {
                    Write-Error "認証エラー: APIトークンを確認してください"
                    break
                }
                404 {
                    Write-Error "シリアル番号 $Serial は登録されていません"
                    break
                }
                500 {
                    Write-Warning "サーバーエラー。リトライします... ($($i+1)/$MaxRetries)"
                    Start-Sleep -Seconds (2 * ($i + 1))
                }
                default {
                    Write-Error "予期しないエラー: $_"
                    break
                }
            }
        }
    }

    throw "最大リトライ回数に達しました"
}
```

---

## APIテスト

### Postmanコレクション

```json
{
  "info": {
    "name": "PC Setup API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Get PC Info",
      "request": {
        "method": "GET",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{api_token}}"
          }
        ],
        "url": {
          "raw": "{{base_url}}/api/pcinfo?serial={{serial}}",
          "host": ["{{base_url}}"],
          "path": ["api", "pcinfo"],
          "query": [
            {
              "key": "serial",
              "value": "{{serial}}"
            }
          ]
        }
      }
    }
  ]
}
```

### pytest テスト例

```python
import pytest
import requests

BASE_URL = "http://drbl-server:5000/api"
API_TOKEN = "your-api-token"

def test_get_pc_info():
    """PC情報取得APIのテスト"""
    headers = {"Authorization": f"Bearer {API_TOKEN}"}
    response = requests.get(
        f"{BASE_URL}/pcinfo",
        params={"serial": "ABC123456"},
        headers=headers
    )

    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert "pcname" in data["data"]
    assert "odj_path" in data["data"]

def test_post_log():
    """ログ記録APIのテスト"""
    headers = {
        "Authorization": f"Bearer {API_TOKEN}",
        "Content-Type": "application/json"
    }
    payload = {
        "serial": "ABC123456",
        "pcname": "20251116M",
        "status": "completed",
        "timestamp": "2025-11-16 14:30:00"
    }

    response = requests.post(
        f"{BASE_URL}/log",
        json=payload,
        headers=headers
    )

    assert response.status_code == 201
    data = response.json()
    assert data["status"] == "success"
```

---

## 変更履歴

| バージョン | 日付 | 変更内容 |
|-----------|------|---------|
| 1.0 | 2025-11-16 | 初版リリース |

---

## サポート

API に関する問い合わせ:
- Email: it-support@company.com
- Slack: #pc-setup-automation
