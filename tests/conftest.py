"""Pytest configuration and fixtures."""
import pytest
import sys
from pathlib import Path

# Add flask-app to Python path
flask_app_path = Path(__file__).parent.parent / 'flask-app'
sys.path.insert(0, str(flask_app_path))


@pytest.fixture
def app():
    """Create Flask application for testing.

    Returns:
        Flask app instance configured for testing
    """
    from app import create_app
    app = create_app('testing')

    with app.app_context():
        from models import db
        db.create_all()

    yield app

    with app.app_context():
        db.drop_all()


@pytest.fixture
def client(app):
    """Create Flask test client.

    Args:
        app: Flask application fixture

    Returns:
        Flask test client
    """
    return app.test_client()


@pytest.fixture
def runner(app):
    """Create Flask CLI runner.

    Args:
        app: Flask application fixture

    Returns:
        Flask CLI runner
    """
    return app.test_cli_runner()


@pytest.fixture
def sample_pc_data():
    """Sample PC data for testing.

    Returns:
        dict: Sample PC information
    """
    return {
        'serial': 'TEST123456',
        'pcname': '20251116M',
        'odj_path': '/srv/odj/20251116M.txt'
    }


@pytest.fixture
def sample_log_data():
    """Sample setup log data for testing.

    Returns:
        dict: Sample setup log
    """
    return {
        'serial': 'TEST123456',
        'pcname': '20251116M',
        'status': 'completed',
        'timestamp': '2025-11-16 12:33:22',
        'logs': 'Setup completed successfully',
        'step': 'windows_update'
    }
