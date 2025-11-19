# コードスタイルと規約

## Python コーディング規約

### 一般規約
- **PEP 8準拠**: Pythonコーディング標準に従う
- **文字エンコーディング**: UTF-8

### 命名規則
- **関数・変数**: snake_case
  - 例: `get_pc_info()`, `serial_number`, `odj_path`
- **クラス**: PascalCase
  - 例: `PCMaster`, `SetupLog`
- **定数**: UPPER_SNAKE_CASE
  - 例: `MAX_RETRY_COUNT`, `API_TIMEOUT`
- **プライベート**: アンダースコアプレフィックス
  - 例: `_internal_function()`, `_private_var`

### 型ヒント
- **使用を推奨**: 関数の引数と戻り値に型ヒントを使用
```python
def get_pc_info(serial: str) -> dict:
    """PC情報を取得"""
    pass
```

### ドキュメント文字列（Docstrings）
- **Google スタイル**のdocstringsを使用
```python
def create_app(config_name: str = 'default') -> Flask:
    """Create Flask application for testing.

    Args:
        config_name: 設定名（'testing', 'development', 'production'）

    Returns:
        Flask app instance configured for testing
    """
    pass
```

### インポート
- **標準ライブラリ → サードパーティ → ローカルモジュール** の順
- 各グループ内はアルファベット順
```python
import sys
from pathlib import Path

import pytest
from flask import Flask

from models import db
```

### エラーハンドリング
- 明示的な例外処理を実装
- ログ記録を含める
```python
try:
    result = api_call()
except Exception as e:
    logger.error(f"API呼び出し失敗: {e}")
    raise
```

### データベースモデル
- **SQLAlchemy ORM**を使用
- テーブル名は小文字、複数形
- カラム名はsnake_case

### API設計
- **RESTful**な設計
- HTTPステータスコードを適切に使用
- JSONレスポンス形式を統一

## PowerShell コーディング規約

### 命名規則
- **関数**: Verb-Noun形式、PascalCase
  - 例: `Get-SerialNumber`, `Set-PCName`, `Apply-ODJ`
- **変数**: camelCase
  - 例: `$serialNumber`, `$pcInfo`

### エラーハンドリング
- `Try-Catch`ブロックを使用
- リトライロジックを実装（3回まで）
- イベントログへの記録

## コミット規約

### コミットメッセージ形式
```
<type>: <subject>

<body>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Type
- `feat`: 新機能
- `fix`: バグ修正
- `refactor`: リファクタリング
- `test`: テスト追加・修正
- `docs`: ドキュメント更新
- `chore`: ビルドプロセスやツールの変更

## テストコード規約

### テストファイル命名
- `test_*.py`形式
- テスト対象モジュール名に`test_`プレフィックス

### テスト関数命名
- `test_<機能名>_<条件>_<期待結果>`
```python
def test_get_pcinfo_valid_serial_returns_pc_data():
    """有効なSerial番号でPC情報が返却されること"""
    pass
```

### フィクスチャ
- conftest.pyで共通フィクスチャを定義
- 再利用可能な設計

### アサーション
- 明確なアサーションメッセージ
```python
assert result['pcname'] == '20251116M', "PC名が一致しません"
```
