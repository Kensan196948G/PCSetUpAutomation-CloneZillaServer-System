---
description: Serenaでコードベース全体をセマンティック解析
---

**Serena MCPサーバ**を使用して、コードベース全体を深く理解・解析します。

## 使用方法
このコマンドの後に、解析したい内容を指定してください。

## 主な機能

### 1. シンボル検索・解析
- クラス、関数、メソッドの定義を検索
- 依存関係の追跡
- 呼び出し元の特定

### 2. コード構造理解
- ファイル構造の可視化
- モジュール間の関係性
- アーキテクチャパターンの分析

### 3. リファクタリング
- シンボル名の一括変更
- コードパターンの検索・置換
- デッドコードの検出

### 4. ドキュメント生成
- コードからドキュメント自動生成
- API仕様の抽出
- 依存関係図作成

## 利用可能なSerenaツール

- `mcp__serena__list_dir`: ディレクトリ一覧
- `mcp__serena__find_file`: ファイル検索
- `mcp__serena__search_for_pattern`: パターン検索
- `mcp__serena__get_symbols_overview`: シンボル概要
- `mcp__serena__find_symbol`: シンボル検索
- `mcp__serena__find_referencing_symbols`: 参照元検索
- `mcp__serena__replace_symbol_body`: シンボル置換
- `mcp__serena__insert_after_symbol`: コード挿入
- `mcp__serena__rename_symbol`: シンボル名変更

## 例

### Flask APIエンドポイント全検索
```
/mcp-serena
flask-appディレクトリ内のすべてのAPIエンドポイント関数を検索して一覧化してください
```

### データベースモデル解析
```
/mcp-serena
pc_masterモデルを参照しているすべてのコードを検索してください
```

### PowerShellスクリプト構造解析
```
/mcp-serena
powershell-scripts/内のすべての関数と依存関係を解析してください
```

### リファクタリング
```
/mcp-serena
Get-PCInfo関数をGet-ComputerInformationに一括リネームしてください
```

Serenaのセマンティック解析により、コードベース全体を深く理解できます。
