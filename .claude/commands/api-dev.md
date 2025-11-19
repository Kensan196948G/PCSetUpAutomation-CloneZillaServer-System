---
description: API開発モード（GET /api/pcinfo, POST /api/log）
---

DRBL管理APIの開発を開始します。

**api-developer** エージェントを起動して、以下のAPIエンドポイントを実装してください：

## 1. GET /api/pcinfo
- **目的**: Serial番号からPC名とODJファイルパスを取得
- **パラメータ**: serial (クエリパラメータ、必須)
- **レスポンス**: JSON形式
  ```json
  {
    "pcname": "20251116M",
    "odj_path": "/odj/20251116M.txt"
  }
  ```
- **エラー**: 404 Not Found（Serial番号が未登録の場合）

## 2. POST /api/log
- **目的**: セットアップ完了ログを記録
- **リクエストボディ**: JSON形式
  ```json
  {
    "serial": "ABC123456",
    "pcname": "20251116M",
    "status": "completed",
    "timestamp": "2025-11-16 12:33:22"
  }
  ```
- **レスポンス**: `{"result": "ok"}`

## 実装要件
- バリデーション実装
- エラーハンドリング
- ロギング
- ユニットテスト作成

完了後、APIテストコードも作成してください。
