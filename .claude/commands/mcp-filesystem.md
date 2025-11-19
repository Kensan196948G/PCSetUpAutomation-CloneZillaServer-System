---
description: Filesystemで高度なファイルシステム操作を実行
---

**Filesystem MCPサーバ**を使用して、高度なファイル・ディレクトリ操作を実行します。

## 使用方法
このコマンドの後に、実行したいファイル操作を指定してください。

## 主な機能

### 1. ディレクトリ管理
- 再帰的ディレクトリ作成
- ディレクトリツリー表示
- 一括ディレクトリ作成

### 2. ファイル操作
- 複数ファイル同時読み込み
- ファイル検索・フィルタリング
- ファイル情報取得（サイズ、権限等）

### 3. バックアップ・リストア
- 設定ファイルバックアップ
- ODJファイル管理
- ログファイル整理

### 4. 一括操作
- パターンマッチによるファイル検索
- 大量ファイルの移動・コピー
- ディレクトリサイズ計算

## 利用可能な主要ツール

- `mcp__filesystem__list_directory`: ディレクトリ一覧
- `mcp__filesystem__directory_tree`: ディレクトリツリー
- `mcp__filesystem__read_multiple_files`: 複数ファイル読み込み
- `mcp__filesystem__search_files`: ファイル検索
- `mcp__filesystem__create_directory`: ディレクトリ作成
- `mcp__filesystem__move_file`: ファイル移動
- `mcp__filesystem__get_file_info`: ファイル情報取得

## 例

### プロジェクト構造作成
```
/mcp-filesystem
以下のディレクトリ構造を一括作成してください:
- flask-app/models
- flask-app/views
- flask-app/static
- flask-app/templates
- powershell-scripts/modules
- tests/unit
- tests/integration
```

### ODJファイル管理
```
/mcp-filesystem
/srv/odj/ ディレクトリ内のすべてのODJファイルを検索し、ファイル数とサイズを報告してください
```

### 設定ファイルバックアップ
```
/mcp-filesystem
flask-app/config/ 内のすべての設定ファイルを /backup/config-YYYYMMDD/ にバックアップしてください
```

### ログファイル整理
```
/mcp-filesystem
/var/log/kitting/ 内の30日以上前のログファイルを /archive/ に移動してください
```

### ディレクトリサイズ確認
```
/mcp-filesystem
/home/partimag/ ディレクトリのサイズとファイル数を計算してください
```

### 複数設定ファイル一括読み込み
```
/mcp-filesystem
flask-app/config/*.json の全ファイルを同時に読み込んで内容を確認してください
```

Filesystemで効率的なファイル管理を実現します。
