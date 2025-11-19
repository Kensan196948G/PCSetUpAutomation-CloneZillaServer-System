"""Pytest configuration and fixtures."""
import os
import sys
import tempfile
import pytest
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app import create_app
from models import db, PCMaster, SetupLog


@pytest.fixture(scope='session')
def app():
    """Create and configure test application instance.

    This fixture is session-scoped, meaning it's created once
    for the entire test session.
    """
    # Create temporary directory for test files
    temp_dir = tempfile.mkdtemp()

    # Create test app
    test_app = create_app('testing')

    # Override config for testing
    test_app.config.update({
        'TESTING': True,
        'WTF_CSRF_ENABLED': False,
        'ODJ_FILES_PATH': os.path.join(temp_dir, 'odj'),
        'CLONEZILLA_IMAGE_PATH': os.path.join(temp_dir, 'images'),
    })

    # Create test directories
    os.makedirs(test_app.config['ODJ_FILES_PATH'], exist_ok=True)
    os.makedirs(test_app.config['CLONEZILLA_IMAGE_PATH'], exist_ok=True)

    yield test_app

    # Cleanup
    import shutil
    shutil.rmtree(temp_dir, ignore_errors=True)


@pytest.fixture(scope='function')
def app_context(app):
    """Create application context for each test."""
    with app.app_context():
        yield app


@pytest.fixture(scope='function')
def db_session(app_context):
    """Create database session for each test.

    This fixture creates fresh database tables before each test
    and drops them after the test completes.
    """
    db.create_all()
    yield db
    db.session.remove()
    db.drop_all()


@pytest.fixture(scope='function')
def client(app, db_session):
    """Create test client for making HTTP requests."""
    return app.test_client()


@pytest.fixture(scope='function')
def runner(app):
    """Create CLI test runner."""
    return app.test_cli_runner()


@pytest.fixture
def sample_pc_data():
    """Sample PC data for testing."""
    return {
        'serial': 'ABC123456',
        'pcname': '20251116M',
        'odj_path': '/srv/odj/20251116M.txt'
    }


@pytest.fixture
def sample_pcs_data():
    """Sample multiple PCs data for testing."""
    return [
        {
            'serial': f'SN{str(i).zfill(8)}',
            'pcname': f'2025111{i % 10}M',
            'odj_path': f'/srv/odj/2025111{i % 10}M.txt'
        }
        for i in range(10)
    ]


@pytest.fixture
def create_test_pc(db_session):
    """Factory fixture to create test PC records."""
    def _create_pc(serial='TEST123', pcname='20251116M', odj_path=None):
        pc = PCMaster(
            serial=serial,
            pcname=pcname,
            odj_path=odj_path
        )
        db_session.session.add(pc)
        db_session.session.commit()
        return pc

    return _create_pc


@pytest.fixture
def create_test_log(db_session):
    """Factory fixture to create test log records."""
    def _create_log(serial='TEST123', pcname='20251116M',
                    status='completed', logs='Test log'):
        log = SetupLog(
            serial=serial,
            pcname=pcname,
            status=status,
            logs=logs
        )
        db_session.session.add(log)
        db_session.session.commit()
        return log

    return _create_log


@pytest.fixture
def csv_file_content():
    """Generate CSV file content for testing."""
    def _generate_csv(rows=10):
        lines = ['serial,pcname,odj_path']
        for i in range(rows):
            lines.append(
                f'SN{str(i).zfill(8)},'
                f'2025111{i % 10}M,'
                f'/srv/odj/2025111{i % 10}M.txt'
            )
        return '\n'.join(lines)

    return _generate_csv


@pytest.fixture
def odj_file_content():
    """Generate ODJ file content for testing."""
    return """<?xml version="1.0" encoding="utf-8"?>
<OfflineDomainJoin>
    <DomainJoin>
        <ComputerName>20251116M</ComputerName>
        <Domain>example.com</Domain>
    </DomainJoin>
</OfflineDomainJoin>"""
