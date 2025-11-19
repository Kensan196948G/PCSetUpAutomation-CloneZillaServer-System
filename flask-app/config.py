"""Flask application configuration."""
import os
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
basedir = Path(__file__).resolve().parent.parent
load_dotenv(basedir / '.env')


class Config:
    """Base configuration."""

    # Flask
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')

    # Database
    SQLALCHEMY_DATABASE_URI = os.getenv(
        'DATABASE_URL',
        f'sqlite:///{basedir}/pc_setup.db'
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ECHO = False

    # API
    API_HOST = os.getenv('API_HOST', '0.0.0.0')
    API_PORT = int(os.getenv('API_PORT', 5000))

    # ODJ Files
    ODJ_FILES_PATH = os.getenv('ODJ_FILES_PATH', '/srv/odj/')

    # Clonezilla Images
    CLONEZILLA_IMAGE_PATH = os.getenv(
        'CLONEZILLA_IMAGE_PATH',
        '/mnt/Linux-ExHDD/Ubuntu-ExHDD'
    )

    # Logging
    LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
    LOG_FILE = os.getenv('LOG_FILE', 'logs/app.log')

    # CORS
    CORS_ENABLED = os.getenv('CORS_ENABLED', 'false').lower() == 'true'
    CORS_ORIGINS = os.getenv(
        'CORS_ORIGINS',
        'http://localhost:5000'
    ).split(',')

    # Security
    SESSION_COOKIE_SECURE = os.getenv(
        'SESSION_COOKIE_SECURE',
        'false'
    ).lower() == 'true'
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = 'Lax'

    # PowerShell Scripts
    PS_SCRIPT_PATH = os.getenv(
        'PS_SCRIPT_PATH',
        '/opt/pc-setup/powershell-scripts/'
    )
    PS_LOG_PATH = os.getenv('PS_LOG_PATH', '/var/log/pc-setup/')

    # Windows Update
    WINDOWS_UPDATE_RETRY = int(os.getenv('WINDOWS_UPDATE_RETRY', 3))
    WINDOWS_UPDATE_TIMEOUT = int(os.getenv('WINDOWS_UPDATE_TIMEOUT', 3600))

    # Domain Settings
    DOMAIN_NAME = os.getenv('DOMAIN_NAME', 'example.com')
    DOMAIN_OU = os.getenv(
        'DOMAIN_OU',
        'OU=Computers,DC=example,DC=com'
    )

    # File Upload Settings
    MAX_CONTENT_LENGTH = int(os.getenv(
        'MAX_CONTENT_LENGTH',
        100 * 1024 * 1024  # 100MB default
    ))
    UPLOAD_FOLDER = os.getenv('UPLOAD_FOLDER', '/tmp/uploads/')
    ALLOWED_EXTENSIONS = {
        'csv': ['text/csv', 'application/vnd.ms-excel'],
        'txt': ['text/plain'],
        'odj': ['text/plain']
    }


class DevelopmentConfig(Config):
    """Development configuration."""
    ENV = 'development'
    DEBUG = True
    SQLALCHEMY_ECHO = True


class ProductionConfig(Config):
    """Production configuration."""
    ENV = 'production'
    DEBUG = False
    TESTING = False
    SESSION_COOKIE_SECURE = True


class TestingConfig(Config):
    """Testing configuration."""
    ENV = 'testing'
    TESTING = True
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'
    SQLALCHEMY_ECHO = False
    WTF_CSRF_ENABLED = False
    LOG_LEVEL = 'DEBUG'


# Configuration dictionary
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}
