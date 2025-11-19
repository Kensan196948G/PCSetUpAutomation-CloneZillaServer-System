#!/usr/bin/env python3
"""本番環境用Flaskアプリケーション起動スクリプト"""

import os
import sys
from pathlib import Path

# プロジェクトルートをPythonパスに追加
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

# 本番環境設定を読み込み
os.environ['FLASK_ENV'] = 'production'
os.environ['FLASK_APP'] = 'app.py'

# アプリケーションファクトリーパターンでアプリ作成
from app import create_app

if __name__ == '__main__':
    # 本番環境アプリケーション作成
    app = create_app('production')

    # 本番環境用ポート8000で起動
    print("=" * 60)
    print("🚀 本番環境用Flask Webアプリケーション起動中...")
    print("=" * 60)
    print(f"環境: 本番（Production）")
    print(f"ポート: 8000")
    print(f"URL: http://192.168.3.135:8000/")
    print(f"デバッグモード: OFF")
    print("=" * 60)

    app.run(
        host='0.0.0.0',
        port=8000,
        debug=False,
        use_reloader=False
    )
