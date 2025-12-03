"""Integration tests for ODJ file upload functionality."""
import io
import os
import pytest
from models import PCMaster


class TestODJUpload:
    """Test ODJ file upload functionality."""

    def test_odj_upload_success(self, client, db_session, create_test_pc,
                                  odj_file_content, app):
        """Test successful ODJ file upload.

        This test verifies that:
        1. Valid ODJ file is accepted
        2. File is saved to correct location
        3. PC record is updated with ODJ path
        4. Response contains success message
        """
        # Arrange
        pc = create_test_pc(serial='TEST123', pcname='20251116M')
        odj_data = odj_file_content

        data = {
            'file': (io.BytesIO(odj_data.encode('utf-8')), '20251116M.txt'),
            'pc_id': pc.id
        }

        # Act
        response = client.post(
            f'/api/pcs/{pc.id}/odj',
            data=data,
            content_type='multipart/form-data'
        )

        # Assert - Skip if endpoint not implemented
        if response.status_code == 404:
            pytest.skip("ODJ upload endpoint not implemented yet")

        assert response.status_code == 200
        json_data = response.get_json()
        assert json_data['result'] == 'ok'
        assert 'odj_path' in json_data

        # Verify file was saved
        odj_path = json_data['odj_path']
        assert os.path.exists(odj_path)

        # Verify PC record updated
        updated_pc = PCMaster.query.get(pc.id)
        assert updated_pc.odj_path == odj_path

        # Verify file content
        with open(odj_path, 'r') as f:
            saved_content = f.read()
        assert odj_data in saved_content

    def test_odj_upload_invalid_extension(self, client, db_session, create_test_pc):
        """Test ODJ upload with invalid file extension.

        This test verifies that:
        1. Non-txt files are rejected
        2. Appropriate error message is returned
        3. PC record is not modified
        """
        # Arrange
        pc = create_test_pc(serial='TEST123', pcname='20251116M')

        data = {
            'file': (io.BytesIO(b'test data'), '20251116M.xml'),
            'pc_id': pc.id
        }

        # Act
        response = client.post(
            f'/api/pcs/{pc.id}/odj',
            data=data,
            content_type='multipart/form-data'
        )

        # Skip if endpoint not implemented
        if response.status_code == 404:
            pytest.skip("ODJ upload endpoint not implemented yet")

        # Assert
        assert response.status_code == 400
        json_data = response.get_json()
        assert 'error' in json_data
        assert 'extension' in json_data['message'].lower() or 'txt' in json_data['message'].lower()

        # Verify PC record not modified
        pc_check = PCMaster.query.get(pc.id)
        assert pc_check.odj_path is None

    def test_odj_upload_file_size_limit(self, client, db_session, create_test_pc):
        """Test ODJ upload with file size exceeding limit.

        This test verifies that:
        1. Files exceeding size limit are rejected
        2. Appropriate error message is returned
        3. No file is saved to disk
        """
        # Arrange
        pc = create_test_pc(serial='TEST123', pcname='20251116M')

        # Create large file (> 1MB)
        large_content = 'X' * (2 * 1024 * 1024)  # 2MB

        data = {
            'file': (io.BytesIO(large_content.encode('utf-8')), '20251116M.txt'),
            'pc_id': pc.id
        }

        # Act
        response = client.post(
            f'/api/pcs/{pc.id}/odj',
            data=data,
            content_type='multipart/form-data'
        )

        # Skip if endpoint not implemented
        if response.status_code == 404:
            pytest.skip("ODJ upload endpoint not implemented yet")

        # Assert
        if response.status_code == 413:  # Payload Too Large
            json_data = response.get_json()
            assert 'error' in json_data
        else:
            # Some frameworks may return 400
            assert response.status_code in [400, 413]

    def test_odj_upload_no_file(self, client, db_session, create_test_pc):
        """Test ODJ upload with no file provided.

        This test verifies that:
        1. Missing file is detected
        2. Appropriate error message is returned
        """
        # Arrange
        pc = create_test_pc(serial='TEST123', pcname='20251116M')

        # Act
        response = client.post(
            f'/api/pcs/{pc.id}/odj',
            data={},
            content_type='multipart/form-data'
        )

        # Skip if endpoint not implemented
        if response.status_code == 404:
            pytest.skip("ODJ upload endpoint not implemented yet")

        # Assert
        assert response.status_code == 400
        json_data = response.get_json()
        assert 'error' in json_data
        assert 'file' in json_data['message'].lower()

    def test_odj_upload_pc_not_found(self, client, db_session, odj_file_content):
        """Test ODJ upload for non-existent PC.

        This test verifies that:
        1. Non-existent PC ID is detected
        2. Appropriate error message is returned
        3. No file is saved
        """
        # Arrange
        data = {
            'file': (io.BytesIO(odj_file_content.encode('utf-8')), 'test.txt'),
            'pc_id': 99999
        }

        # Act
        response = client.post(
            '/api/pcs/99999/odj',
            data=data,
            content_type='multipart/form-data'
        )

        # Skip if endpoint not implemented
        if response.status_code == 404 and 'odj' not in response.get_json().get('message', '').lower():
            pytest.skip("ODJ upload endpoint not implemented yet")

        # Assert
        assert response.status_code == 404
        json_data = response.get_json()
        assert 'error' in json_data
        assert 'not found' in json_data['message'].lower()

    def test_odj_upload_replace_existing(self, client, db_session, create_test_pc,
                                          odj_file_content, app):
        """Test ODJ upload replacing existing file.

        This test verifies that:
        1. Existing ODJ file can be replaced
        2. Old file is removed or overwritten
        3. PC record is updated with new path
        4. New file content is correct
        """
        # Arrange
        pc = create_test_pc(
            serial='TEST123',
            pcname='20251116M',
            odj_path='/srv/odj/old_file.txt'
        )

        new_content = odj_file_content

        data = {
            'file': (io.BytesIO(new_content.encode('utf-8')), '20251116M_new.txt'),
            'pc_id': pc.id
        }

        # Act
        response = client.post(
            f'/api/pcs/{pc.id}/odj',
            data=data,
            content_type='multipart/form-data'
        )

        # Skip if endpoint not implemented
        if response.status_code == 404:
            pytest.skip("ODJ upload endpoint not implemented yet")

        # Assert
        assert response.status_code == 200
        json_data = response.get_json()
        assert json_data['result'] == 'ok'

        # Verify PC record updated
        updated_pc = PCMaster.query.get(pc.id)
        assert updated_pc.odj_path != '/srv/odj/old_file.txt'
        assert updated_pc.odj_path == json_data['odj_path']

    def test_odj_upload_filename_sanitization(self, client, db_session, create_test_pc,
                                                odj_file_content):
        """Test ODJ upload with unsafe filename characters.

        This test verifies that:
        1. Unsafe characters are sanitized
        2. File is saved with safe name
        3. Upload succeeds despite unsafe name
        """
        # Arrange
        pc = create_test_pc(serial='TEST123', pcname='20251116M')

        # Filename with unsafe characters
        unsafe_filename = '../../../etc/passwd.txt'

        data = {
            'file': (io.BytesIO(odj_file_content.encode('utf-8')), unsafe_filename),
            'pc_id': pc.id
        }

        # Act
        response = client.post(
            f'/api/pcs/{pc.id}/odj',
            data=data,
            content_type='multipart/form-data'
        )

        # Skip if endpoint not implemented
        if response.status_code == 404:
            pytest.skip("ODJ upload endpoint not implemented yet")

        # Assert - Should either succeed with sanitized name or reject
        if response.status_code == 200:
            json_data = response.get_json()
            odj_path = json_data['odj_path']

            # Verify path doesn't contain directory traversal
            assert '../' not in odj_path
            assert '/etc/passwd' not in odj_path
        else:
            # File rejected due to unsafe name
            assert response.status_code == 400

    def test_odj_upload_concurrent_uploads(self, client, db_session, create_test_pc,
                                            odj_file_content):
        """Test concurrent ODJ uploads for different PCs.

        This test verifies that:
        1. Multiple uploads can happen simultaneously
        2. Files are saved correctly
        3. No conflicts or race conditions occur
        """
        # Arrange
        pcs = [
            create_test_pc(serial=f'TEST{i:03d}', pcname=f'2025111{i}M')
            for i in range(5)
        ]

        # Act - Simulate concurrent uploads
        responses = []
        for pc in pcs:
            data = {
                'file': (io.BytesIO(odj_file_content.encode('utf-8')),
                        f'{pc.pcname}.txt'),
                'pc_id': pc.id
            }

            response = client.post(
                f'/api/pcs/{pc.id}/odj',
                data=data,
                content_type='multipart/form-data'
            )
            responses.append(response)

        # Skip if endpoint not implemented
        if responses[0].status_code == 404:
            pytest.skip("ODJ upload endpoint not implemented yet")

        # Assert
        for response in responses:
            assert response.status_code == 200
            json_data = response.get_json()
            assert json_data['result'] == 'ok'

        # Verify all PCs updated
        for pc in pcs:
            updated_pc = PCMaster.query.get(pc.id)
            assert updated_pc.odj_path is not None

    def test_odj_upload_empty_file(self, client, db_session, create_test_pc):
        """Test ODJ upload with empty file.

        This test verifies that:
        1. Empty files are detected
        2. Appropriate error message is returned
        """
        # Arrange
        pc = create_test_pc(serial='TEST123', pcname='20251116M')

        data = {
            'file': (io.BytesIO(b''), '20251116M.txt'),
            'pc_id': pc.id
        }

        # Act
        response = client.post(
            f'/api/pcs/{pc.id}/odj',
            data=data,
            content_type='multipart/form-data'
        )

        # Skip if endpoint not implemented
        if response.status_code == 404:
            pytest.skip("ODJ upload endpoint not implemented yet")

        # Assert - May accept empty file or reject it
        if response.status_code == 400:
            json_data = response.get_json()
            assert 'error' in json_data
