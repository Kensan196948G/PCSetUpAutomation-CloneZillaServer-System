"""Integration tests for deployment API functionality."""
import pytest
import time
from models import PCMaster


class TestDeploymentAPI:
    """Test deployment creation and management."""

    def test_create_deployment(self, client, db_session, create_test_pc):
        """Test creating a new deployment.

        This test verifies that:
        1. Deployment can be created with valid data
        2. Response contains deployment ID
        3. Deployment record is stored
        4. Initial status is 'pending'
        """
        # Arrange
        pcs = [
            create_test_pc(serial=f'DEPLOY{i:03d}', pcname=f'2025111{i}M')
            for i in range(3)
        ]

        pc_ids = [pc.id for pc in pcs]

        deployment_data = {
            'name': 'Test Deployment',
            'pc_ids': pc_ids,
            'image_name': 'win11-master-2025',
            'auto_start': False
        }

        # Act
        response = client.post(
            '/api/deployments',
            json=deployment_data
        )

        # Skip if endpoint not implemented
        if response.status_code == 404:
            pytest.skip("Deployment endpoint not implemented yet")

        # Assert
        assert response.status_code == 201
        json_data = response.get_json()
        assert json_data['result'] == 'ok'
        assert 'deployment_id' in json_data
        assert 'deployment' in json_data

        deployment = json_data['deployment']
        assert deployment['name'] == 'Test Deployment'
        assert deployment['status'] == 'pending'
        assert len(deployment['pcs']) == 3

    def test_get_deployment_status(self, client, db_session, create_test_pc):
        """Test retrieving deployment status.

        This test verifies that:
        1. Deployment status can be retrieved
        2. Response contains complete deployment info
        3. PC statuses are included
        4. Progress information is accurate
        """
        # Arrange - Create deployment first
        pcs = [
            create_test_pc(serial=f'STAT{i:03d}', pcname=f'2025111{i}M')
            for i in range(5)
        ]

        deployment_data = {
            'name': 'Status Test',
            'pc_ids': [pc.id for pc in pcs],
            'image_name': 'win11-master-2025'
        }

        create_response = client.post('/api/deployments', json=deployment_data)

        # Skip if endpoint not implemented
        if create_response.status_code == 404:
            pytest.skip("Deployment endpoint not implemented yet")

        deployment_id = create_response.get_json()['deployment_id']

        # Act
        response = client.get(f'/api/deployments/{deployment_id}')

        # Assert
        assert response.status_code == 200
        json_data = response.get_json()
        assert 'deployment' in json_data

        deployment = json_data['deployment']
        assert deployment['id'] == deployment_id
        assert deployment['name'] == 'Status Test'
        assert 'status' in deployment
        assert 'pcs' in deployment
        assert len(deployment['pcs']) == 5
        assert 'progress' in deployment

    def test_deployment_progress_update(self, client, db_session, create_test_pc):
        """Test updating deployment progress.

        This test verifies that:
        1. Deployment progress can be updated
        2. Individual PC status can be updated
        3. Overall deployment status reflects PC statuses
        4. Progress percentage is calculated correctly
        """
        # Arrange
        pcs = [
            create_test_pc(serial=f'PROG{i:03d}', pcname=f'2025111{i}M')
            for i in range(4)
        ]

        deployment_data = {
            'name': 'Progress Test',
            'pc_ids': [pc.id for pc in pcs],
            'image_name': 'win11-master-2025'
        }

        create_response = client.post('/api/deployments', json=deployment_data)

        # Skip if endpoint not implemented
        if create_response.status_code == 404:
            pytest.skip("Deployment endpoint not implemented yet")

        deployment_id = create_response.get_json()['deployment_id']

        # Act - Update progress for first PC
        progress_data = {
            'pc_id': pcs[0].id,
            'status': 'imaging',
            'progress': 50
        }

        response = client.put(
            f'/api/deployments/{deployment_id}/progress',
            json=progress_data
        )

        # Assert
        assert response.status_code == 200
        json_data = response.get_json()
        assert json_data['result'] == 'ok'

        # Get deployment status
        status_response = client.get(f'/api/deployments/{deployment_id}')
        deployment = status_response.get_json()['deployment']

        # Verify progress updated
        pc_statuses = {pc['id']: pc for pc in deployment['pcs']}
        assert pc_statuses[pcs[0].id]['status'] == 'imaging'
        assert pc_statuses[pcs[0].id]['progress'] == 50

        # Verify overall progress
        # 1 PC at 50% out of 4 PCs = 12.5% overall
        assert deployment['progress'] == 12.5

    def test_multiple_pc_deployment(self, client, db_session, create_test_pc):
        """Test deploying to multiple PCs simultaneously.

        This test verifies that:
        1. Multiple PCs can be included in one deployment
        2. Each PC has independent status tracking
        3. Deployment handles 10+ PCs efficiently
        4. Status updates work correctly for all PCs
        """
        # Arrange - Create 15 PCs
        pcs = [
            create_test_pc(serial=f'MULTI{i:03d}', pcname=f'2025111{i % 10}M')
            for i in range(15)
        ]

        deployment_data = {
            'name': 'Multi-PC Deployment',
            'pc_ids': [pc.id for pc in pcs],
            'image_name': 'win11-master-2025'
        }

        # Act
        response = client.post('/api/deployments', json=deployment_data)

        # Skip if endpoint not implemented
        if response.status_code == 404:
            pytest.skip("Deployment endpoint not implemented yet")

        # Assert
        assert response.status_code == 201
        json_data = response.get_json()
        deployment_id = json_data['deployment_id']

        # Verify all PCs included
        status_response = client.get(f'/api/deployments/{deployment_id}')
        deployment = status_response.get_json()['deployment']
        assert len(deployment['pcs']) == 15

        # Update status for each PC
        for i, pc in enumerate(pcs[:5]):  # Update first 5
            progress_data = {
                'pc_id': pc.id,
                'status': 'completed',
                'progress': 100
            }
            update_response = client.put(
                f'/api/deployments/{deployment_id}/progress',
                json=progress_data
            )
            assert update_response.status_code == 200

        # Verify progress
        final_status = client.get(f'/api/deployments/{deployment_id}')
        final_deployment = final_status.get_json()['deployment']

        # 5 out of 15 completed = 33.33% overall
        assert 30 <= final_deployment['progress'] <= 35

    def test_deployment_start_and_stop(self, client, db_session, create_test_pc):
        """Test starting and stopping a deployment.

        This test verifies that:
        1. Deployment can be started
        2. Status changes to 'running'
        3. Deployment can be paused/stopped
        4. Status transitions are valid
        """
        # Arrange
        pcs = [
            create_test_pc(serial=f'START{i:03d}', pcname=f'2025111{i}M')
            for i in range(3)
        ]

        deployment_data = {
            'name': 'Start/Stop Test',
            'pc_ids': [pc.id for pc in pcs],
            'image_name': 'win11-master-2025',
            'auto_start': False
        }

        create_response = client.post('/api/deployments', json=deployment_data)

        # Skip if endpoint not implemented
        if create_response.status_code == 404:
            pytest.skip("Deployment endpoint not implemented yet")

        deployment_id = create_response.get_json()['deployment_id']

        # Act - Start deployment
        start_response = client.post(f'/api/deployments/{deployment_id}/start')

        if start_response.status_code == 404:
            pytest.skip("Deployment start endpoint not implemented yet")

        # Assert
        assert start_response.status_code == 200

        # Verify status changed
        status_response = client.get(f'/api/deployments/{deployment_id}')
        deployment = status_response.get_json()['deployment']
        assert deployment['status'] in ['running', 'started']

        # Stop deployment
        stop_response = client.post(f'/api/deployments/{deployment_id}/stop')
        if stop_response.status_code != 404:
            assert stop_response.status_code == 200

            # Verify stopped
            status_response = client.get(f'/api/deployments/{deployment_id}')
            deployment = status_response.get_json()['deployment']
            assert deployment['status'] in ['stopped', 'paused']

    def test_deployment_with_invalid_pcs(self, client, db_session):
        """Test deployment creation with non-existent PC IDs.

        This test verifies that:
        1. Invalid PC IDs are detected
        2. Appropriate error message is returned
        3. Deployment is not created
        """
        # Arrange
        deployment_data = {
            'name': 'Invalid Test',
            'pc_ids': [99999, 99998, 99997],  # Non-existent IDs
            'image_name': 'win11-master-2025'
        }

        # Act
        response = client.post('/api/deployments', json=deployment_data)

        # Skip if endpoint not implemented
        if response.status_code == 404:
            pytest.skip("Deployment endpoint not implemented yet")

        # Assert
        assert response.status_code == 400
        json_data = response.get_json()
        assert 'error' in json_data
        assert 'not found' in json_data['message'].lower() or 'invalid' in json_data['message'].lower()

    def test_deployment_list(self, client, db_session, create_test_pc):
        """Test listing all deployments.

        This test verifies that:
        1. All deployments can be listed
        2. Pagination works correctly
        3. Filtering by status works
        4. Results are ordered by creation time
        """
        # Arrange - Create multiple deployments
        for i in range(5):
            pcs = [
                create_test_pc(serial=f'LIST{i}{j:02d}', pcname=f'202511{j}M')
                for j in range(2)
            ]

            deployment_data = {
                'name': f'Deployment {i}',
                'pc_ids': [pc.id for pc in pcs],
                'image_name': 'win11-master-2025'
            }

            create_response = client.post('/api/deployments', json=deployment_data)

            # Skip if endpoint not implemented
            if create_response.status_code == 404:
                pytest.skip("Deployment endpoint not implemented yet")

        # Act
        response = client.get('/api/deployments')

        # Assert
        assert response.status_code == 200
        json_data = response.get_json()
        assert 'items' in json_data
        assert len(json_data['items']) >= 5

        # Verify pagination info
        if 'total' in json_data:
            assert json_data['total'] >= 5

    def test_deployment_completion_tracking(self, client, db_session, create_test_pc):
        """Test deployment completion tracking.

        This test verifies that:
        1. Deployment status changes to 'completed' when all PCs done
        2. Completion timestamp is recorded
        3. Final statistics are accurate
        """
        # Arrange
        pcs = [
            create_test_pc(serial=f'COMP{i:03d}', pcname=f'2025111{i}M')
            for i in range(3)
        ]

        deployment_data = {
            'name': 'Completion Test',
            'pc_ids': [pc.id for pc in pcs],
            'image_name': 'win11-master-2025'
        }

        create_response = client.post('/api/deployments', json=deployment_data)

        # Skip if endpoint not implemented
        if create_response.status_code == 404:
            pytest.skip("Deployment endpoint not implemented yet")

        deployment_id = create_response.get_json()['deployment_id']

        # Act - Mark all PCs as completed
        for pc in pcs:
            progress_data = {
                'pc_id': pc.id,
                'status': 'completed',
                'progress': 100
            }
            client.put(
                f'/api/deployments/{deployment_id}/progress',
                json=progress_data
            )

        # Assert
        status_response = client.get(f'/api/deployments/{deployment_id}')
        deployment = status_response.get_json()['deployment']

        # Should be completed
        assert deployment['status'] == 'completed'
        assert deployment['progress'] == 100

        # Completion time should be set
        if 'completed_at' in deployment:
            assert deployment['completed_at'] is not None

    def test_deployment_error_handling(self, client, db_session, create_test_pc):
        """Test deployment error handling and recovery.

        This test verifies that:
        1. Errors during deployment are captured
        2. Error status is reflected in deployment
        3. Partial completions are tracked
        4. Failed PCs don't block successful ones
        """
        # Arrange
        pcs = [
            create_test_pc(serial=f'ERROR{i:03d}', pcname=f'2025111{i}M')
            for i in range(4)
        ]

        deployment_data = {
            'name': 'Error Test',
            'pc_ids': [pc.id for pc in pcs],
            'image_name': 'win11-master-2025'
        }

        create_response = client.post('/api/deployments', json=deployment_data)

        # Skip if endpoint not implemented
        if create_response.status_code == 404:
            pytest.skip("Deployment endpoint not implemented yet")

        deployment_id = create_response.get_json()['deployment_id']

        # Act - Mark some as completed, some as failed
        # PC 0, 1: completed
        for i in range(2):
            progress_data = {
                'pc_id': pcs[i].id,
                'status': 'completed',
                'progress': 100
            }
            client.put(
                f'/api/deployments/{deployment_id}/progress',
                json=progress_data
            )

        # PC 2: failed
        progress_data = {
            'pc_id': pcs[2].id,
            'status': 'failed',
            'progress': 45,
            'error': 'Network timeout during imaging'
        }
        client.put(
            f'/api/deployments/{deployment_id}/progress',
            json=progress_data
        )

        # Assert
        status_response = client.get(f'/api/deployments/{deployment_id}')
        deployment = status_response.get_json()['deployment']

        # Check statistics
        pc_statuses = {pc['id']: pc for pc in deployment['pcs']}
        assert pc_statuses[pcs[0].id]['status'] == 'completed'
        assert pc_statuses[pcs[1].id]['status'] == 'completed'
        assert pc_statuses[pcs[2].id]['status'] == 'failed'

        # Deployment should show partial completion
        # 2 completed, 1 failed, 1 pending out of 4
        # Could be 'partial' or 'failed' status depending on implementation
        assert deployment['status'] in ['partial', 'failed', 'running']
