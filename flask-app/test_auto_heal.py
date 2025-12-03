"""
テスト用ファイル - 自動修復システムの動作確認用

このファイルには意図的にエラーが含まれています：
1. 未使用インポート
2. 未定義変数（修復不可能なエラー）
3. インデント問題
"""

# エラー1: 未使用インポート（自動修復可能）
import os
import sys
from datetime import datetime
from typing import List, Dict

# エラー2: 未定義変数（修復不可能 - Issue作成されるべき）
def test_function():
    result = undefined_variable  # これは自動修復できない
    return result

# エラー3: インデント問題（自動修復可能）
def another_function():
 return True  # インデントが不足（2スペースのはず4スペース）

# エラー4: 不足インポート（修復可能な場合がある）
def get_current_time():
    # datetimeはインポート済みなので問題なし
    return datetime.now()
