"""本番環境用Flask設定ファイル"""
import os
from datetime import timedelta

class ProductionConfig:
    """本番環境設定"""

    # 基本設定
    ENV = 'production'
    DEBUG = False
    TESTING = False

    # セキュリティ
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'production-secret-key-change-this-in-env'

    # データベース
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or \
        'sqlite:///./instance/production.db'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ECHO = False

    # サーバ設定
    SERVER_NAME = None  # Nginxでリバースプロキシする場合に設定
    PREFERRED_URL_SCHEME = 'http'  # HTTPSの場合は 'https'

    # セッション設定
    PERMANENT_SESSION_LIFETIME = timedelta(minutes=30)
    SESSION_COOKIE_SECURE = False  # HTTPSの場合はTrue
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = 'Lax'

    # アップロード設定
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB
    UPLOAD_FOLDER = os.path.join(os.path.dirname(__file__), 'static', 'uploads')

    # ログ設定
    LOG_LEVEL = 'INFO'
    LOG_FILE = '/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/logs/flask/app.log'

    # CORS設定（本番では無効化推奨）
    CORS_ENABLED = False

    # API設定
    API_RATE_LIMIT = '1000 per hour'
    API_TOKEN = os.environ.get('API_TOKEN') or 'production-api-token'

    # ODJファイル設定
    ODJ_STORAGE_PATH = '/srv/odj'

    # Clonezillaイメージ設定
    CLONEZILLA_IMAGE_PATH = '/home/partimag'

    # 本番環境フラグ
    IS_PRODUCTION = True

    # ページネーション
    ITEMS_PER_PAGE = 50

    # タイムゾーン
    TIMEZONE = 'Asia/Tokyo'
