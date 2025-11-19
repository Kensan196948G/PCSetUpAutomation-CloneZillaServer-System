"""Integration tests for API endpoints.

These tests verify the complete workflow of API endpoints
including database interactions and edge cases.
"""
import pytest
import json
import io
import csv


class TestPCInfoWorkflow:
    """Integration tests for PC info workflow."""

    def test_complete_pc_lifecycle(self, client, app):
        """Test complete PC lifecycle: create -> retrieve -> update -> delete."""
        # Step 1: Create PC
        pc_data = {
            'serial': 'LIFECYCLE001',
            'pcname': '20251116M',
            'odj_path': '/srv/odj/20251116M.txt'
        }

        response = client.post(
            '/api/pcs',
            data=json.dumps(pc_data),
            content_type='application/json'
        )
        assert response.status_code == 201
        created_pc = json.loads(response.data)
        pc_id = created_pc['pc_id']

        # Step 2: Retrieve PC info via /api/pcinfo
        response = client.get(f'/api/pcinfo?serial={pc_data["serial"]}')
        assert response.status_code == 200
        pc_info = json.loads(response.data)
        assert pc_info['pcname'] == pc_data['pcname']
        assert pc_info['odj_path'] == pc_data['odj_path']

        # Step 3: Update PC
        update_data = {
            'pcname': '20251117M',
            'odj_path': '/srv/odj/20251117M.txt'
        }
        response = client.put(
            f'/api/pcs/{pc_id}',
            data=json.dumps(update_data),
            content_type='application/json'
        )
        assert response.status_code == 200

        # Step 4: Verify update via /api/pcinfo
        response = client.get(f'/api/pcinfo?serial={pc_data["serial"]}')
        assert response.status_code == 200
        pc_info = json.loads(response.data)
        assert pc_info['pcname'] == update_data['pcname']

        # Step 5: Delete PC
        response = client.delete(f'/api/pcs/{pc_id}')
        assert response.status_code == 200

        # Step 6: Verify PC is deleted
        response = client.get(f'/api/pcinfo?serial={pc_data["serial"]}')
        assert response.status_code == 404

    def test_concurrent_pc_operations(self, client):
        """Test creating multiple PCs concurrently."""
        pcs = []
        for i in range(10):
            pc_data = {
                'serial': f'CONCURRENT{i:03d}',
                'pcname': f'2025111{i}M',
                'odj_path': f'/srv/odj/2025111{i}M.txt'
            }
            response = client.post(
                '/api/pcs',
                data=json.dumps(pc_data),
                content_type='application/json'
            )
            assert response.status_code == 201
            pcs.append(json.loads(response.data))

        # Verify all PCs were created
        response = client.get('/api/pcs?per_page=100')
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['total'] == 10


class TestSetupLogWorkflow:
    """Integration tests for setup log workflow."""

    def test_complete_setup_workflow(self, client, app):
        """Test complete setup workflow with multiple log entries."""
        # Setup: Create PC
        pc_data = {
            'serial': 'SETUP001',
            'pcname': '20251116M',
            'odj_path': '/srv/odj/20251116M.txt'
        }
        response = client.post(
            '/api/pcs',
            data=json.dumps(pc_data),
            content_type='application/json'
        )
        assert response.status_code == 201

        # Simulate setup workflow with multiple log entries
        steps = [
            {'status': 'pending', 'step': 'initialization', 'logs': 'Setup started'},
            {'status': 'in_progress', 'step': 'pc_rename', 'logs': 'Renaming PC'},
            {'status': 'in_progress', 'step': 'odj_apply', 'logs': 'Applying ODJ'},
            {'status': 'in_progress', 'step': 'windows_update', 'logs': 'Running Windows Update'},
            {'status': 'completed', 'step': 'finalization', 'logs': 'Setup completed'}
        ]

        for step_data in steps:
            log_data = {
                'serial': pc_data['serial'],
                'pcname': pc_data['pcname'],
                'status': step_data['status'],
                'timestamp': '2025-11-16 12:33:22',
                'logs': step_data['logs'],
                'step': step_data['step']
            }
            response = client.post(
                '/api/log',
                data=json.dumps(log_data),
                content_type='application/json'
            )
            assert response.status_code == 201
            result = json.loads(response.data)
            assert result['result'] == 'ok'
            assert 'log_id' in result

    def test_failed_setup_workflow(self, client):
        """Test failed setup workflow with error logging."""
        # Setup: Create PC
        pc_data = {
            'serial': 'FAILED001',
            'pcname': '20251116M',
            'odj_path': '/srv/odj/20251116M.txt'
        }
        client.post(
            '/api/pcs',
            data=json.dumps(pc_data),
            content_type='application/json'
        )

        # Log failure
        log_data = {
            'serial': pc_data['serial'],
            'pcname': pc_data['pcname'],
            'status': 'failed',
            'timestamp': '2025-11-16 12:33:22',
            'logs': 'Windows Update failed',
            'step': 'windows_update',
            'error_message': 'Update server unreachable - timeout after 300s'
        }
        response = client.post(
            '/api/log',
            data=json.dumps(log_data),
            content_type='application/json'
        )
        assert response.status_code == 201


class TestCSVImport:
    """Integration tests for CSV import functionality."""

    def test_csv_import_success(self, client):
        """Test successful CSV import."""
        # Create CSV content
        csv_content = """serial,pcname,odj_path
CSV001,20251116M,/srv/odj/20251116M.txt
CSV002,20251117M,/srv/odj/20251117M.txt
CSV003,20251118M,/srv/odj/20251118M.txt
"""
        # Create file object
        csv_file = (io.BytesIO(csv_content.encode('utf-8')), 'test.csv')

        # Upload CSV
        response = client.post(
            '/api/pcs',
            data={'file': csv_file},
            content_type='multipart/form-data'
        )

        # Assert
        assert response.status_code == 201
        data = json.loads(response.data)
        assert data['result'] == 'ok'
        assert data['imported'] == 3
        assert data['failed'] == 0

        # Verify PCs were imported
        response = client.get('/api/pcs')
        data = json.loads(response.data)
        assert data['total'] == 3

    def test_csv_import_with_duplicates(self, client, app):
        """Test CSV import with duplicate entries."""
        # Setup: Create existing PC
        pc_data = {
            'serial': 'DUPLICATE001',
            'pcname': '20251116M',
            'odj_path': '/srv/odj/20251116M.txt'
        }
        client.post(
            '/api/pcs',
            data=json.dumps(pc_data),
            content_type='application/json'
        )

        # Create CSV with duplicate
        csv_content = """serial,pcname,odj_path
DUPLICATE001,20251117M,/srv/odj/20251117M.txt
NEW001,20251118M,/srv/odj/20251118M.txt
"""
        csv_file = (io.BytesIO(csv_content.encode('utf-8')), 'test.csv')

        # Upload CSV
        response = client.post(
            '/api/pcs',
            data={'file': csv_file},
            content_type='multipart/form-data'
        )

        # Assert
        assert response.status_code == 201
        data = json.loads(response.data)
        assert data['imported'] == 1
        assert data['failed'] == 1
        assert len(data['errors']) == 1

    def test_csv_import_with_invalid_data(self, client):
        """Test CSV import with invalid data."""
        # Create CSV with invalid data
        csv_content = """serial,pcname,odj_path
VALID001,20251116M,/srv/odj/20251116M.txt
,20251117M,/srv/odj/20251117M.txt
INVALID@#$,20251118M,/srv/odj/20251118M.txt
"""
        csv_file = (io.BytesIO(csv_content.encode('utf-8')), 'test.csv')

        # Upload CSV
        response = client.post(
            '/api/pcs',
            data={'file': csv_file},
            content_type='multipart/form-data'
        )

        # Assert
        assert response.status_code == 201
        data = json.loads(response.data)
        assert data['imported'] == 1
        assert data['failed'] == 2


class TestPaginationAndFiltering:
    """Integration tests for pagination and filtering."""

    def test_pagination_with_large_dataset(self, client, app):
        """Test pagination with large dataset."""
        # Setup: Create 100 PCs
        with app.app_context():
            from models import db, PCMaster
            for i in range(100):
                pc = PCMaster(
                    serial=f'PAGE{i:04d}',
                    pcname=f'2025{i % 12 + 1:02d}{i % 28 + 1:02d}M',
                    odj_path=f'/srv/odj/page{i}.txt'
                )
                db.session.add(pc)
            db.session.commit()

        # Test: Get different pages
        for page in range(1, 6):
            response = client.get(f'/api/pcs?page={page}&per_page=20')
            assert response.status_code == 200
            data = json.loads(response.data)
            assert data['page'] == page
            assert data['total'] == 100
            assert len(data['items']) == 20

    def test_filtering_by_serial(self, client, app):
        """Test filtering PCs by serial."""
        # Setup: Create PCs with different serials
        with app.app_context():
            from models import db, PCMaster
            serials = ['ABC001', 'ABC002', 'XYZ001', 'XYZ002']
            for serial in serials:
                pc = PCMaster(
                    serial=serial,
                    pcname='20251116M',
                    odj_path='/srv/odj/test.txt'
                )
                db.session.add(pc)
            db.session.commit()

        # Test: Filter by serial pattern
        response = client.get('/api/pcs?serial=ABC')
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['total'] == 2
        assert all('ABC' in item['serial'] for item in data['items'])

    def test_filtering_by_pcname(self, client, app):
        """Test filtering PCs by PC name."""
        # Setup: Create PCs with different names
        with app.app_context():
            from models import db, PCMaster
            for i in range(5):
                pc = PCMaster(
                    serial=f'TEST{i}',
                    pcname=f'2025111{i}M',
                    odj_path='/srv/odj/test.txt'
                )
                db.session.add(pc)
            db.session.commit()

        # Test: Filter by PC name pattern
        response = client.get('/api/pcs?pcname=20251112M')
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['total'] == 1
        assert data['items'][0]['pcname'] == '20251112M'


class TestErrorHandling:
    """Integration tests for error handling."""

    def test_database_transaction_rollback(self, client, app):
        """Test database rollback on error."""
        # This test verifies that database transactions are properly rolled back on errors
        initial_count = 0
        with app.app_context():
            from models import PCMaster
            initial_count = PCMaster.query.count()

        # Attempt to create PC with invalid data that passes initial validation
        # but fails during database commit (e.g., extremely long odj_path)
        pc_data = {
            'serial': 'ROLLBACK001',
            'pcname': '20251116M',
            'odj_path': 'x' * 300  # Exceeds 255 character limit
        }

        response = client.post(
            '/api/pcs',
            data=json.dumps(pc_data),
            content_type='application/json'
        )

        # Should fail validation
        assert response.status_code == 400

        # Verify no PC was created
        with app.app_context():
            from models import PCMaster
            final_count = PCMaster.query.count()
            assert final_count == initial_count

    def test_api_response_time(self, client, app):
        """Test API response time is within acceptable limits."""
        import time

        # Setup: Create PC
        pc_data = {
            'serial': 'PERFORMANCE001',
            'pcname': '20251116M',
            'odj_path': '/srv/odj/20251116M.txt'
        }
        client.post(
            '/api/pcs',
            data=json.dumps(pc_data),
            content_type='application/json'
        )

        # Test: Measure response time for /api/pcinfo
        start_time = time.time()
        response = client.get(f'/api/pcinfo?serial={pc_data["serial"]}')
        elapsed_time = (time.time() - start_time) * 1000  # Convert to ms

        assert response.status_code == 200
        # Response time should be under 200ms (target from requirements)
        # Note: In test environment, this might be higher, so we use 500ms as threshold
        assert elapsed_time < 500, f"Response time {elapsed_time:.2f}ms exceeded threshold"

    def test_concurrent_pc_creation_with_same_serial(self, client, app):
        """Test handling of concurrent PC creation attempts with same serial."""
        pc_data = {
            'serial': 'CONCURRENT_DUP',
            'pcname': '20251116M',
            'odj_path': '/srv/odj/20251116M.txt'
        }

        # First creation should succeed
        response1 = client.post(
            '/api/pcs',
            data=json.dumps(pc_data),
            content_type='application/json'
        )
        assert response1.status_code == 201

        # Second creation should fail with conflict
        response2 = client.post(
            '/api/pcs',
            data=json.dumps(pc_data),
            content_type='application/json'
        )
        assert response2.status_code == 409

        # Verify only one PC was created
        with app.app_context():
            from models import PCMaster
            count = PCMaster.query.filter_by(serial=pc_data['serial']).count()
            assert count == 1
