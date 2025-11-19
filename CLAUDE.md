# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

本プロジェクトは、**会社キッティング自動化フレームワーク**の設計・実装プロジェクトです。年間100台規模のWindows PCを完全自動でキッティングするシステムで、「LANに挿して電源を入れるだけ」で以下のすべてを自動化します：

- PXEブート → Clonezillaによるマスターイメージ展開
- PC名の自動設定（命名規則: YYYYMMDDM、例: 20251116M）
- ODJ（Offline Domain Join）によるドメイン参加
- Windows Update
- 会社標準アプリケーションの導入

## システムアーキテクチャ（4レイヤー構造）

### 1. マスターPC構築レイヤー
- Windows 11ベースのマスターPC作成
- 会社標準構成（Microsoft 365 Apps、セキュリティソフト等）を実装
- Sysprep実行 → Clonezillaでイメージ化

### 2. 前処理レイヤー（箱OCR）
- PCの箱側面にあるSerial番号をスマホで撮影
- ChatGPT OCRでSerial番号抽出
- 導入日ベースでPC名自動生成（YYYYMMDDM）
- CSV生成（PC名, Serial）

### 3. インフラレイヤー（DRBL/Clonezilla + 管理GUI）
- **DRBLサーバ**（Ubuntu）: PXEブート環境、マスターイメージ保持、10〜20台同時展開
- **管理Webアプリケーション**（Flask想定）: Serial番号とPC名の管理、ODJファイルアップロード・紐付け
- **管理データベース**: SQLite or PostgreSQL（pc_master, setup_logs テーブル）
- **REST API**: `/api/pcinfo?serial=XXX` → PC名とODJパス返却、`/api/log` → セットアップログ登録

### 4. 実行レイヤー（PXE → 完全自動化）
- PXEブート → Clonezillaイメージ展開
- Windows初回起動後の自動処理（PowerShell）:
  - Serial番号取得（`Get-CimInstance Win32_BIOS`）
  - DRBL APIへ問い合わせ
  - PC名設定（`Rename-Computer`）
  - ODJファイル取得・適用（`djoin /requestODJ /loadfile`）
  - 再起動後、Windows Update + アプリ導入 + 完了ログ送信

## 主要コンポーネント

### DRBL管理GUIアプリケーション（Flask想定）
- **技術スタック**: Flask, SQLite/PostgreSQL, Bootstrap
- **主要機能**:
  - PC名・Serial・ODJファイルの管理
  - CSVインポート（100台以上の一括登録）
  - APIエンドポイント提供
  - セットアップログ記録

### データベーススキーマ

**pc_masterテーブル**:
- id (INTEGER PK)
- serial (TEXT UNIQUE) - PCシリアル番号
- pcname (TEXT) - PC名（YYYYMMDDM形式）
- odj_path (TEXT) - ODJファイルパス
- created_at (DATETIME)

**setup_logsテーブル**:
- id (INTEGER PK)
- serial (TEXT)
- pcname (TEXT)
- status (TEXT) - セットアップ状態
- timestamp (DATETIME)
- logs (TEXT) - 任意のログ文字列

### REST API仕様

**GET /api/pcinfo**:
```
リクエスト: GET /api/pcinfo?serial=ABC123456
レスポンス: {"pcname": "20251116M", "odj_path": "/odj/20251116M.txt"}
```

**POST /api/log**:
```
リクエスト: POST /api/log
Body: {"serial": "ABC123456", "pcname": "20251116M", "status": "completed", "timestamp": "2025-11-16 12:33:22"}
レスポンス: {"result":"ok"}
```

### PowerShell自動セットアップスクリプト

主要関数構成:
- `Get-SerialNumber`: BIOS Serial取得
- `Get-PCInfoFromAPI`: API `/pcinfo` へアクセス
- `Set-PCName`: PC名設定（Rename-Computer）
- `Apply-ODJ`: djoin実行
- `Run-WindowsUpdate`: PSWindowsUpdateモジュール使用
- `Install-Apps`: 会社標準アプリのサイレントインストール
- `Send-SetupLog`: API `/log` へPOST

## PC命名規則

**YYYYMMDDM形式**:
- YYYY: 導入年（4桁）
- MM: 導入月（2桁）
- DD: 導入日（2桁）
- M: 固定サフィックス

例: 2025年11月16日導入 → `20251116M`

## セキュリティ考慮事項

- ChatGPTへはSerial番号のみ送信（機微情報なし）
- API通信は社内LANのみ
- ODJファイルは権限付きフォルダに保存
- 展開後スクリプトは署名/ハッシュ検証を実装

## 非機能要件

- **Sysprep成功率**: 100%
- **API応答時間**: 200ms以下（LAN環境）
- **同時展開**: 10〜20台（性能劣化1台あたり20%以内）
- **展開時間**: 開始から完了まで60〜90分以内
- **展開失敗率**: 1%未満
- **OCR精度**: 99%以上

## 開発時の注意事項

### マスターPC構築時
- AppX除外処理を含むSysprep前処理を確実に実施
- unattend.xmlは自動ログオン設定を含める
- マスターイメージ更新は年数回を想定

### DRBL/Clonezillaサーバ
- マスターイメージ格納先: `/home/partimag/`
- ODJファイル格納先: `/srv/odj/` 推奨
- 圧縮形式: zstd or gzip

### PowerShellスクリプト
- エラーハンドリング: DRBL API不応答時3回リトライ
- PC名取得不可時は管理GUIへエラー送信
- ODJ適用失敗時はWindowsイベントログ送信
- Windows Update は複数回ループ対応（更新完了まで）

### 異常系処理
- API不応答 → 3回リトライ後エラーログ
- Serial番号取得失敗 → 手動介入通知
- ODJ適用失敗 → イベントログ記録 + 管理GUI通知

## ディレクトリ構造（想定）

```
/
├── docs/                    # 設計ドキュメント類（本リポジトリ）
├── drbl-server/            # DRBLサーバ設定ファイル
├── flask-app/              # Flask管理Webアプリケーション
│   ├── app.py
│   ├── models.py
│   ├── api.py
│   ├── templates/
│   └── static/
├── powershell-scripts/     # Windows初期セットアップスクリプト
│   ├── setup.ps1
│   ├── modules/
│   └── config/
├── master-pc/              # マスターPC構築用スクリプト・設定
│   ├── sysprep/
│   └── unattend.xml
└── odj-files/              # ODJファイル格納（実環境では/srv/odj/等）
```

## 将来の拡張性

- 展開ステータスダッシュボード
- 自動メール通知
- Microsoft Intune連携
- PXEメニュー管理UI
