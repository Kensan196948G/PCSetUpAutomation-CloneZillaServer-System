# プロジェクト概要

## プロジェクト名
**PC Setup Automation - Clonezilla Server Project**
会社キッティング自動化フレームワーク

## プロジェクトの目的
年間100台規模のWindows PCを完全自動でキッティングするシステム。
「LANに挿して電源を入れるだけ」で以下を自動化：
- PXEブート → Clonezillaによるマスターイメージ展開
- PC名の自動設定（命名規則: YYYYMMDDM）
- ODJ（Offline Domain Join）によるドメイン参加
- Windows Update自動実行
- 会社標準アプリケーションの自動導入
- セットアップログの自動記録

## 技術スタック

### バックエンド
- **Python**: 3.12
- **Flask**: 3.1.1
- **データベース**: SQLite（開発）/ PostgreSQL（本番）
- **ORM**: Flask-SQLAlchemy 3.1.1

### フロントエンド
- Bootstrap（管理WebUI）
- HTML/CSS/JavaScript（テンプレート）

### インフラ
- **OS**: Ubuntu 22.04 LTS
- **DRBL/Clonezilla**: PXEブート環境、マスターイメージ展開
- **TFTP**: PXEブート用
- **DHCP**: isc-dhcp-server
- **NFS**: イメージ配信用
- **Nginx**: Webサーバ（本番環境）

### Windows自動化
- **PowerShell**: 7.x
- Windows初回起動時の自動セットアップスクリプト

### テスト
- **pytest**: 7.4.3
- **pytest-cov**: 4.1.0（カバレッジ）
- **pytest-flask**: 1.3.0
- **pytest-mock**: 3.12.0
- **pytest-benchmark**: 4.0.0（パフォーマンステスト）

## システムアーキテクチャ（4レイヤー構造）

### 1. マスターPC構築レイヤー
- Windows 11ベースのマスターPC作成
- Sysprep実行 → Clonezillaでイメージ化

### 2. 前処理レイヤー（箱OCR）
- ChatGPT OCRでSerial番号抽出
- 導入日ベースでPC名自動生成（YYYYMMDDM）

### 3. インフラレイヤー（DRBL/Clonezilla + 管理GUI）
- DRBLサーバ: PXEブート環境、10〜20台同時展開
- Flask管理Webアプリケーション: Serial番号とPC名の管理
- REST API: `/api/pcinfo`、`/api/log`

### 4. 実行レイヤー（PXE → 完全自動化）
- PXEブート → Clonezillaイメージ展開
- Windows初回起動後の自動処理（PowerShell）

## 非機能要件
- **Sysprep成功率**: 100%
- **API応答時間**: 200ms以下（LAN環境）
- **同時展開**: 10〜20台
- **展開時間**: 60〜90分以内
- **展開失敗率**: 1%未満
