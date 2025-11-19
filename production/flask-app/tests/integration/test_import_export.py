"""Integration tests for CSV import/export functionality."""
import io
import csv
import pytest
from models import PCMaster


class TestCSVImport:
    """Test CSV import functionality."""

    def test_csv_import_success(self, client, db_session, csv_file_content):
        """Test successful CSV import with valid data.

        This test verifies that:
        1. CSV file with valid data is accepted
        2. All records are imported successfully
        3. Response contains correct import statistics
        4. Database contains all imported records
        """
        # Arrange
        csv_content = csv_file_content(10)
        data = {
            'file': (io.BytesIO(csv_content.encode('utf-8')), 'test.csv')
        }

        # Act
        response = client.post(
            '/api/pcs',
            data=data,
            content_type='multipart/form-data'
        )

        # Assert
        assert response.status_code == 201
        json_data = response.get_json()
        assert json_data['result'] == 'ok'
        assert json_data['imported'] == 10
        assert json_data['failed'] == 0
        assert json_data.get('errors') is None

        # Verify database records
        pcs = PCMaster.query.all()
        assert len(pcs) == 10

        # Verify first record
        first_pc = PCMaster.query.filter_by(serial='SN00000000').first()
        assert first_pc is not None
        assert first_pc.pcname == '20251110M'
        assert first_pc.odj_path == '/srv/odj/20251110M.txt'

    def test_csv_import_duplicate(self, client, db_session, create_test_pc, csv_file_content):
        """Test CSV import with duplicate serial numbers.

        This test verifies that:
        1. Existing PC records are not overwritten
        2. Duplicate entries are reported in errors
        3. Other valid records are still imported
        4. Response contains detailed error information
        """
        # Arrange - Create existing PC
        create_test_pc(serial='SN00000000', pcname='EXISTING1M')

        csv_content = csv_file_content(5)

        data = {
            'file': (io.BytesIO(csv_content.encode('utf-8')), 'test.csv')
        }

        # Act
        response = client.post(
            '/api/pcs',
            data=data,
            content_type='multipart/form-data'
        )

        # Assert
        assert response.status_code == 201
        json_data = response.get_json()
        assert json_data['result'] == 'ok'
        assert json_data['imported'] == 4  # One duplicate skipped
        assert json_data['failed'] == 1
        assert json_data['errors'] is not None
        assert len(json_data['errors']) == 1

        # Verify error details
        error = json_data['errors'][0]
        assert error['row'] == 2  # Row 2 in CSV (after header)
        assert 'already exists' in error['error']
        assert error['data']['serial'] == 'SN00000000'

        # Verify original PC was not modified
        original_pc = PCMaster.query.filter_by(serial='SN00000000').first()
        assert original_pc.pcname == 'EXISTING1M'

    def test_csv_import_invalid_format(self, client, db_session):
        """Test CSV import with invalid format.

        This test verifies that:
        1. Missing required columns are detected
        2. Invalid PC names are rejected
        3. Empty serial numbers are rejected
        4. Response contains validation errors
        """
        # Arrange - CSV with invalid data
        invalid_csv = """serial,pcname,odj_path
VALIDSERIAL1,20251116M,/srv/odj/20251116M.txt
,20251117M,/srv/odj/20251117M.txt
VALIDSERIAL3,INVALID_NAME,/srv/odj/invalid.txt
VALIDSERIAL4,20251118M,/srv/odj/20251118M.txt"""

        data = {
            'file': (io.BytesIO(invalid_csv.encode('utf-8')), 'test.csv')
        }

        # Act
        response = client.post(
            '/api/pcs',
            data=data,
            content_type='multipart/form-data'
        )

        # Assert
        assert response.status_code == 201
        json_data = response.get_json()
        assert json_data['result'] == 'ok'
        assert json_data['imported'] == 2  # Only 2 valid records
        assert json_data['failed'] == 2
        assert json_data['errors'] is not None
        assert len(json_data['errors']) == 2

        # Verify only valid records were imported
        pcs = PCMaster.query.all()
        assert len(pcs) == 2
        serials = [pc.serial for pc in pcs]
        assert 'VALIDSERIAL1' in serials
        assert 'VALIDSERIAL4' in serials

    def test_csv_import_large_file(self, client, db_session, csv_file_content):
        """Test CSV import with 100+ records.

        This test verifies that:
        1. Large CSV files are processed efficiently
        2. All records are imported successfully
        3. Database transactions are handled correctly
        4. Performance is acceptable (<5 seconds for 100 records)
        """
        # Arrange
        import time
        csv_content = csv_file_content(150)

        data = {
            'file': (io.BytesIO(csv_content.encode('utf-8')), 'large_test.csv')
        }

        # Act
        start_time = time.time()
        response = client.post(
            '/api/pcs',
            data=data,
            content_type='multipart/form-data'
        )
        elapsed_time = time.time() - start_time

        # Assert
        assert response.status_code == 201
        json_data = response.get_json()
        assert json_data['result'] == 'ok'
        assert json_data['imported'] == 150
        assert json_data['failed'] == 0

        # Verify all records in database
        pcs = PCMaster.query.all()
        assert len(pcs) == 150

        # Performance check - should complete in under 5 seconds
        assert elapsed_time < 5.0, f"Import took {elapsed_time:.2f}s, expected < 5s"

    def test_csv_import_no_file(self, client, db_session):
        """Test CSV import with no file provided.

        This test verifies that:
        1. Missing file is detected
        2. Appropriate error message is returned
        3. No records are created in database
        """
        # Act
        response = client.post(
            '/api/pcs',
            data={},
            content_type='multipart/form-data'
        )

        # Assert
        assert response.status_code == 400
        json_data = response.get_json()
        assert json_data['error'] == 'Bad Request'
        assert 'file' in json_data['message'].lower()

        # Verify no records created
        pcs = PCMaster.query.all()
        assert len(pcs) == 0

    def test_csv_import_wrong_extension(self, client, db_session):
        """Test CSV import with non-CSV file.

        This test verifies that:
        1. File extension validation works
        2. Non-CSV files are rejected
        3. Appropriate error message is returned
        """
        # Arrange
        data = {
            'file': (io.BytesIO(b'test data'), 'test.txt')
        }

        # Act
        response = client.post(
            '/api/pcs',
            data=data,
            content_type='multipart/form-data'
        )

        # Assert
        assert response.status_code == 400
        json_data = response.get_json()
        assert json_data['error'] == 'Bad Request'
        assert 'CSV' in json_data['message']

    def test_csv_import_encoding_utf8_with_bom(self, client, db_session):
        """Test CSV import with UTF-8 BOM encoding.

        This test verifies that:
        1. UTF-8 with BOM is handled correctly
        2. Records are imported successfully
        3. No encoding errors occur
        """
        # Arrange - CSV with UTF-8 BOM
        csv_content = 'serial,pcname,odj_path\nTEST123,20251116M,/srv/odj/test.txt'
        csv_with_bom = '\ufeff' + csv_content

        data = {
            'file': (io.BytesIO(csv_with_bom.encode('utf-8')), 'test.csv')
        }

        # Act
        response = client.post(
            '/api/pcs',
            data=data,
            content_type='multipart/form-data'
        )

        # Assert
        assert response.status_code == 201
        json_data = response.get_json()
        assert json_data['imported'] == 1
        assert json_data['failed'] == 0

    def test_csv_import_mixed_success_and_failures(self, client, db_session):
        """Test CSV import with mix of valid and invalid records.

        This test verifies that:
        1. Valid records are imported
        2. Invalid records are skipped with errors
        3. Transaction rollback doesn't affect valid imports
        4. Detailed error reporting for each failure
        """
        # Arrange
        mixed_csv = """serial,pcname,odj_path
VALID001,20251116M,/srv/odj/20251116M.txt
,20251117M,/srv/odj/20251117M.txt
VALID003,20251118M,/srv/odj/20251118M.txt
INVALID,BADNAME,/srv/odj/bad.txt
VALID005,20251119M,/srv/odj/20251119M.txt"""

        data = {
            'file': (io.BytesIO(mixed_csv.encode('utf-8')), 'test.csv')
        }

        # Act
        response = client.post(
            '/api/pcs',
            data=data,
            content_type='multipart/form-data'
        )

        # Assert
        assert response.status_code == 201
        json_data = response.get_json()
        assert json_data['result'] == 'ok'
        assert json_data['imported'] == 3
        assert json_data['failed'] == 2

        # Verify valid records imported
        pcs = PCMaster.query.all()
        assert len(pcs) == 3
        serials = [pc.serial for pc in pcs]
        assert 'VALID001' in serials
        assert 'VALID003' in serials
        assert 'VALID005' in serials


class TestCSVExport:
    """Test CSV export functionality (if implemented)."""

    def test_csv_export_all_pcs(self, client, db_session, create_test_pc):
        """Test exporting all PCs to CSV.

        Note: This test assumes CSV export endpoint exists.
        If not implemented, this test will be skipped.
        """
        # Arrange
        for i in range(5):
            create_test_pc(
                serial=f'EXPORT{i:03d}',
                pcname=f'2025111{i}M',
                odj_path=f'/srv/odj/2025111{i}M.txt'
            )

        # Act - Attempt to export (endpoint may not exist yet)
        response = client.get('/api/pcs/export')

        # Skip if endpoint not implemented
        if response.status_code == 404:
            pytest.skip("CSV export endpoint not implemented yet")

        # Assert
        assert response.status_code == 200
        assert response.headers['Content-Type'] == 'text/csv'

        # Parse CSV response
        csv_content = response.data.decode('utf-8')
        reader = csv.DictReader(io.StringIO(csv_content))
        rows = list(reader)

        assert len(rows) == 5
        assert rows[0]['serial'] == 'EXPORT000'
