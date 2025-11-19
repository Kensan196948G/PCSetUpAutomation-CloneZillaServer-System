"""Unit tests for API endpoints."""
import pytest
import json
from datetime import datetime


class TestPCInfoAPI:
    """Tests for GET /api/pcinfo endpoint."""

    def test_get_pcinfo_success(self, client, app, sample_pc_data):
        """Test successful PC info retrieval."""
        # Setup: Create a PC in database
        with app.app_context():
            from models import db, PCMaster
            pc = PCMaster(
                serial=sample_pc_data['serial'],
                pcname=sample_pc_data['pcname'],
                odj_path=sample_pc_data['odj_path']
            )
            db.session.add(pc)
            db.session.commit()

        # Test: Get PC info
        response = client.get(f'/api/pcinfo?serial={sample_pc_data["serial"]}')

        # Assert
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['pcname'] == sample_pc_data['pcname']
        assert data['odj_path'] == sample_pc_data['odj_path']

    def test_get_pcinfo_not_found(self, client):
        """Test PC not found scenario."""
        # Test: Get non-existent PC
        response = client.get('/api/pcinfo?serial=NONEXISTENT')

        # Assert
        assert response.status_code == 404
        data = json.loads(response.data)
        assert 'error' in data
        assert data['error'] == 'Not Found'

    def test_get_pcinfo_missing_serial(self, client):
        """Test missing serial parameter."""
        # Test: No serial parameter
        response = client.get('/api/pcinfo')

        # Assert
        assert response.status_code == 400
        data = json.loads(response.data)
        assert 'error' in data
        assert data['error'] == 'Bad Request'

    def test_get_pcinfo_invalid_serial(self, client):
        """Test invalid serial format."""
        # Test: Invalid serial with special characters
        response = client.get('/api/pcinfo?serial=ABC@#$%')

        # Assert
        assert response.status_code == 400
        data = json.loads(response.data)
        assert 'error' in data

    def test_get_pcinfo_empty_serial(self, client):
        """Test empty serial parameter."""
        # Test: Empty serial
        response = client.get('/api/pcinfo?serial=')

        # Assert
        assert response.status_code == 400
        data = json.loads(response.data)
        assert 'error' in data


class TestLogAPI:
    """Tests for POST /api/log endpoint."""

    def test_post_log_success(self, client, sample_log_data):
        """Test successful log creation."""
        # Test: Create log entry
        response = client.post(
            '/api/log',
            data=json.dumps(sample_log_data),
            content_type='application/json'
        )

        # Assert
        assert response.status_code == 201
        data = json.loads(response.data)
        assert data['result'] == 'ok'
        assert 'log_id' in data
        assert isinstance(data['log_id'], int)

    def test_post_log_invalid_json(self, client):
        """Test invalid JSON in request body."""
        # Test: Send invalid JSON
        response = client.post(
            '/api/log',
            data='invalid json',
            content_type='application/json'
        )

        # Assert
        assert response.status_code == 400
        data = json.loads(response.data)
        assert 'error' in data

    def test_post_log_missing_fields(self, client):
        """Test missing required fields."""
        # Test: Missing status field
        incomplete_data = {
            'serial': 'TEST123',
            'pcname': '20251116M',
            'timestamp': '2025-11-16 12:33:22'
            # Missing 'status'
        }

        response = client.post(
            '/api/log',
            data=json.dumps(incomplete_data),
            content_type='application/json'
        )

        # Assert
        assert response.status_code == 400
        data = json.loads(response.data)
        assert 'error' in data
        assert 'status' in data['message']

    def test_post_log_invalid_status(self, client):
        """Test invalid status value."""
        # Test: Invalid status
        invalid_data = {
            'serial': 'TEST123',
            'pcname': '20251116M',
            'status': 'invalid_status',
            'timestamp': '2025-11-16 12:33:22'
        }

        response = client.post(
            '/api/log',
            data=json.dumps(invalid_data),
            content_type='application/json'
        )

        # Assert
        assert response.status_code == 400
        data = json.loads(response.data)
        assert 'error' in data

    def test_post_log_invalid_timestamp(self, client):
        """Test invalid timestamp format."""
        # Test: Invalid timestamp
        invalid_data = {
            'serial': 'TEST123',
            'pcname': '20251116M',
            'status': 'completed',
            'timestamp': 'invalid-timestamp'
        }

        response = client.post(
            '/api/log',
            data=json.dumps(invalid_data),
            content_type='application/json'
        )

        # Assert
        assert response.status_code == 400
        data = json.loads(response.data)
        assert 'error' in data

    def test_post_log_with_optional_fields(self, client):
        """Test log creation with all optional fields."""
        # Test: Complete log data with optional fields
        complete_data = {
            'serial': 'TEST123',
            'pcname': '20251116M',
            'status': 'failed',
            'timestamp': '2025-11-16 12:33:22',
            'logs': 'Setup failed at Windows Update',
            'step': 'windows_update',
            'error_message': 'Update server unreachable'
        }

        response = client.post(
            '/api/log',
            data=json.dumps(complete_data),
            content_type='application/json'
        )

        # Assert
        assert response.status_code == 201
        data = json.loads(response.data)
        assert data['result'] == 'ok'


class TestPCCRUDAPI:
    """Tests for PC CRUD endpoints."""

    def test_list_pcs_empty(self, client):
        """Test listing PCs when database is empty."""
        # Test: Get empty list
        response = client.get('/api/pcs')

        # Assert
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['items'] == []
        assert data['total'] == 0

    def test_list_pcs_with_data(self, client, app, sample_pc_data):
        """Test listing PCs with data."""
        # Setup: Create PCs
        with app.app_context():
            from models import db, PCMaster
            for i in range(3):
                pc = PCMaster(
                    serial=f'TEST{i}',
                    pcname=f'2025111{i}M',
                    odj_path=f'/srv/odj/2025111{i}M.txt'
                )
                db.session.add(pc)
            db.session.commit()

        # Test: Get list
        response = client.get('/api/pcs')

        # Assert
        assert response.status_code == 200
        data = json.loads(response.data)
        assert len(data['items']) == 3
        assert data['total'] == 3

    def test_list_pcs_pagination(self, client, app):
        """Test pagination."""
        # Setup: Create 25 PCs
        with app.app_context():
            from models import db, PCMaster
            for i in range(25):
                pc = PCMaster(
                    serial=f'TEST{i:03d}',
                    pcname=f'2025111{i % 10}M',
                    odj_path=f'/srv/odj/test{i}.txt'
                )
                db.session.add(pc)
            db.session.commit()

        # Test: Get first page
        response = client.get('/api/pcs?page=1&per_page=10')
        assert response.status_code == 200
        data = json.loads(response.data)
        assert len(data['items']) == 10
        assert data['total'] == 25
        assert data['pages'] == 3

        # Test: Get second page
        response = client.get('/api/pcs?page=2&per_page=10')
        assert response.status_code == 200
        data = json.loads(response.data)
        assert len(data['items']) == 10

    def test_create_pc_success(self, client, sample_pc_data):
        """Test successful PC creation."""
        # Test: Create PC
        response = client.post(
            '/api/pcs',
            data=json.dumps(sample_pc_data),
            content_type='application/json'
        )

        # Assert
        assert response.status_code == 201
        data = json.loads(response.data)
        assert data['result'] == 'ok'
        assert 'pc_id' in data
        assert data['pc']['serial'] == sample_pc_data['serial']

    def test_create_pc_duplicate(self, client, app, sample_pc_data):
        """Test creating duplicate PC."""
        # Setup: Create initial PC
        with app.app_context():
            from models import db, PCMaster
            pc = PCMaster(**sample_pc_data)
            db.session.add(pc)
            db.session.commit()

        # Test: Try to create duplicate
        response = client.post(
            '/api/pcs',
            data=json.dumps(sample_pc_data),
            content_type='application/json'
        )

        # Assert
        assert response.status_code == 409
        data = json.loads(response.data)
        assert 'error' in data
        assert data['error'] == 'Conflict'

    def test_update_pc_success(self, client, app, sample_pc_data):
        """Test successful PC update."""
        # Setup: Create PC
        with app.app_context():
            from models import db, PCMaster
            pc = PCMaster(**sample_pc_data)
            db.session.add(pc)
            db.session.commit()
            pc_id = pc.id

        # Test: Update PC
        update_data = {
            'pcname': '20251117M',
            'odj_path': '/srv/odj/20251117M.txt'
        }
        response = client.put(
            f'/api/pcs/{pc_id}',
            data=json.dumps(update_data),
            content_type='application/json'
        )

        # Assert
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['result'] == 'ok'
        assert data['pc']['pcname'] == update_data['pcname']

    def test_update_pc_not_found(self, client):
        """Test updating non-existent PC."""
        # Test: Update non-existent PC
        update_data = {'pcname': '20251117M'}
        response = client.put(
            '/api/pcs/9999',
            data=json.dumps(update_data),
            content_type='application/json'
        )

        # Assert
        assert response.status_code == 404
        data = json.loads(response.data)
        assert 'error' in data

    def test_delete_pc_success(self, client, app, sample_pc_data):
        """Test successful PC deletion."""
        # Setup: Create PC
        with app.app_context():
            from models import db, PCMaster
            pc = PCMaster(**sample_pc_data)
            db.session.add(pc)
            db.session.commit()
            pc_id = pc.id

        # Test: Delete PC
        response = client.delete(f'/api/pcs/{pc_id}')

        # Assert
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['result'] == 'ok'

        # Verify PC is deleted
        with app.app_context():
            from models import PCMaster
            pc = PCMaster.query.get(pc_id)
            assert pc is None

    def test_delete_pc_not_found(self, client):
        """Test deleting non-existent PC."""
        # Test: Delete non-existent PC
        response = client.delete('/api/pcs/9999')

        # Assert
        assert response.status_code == 404
        data = json.loads(response.data)
        assert 'error' in data


class TestValidators:
    """Tests for validation helpers."""

    def test_validate_serial(self):
        """Test serial number validation."""
        from api.validators import validate_serial

        # Valid serials
        assert validate_serial('ABC123')[0] is True
        assert validate_serial('TEST-123_456')[0] is True

        # Invalid serials
        assert validate_serial('')[0] is False
        assert validate_serial(None)[0] is False
        assert validate_serial('A' * 101)[0] is False
        assert validate_serial('ABC@#$')[0] is False

    def test_validate_pcname(self):
        """Test PC name validation."""
        from api.validators import validate_pcname

        # Valid PC names
        assert validate_pcname('20251116M')[0] is True
        assert validate_pcname('TEST-PC')[0] is True

        # Invalid PC names
        assert validate_pcname('')[0] is False
        assert validate_pcname(None)[0] is False
        assert validate_pcname('A' * 51)[0] is False

    def test_validate_status(self):
        """Test status validation."""
        from api.validators import validate_status

        # Valid statuses
        assert validate_status('pending')[0] is True
        assert validate_status('in_progress')[0] is True
        assert validate_status('completed')[0] is True
        assert validate_status('failed')[0] is True

        # Invalid statuses
        assert validate_status('invalid')[0] is False
        assert validate_status('')[0] is False
        assert validate_status(None)[0] is False

    def test_validate_pagination(self):
        """Test pagination validation."""
        from api.validators import validate_pagination

        # Valid pagination
        is_valid, _, page, per_page = validate_pagination(1, 20)
        assert is_valid is True
        assert page == 1
        assert per_page == 20

        # Default values
        is_valid, _, page, per_page = validate_pagination(None, None)
        assert is_valid is True
        assert page == 1
        assert per_page == 20

        # Invalid values
        assert validate_pagination(-1, 20)[0] is False
        assert validate_pagination(1, 0)[0] is False
        assert validate_pagination(1, 200)[0] is False
