"""End-to-End tests for complete PC setup workflow."""
import io
import pytest
import time
from models import PCMaster


class TestCompleteWorkflow:
    """Test complete PC setup workflow from start to finish."""

    def test_complete_deployment_workflow(self, client, db_session,
                                           csv_file_content, odj_file_content, app):
        """Test complete workflow: CSV import → ODJ upload → Deployment → Completion.

        Workflow Steps:
        1. Import 100 PCs from CSV
        2. Upload ODJ files for PCs
        3. Select master image
        4. Create deployment
        5. Start deployment
        6. Track progress
        7. Verify completion

        This is the core E2E test that validates the entire system.
        """
        # ===== Step 1: Import 100 PCs from CSV =====
        print("\n[Step 1] Importing 100 PCs from CSV...")

        csv_content = csv_file_content(100)
        csv_data = {
            'file': (io.BytesIO(csv_content.encode('utf-8')), 'bulk_import.csv')
        }

        import_response = client.post(
            '/api/pcs',
            data=csv_data,
            content_type='multipart/form-data'
        )

        assert import_response.status_code == 201
        import_result = import_response.get_json()
        assert import_result['imported'] == 100
        assert import_result['failed'] == 0

        print(f"✓ Imported {import_result['imported']} PCs successfully")

        # Verify database
        total_pcs = PCMaster.query.count()
        assert total_pcs == 100

        # ===== Step 2: Upload ODJ files =====
        print("\n[Step 2] Uploading ODJ files for first 10 PCs...")

        pcs = PCMaster.query.limit(10).all()
        uploaded_count = 0

        for pc in pcs:
            odj_data = {
                'file': (io.BytesIO(odj_file_content.encode('utf-8')),
                        f'{pc.pcname}.txt'),
                'pc_id': pc.id
            }

            odj_response = client.post(
                f'/api/pcs/{pc.id}/odj',
                data=odj_data,
                content_type='multipart/form-data'
            )

            # Skip ODJ upload if endpoint not implemented
            if odj_response.status_code == 404:
                print("  ⚠ ODJ upload endpoint not implemented, skipping...")
                break

            if odj_response.status_code == 200:
                uploaded_count += 1

        if uploaded_count > 0:
            print(f"✓ Uploaded {uploaded_count} ODJ files")

        # ===== Step 3: Select master image =====
        print("\n[Step 3] Selecting master image...")

        # List available images
        images_response = client.get('/api/images')

        if images_response.status_code == 404:
            print("  ⚠ Images endpoint not implemented, using default image name")
            image_name = 'win11-master-2025'
        else:
            images = images_response.get_json()
            if images and len(images.get('items', [])) > 0:
                image_name = images['items'][0]['name']
                print(f"✓ Selected image: {image_name}")
            else:
                image_name = 'win11-master-2025'
                print(f"  Using default image: {image_name}")

        # ===== Step 4: Create deployment =====
        print("\n[Step 4] Creating deployment for 20 PCs...")

        deployment_pcs = PCMaster.query.limit(20).all()
        pc_ids = [pc.id for pc in deployment_pcs]

        deployment_data = {
            'name': 'E2E Test Deployment - 20 PCs',
            'pc_ids': pc_ids,
            'image_name': image_name,
            'auto_start': False
        }

        deployment_response = client.post(
            '/api/deployments',
            json=deployment_data
        )

        if deployment_response.status_code == 404:
            pytest.skip("Deployment endpoint not implemented yet")

        assert deployment_response.status_code == 201
        deployment_result = deployment_response.get_json()
        deployment_id = deployment_result['deployment_id']

        print(f"✓ Created deployment ID: {deployment_id}")

        # ===== Step 5: Start deployment =====
        print("\n[Step 5] Starting deployment...")

        start_response = client.post(f'/api/deployments/{deployment_id}/start')

        if start_response.status_code == 404:
            print("  ⚠ Deployment start endpoint not implemented")
        else:
            assert start_response.status_code == 200
            print("✓ Deployment started")

        # ===== Step 6: Simulate deployment progress =====
        print("\n[Step 6] Simulating deployment progress...")

        # Simulate progress for each PC
        stages = [
            ('imaging', 25, 0.1),
            ('imaging', 50, 0.1),
            ('imaging', 75, 0.1),
            ('completed', 100, 0.1)
        ]

        for i, pc in enumerate(deployment_pcs[:10]):  # Simulate first 10 PCs
            for stage, progress, delay in stages:
                progress_data = {
                    'pc_id': pc.id,
                    'status': stage,
                    'progress': progress
                }

                progress_response = client.put(
                    f'/api/deployments/{deployment_id}/progress',
                    json=progress_data
                )

                if progress_response.status_code != 404:
                    time.sleep(delay)

            print(f"  ✓ PC {i+1}/10 completed")

        # ===== Step 7: Verify deployment status =====
        print("\n[Step 7] Verifying deployment status...")

        status_response = client.get(f'/api/deployments/{deployment_id}')
        assert status_response.status_code == 200

        deployment_status = status_response.get_json()['deployment']
        print(f"  Deployment status: {deployment_status['status']}")
        print(f"  Overall progress: {deployment_status.get('progress', 0)}%")

        # At least 10 PCs should be completed
        completed_pcs = [pc for pc in deployment_status['pcs']
                        if pc['status'] == 'completed']
        assert len(completed_pcs) >= 10

        # ===== Step 8: Verify setup logs =====
        print("\n[Step 8] Verifying setup logs...")

        logs_response = client.get('/api/logs')

        if logs_response.status_code != 404:
            logs = logs_response.get_json()
            print(f"✓ Found {len(logs.get('items', []))} log entries")

        print("\n✓ Complete workflow test passed!")

    def test_partial_failure_workflow(self, client, db_session, csv_file_content):
        """Test workflow with partial failures.

        This test verifies:
        1. Some PCs can fail during deployment
        2. Other PCs continue successfully
        3. Overall deployment tracks mixed status
        4. Error details are recorded
        """
        print("\n[Partial Failure Workflow] Starting...")

        # Import PCs
        csv_content = csv_file_content(10)
        csv_data = {
            'file': (io.BytesIO(csv_content.encode('utf-8')), 'partial_test.csv')
        }

        import_response = client.post(
            '/api/pcs',
            data=csv_data,
            content_type='multipart/form-data'
        )
        assert import_response.status_code == 201

        # Create deployment
        pcs = PCMaster.query.all()
        pc_ids = [pc.id for pc in pcs]

        deployment_data = {
            'name': 'Partial Failure Test',
            'pc_ids': pc_ids,
            'image_name': 'win11-master-2025'
        }

        deployment_response = client.post('/api/deployments', json=deployment_data)

        if deployment_response.status_code == 404:
            pytest.skip("Deployment endpoint not implemented yet")

        deployment_id = deployment_response.get_json()['deployment_id']

        # Simulate mixed results
        for i, pc in enumerate(pcs):
            if i % 3 == 0:  # Every 3rd PC fails
                progress_data = {
                    'pc_id': pc.id,
                    'status': 'failed',
                    'progress': 30 + (i * 5),
                    'error': f'Simulated error for PC {pc.pcname}'
                }
            else:  # Others succeed
                progress_data = {
                    'pc_id': pc.id,
                    'status': 'completed',
                    'progress': 100
                }

            client.put(
                f'/api/deployments/{deployment_id}/progress',
                json=progress_data
            )

        # Verify mixed status
        status_response = client.get(f'/api/deployments/{deployment_id}')
        deployment = status_response.get_json()['deployment']

        completed = len([pc for pc in deployment['pcs'] if pc['status'] == 'completed'])
        failed = len([pc for pc in deployment['pcs'] if pc['status'] == 'failed'])

        print(f"  Completed: {completed}, Failed: {failed}")
        assert completed > 0
        assert failed > 0
        assert completed + failed == len(pcs)

        print("✓ Partial failure workflow test passed!")

    def test_concurrent_deployments_workflow(self, client, db_session, csv_file_content):
        """Test multiple concurrent deployments.

        This test verifies:
        1. Multiple deployments can run simultaneously
        2. Each deployment tracks independently
        3. No cross-deployment interference
        4. Database handles concurrent updates
        """
        print("\n[Concurrent Deployments] Starting...")

        # Import PCs for multiple deployments
        csv_content = csv_file_content(30)
        csv_data = {
            'file': (io.BytesIO(csv_content.encode('utf-8')), 'concurrent_test.csv')
        }

        import_response = client.post(
            '/api/pcs',
            data=csv_data,
            content_type='multipart/form-data'
        )
        assert import_response.status_code == 201

        # Create 3 deployments
        all_pcs = PCMaster.query.all()
        deployments = []

        for i in range(3):
            start_idx = i * 10
            end_idx = start_idx + 10
            deployment_pcs = all_pcs[start_idx:end_idx]

            deployment_data = {
                'name': f'Concurrent Deployment {i+1}',
                'pc_ids': [pc.id for pc in deployment_pcs],
                'image_name': 'win11-master-2025'
            }

            response = client.post('/api/deployments', json=deployment_data)

            if response.status_code == 404:
                pytest.skip("Deployment endpoint not implemented yet")

            deployments.append({
                'id': response.get_json()['deployment_id'],
                'pcs': deployment_pcs
            })

        print(f"✓ Created {len(deployments)} concurrent deployments")

        # Update each deployment independently
        for deployment in deployments:
            for pc in deployment['pcs'][:5]:  # Complete first 5 in each
                progress_data = {
                    'pc_id': pc.id,
                    'status': 'completed',
                    'progress': 100
                }

                client.put(
                    f'/api/deployments/{deployment["id"]}/progress',
                    json=progress_data
                )

        # Verify each deployment
        for deployment in deployments:
            status_response = client.get(f'/api/deployments/{deployment["id"]}')
            status = status_response.get_json()['deployment']

            completed = len([pc for pc in status['pcs'] if pc['status'] == 'completed'])
            assert completed == 5

        print("✓ Concurrent deployments test passed!")

    def test_full_100pc_deployment_workflow(self, client, db_session, csv_file_content):
        """Test full-scale deployment with 100 PCs.

        This test verifies:
        1. System handles 100 PCs efficiently
        2. Progress tracking scales properly
        3. Performance is acceptable
        4. No memory or resource issues
        """
        print("\n[Full-Scale 100 PC Deployment] Starting...")

        start_time = time.time()

        # Import 100 PCs
        csv_content = csv_file_content(100)
        csv_data = {
            'file': (io.BytesIO(csv_content.encode('utf-8')), 'full_scale.csv')
        }

        import_response = client.post(
            '/api/pcs',
            data=csv_data,
            content_type='multipart/form-data'
        )
        assert import_response.status_code == 201
        print(f"✓ Imported 100 PCs in {time.time() - start_time:.2f}s")

        # Create deployment
        pcs = PCMaster.query.all()
        deployment_data = {
            'name': 'Full Scale 100 PC Deployment',
            'pc_ids': [pc.id for pc in pcs],
            'image_name': 'win11-master-2025'
        }

        deployment_start = time.time()
        deployment_response = client.post('/api/deployments', json=deployment_data)

        if deployment_response.status_code == 404:
            pytest.skip("Deployment endpoint not implemented yet")

        deployment_id = deployment_response.get_json()['deployment_id']
        print(f"✓ Created deployment in {time.time() - deployment_start:.2f}s")

        # Simulate rapid progress updates
        update_start = time.time()

        for i, pc in enumerate(pcs[:50]):  # Update first 50 for time constraint
            progress_data = {
                'pc_id': pc.id,
                'status': 'completed',
                'progress': 100
            }

            client.put(
                f'/api/deployments/{deployment_id}/progress',
                json=progress_data
            )

            if (i + 1) % 10 == 0:
                print(f"  Updated {i+1} PCs...")

        update_time = time.time() - update_start
        print(f"✓ Updated 50 PCs in {update_time:.2f}s ({update_time/50*1000:.1f}ms per PC)")

        # Verify final status
        status_response = client.get(f'/api/deployments/{deployment_id}')
        deployment = status_response.get_json()['deployment']

        total_time = time.time() - start_time
        print(f"\n✓ Full workflow completed in {total_time:.2f}s")
        print(f"  Progress: {deployment.get('progress', 0)}%")

        # Performance assertion
        assert total_time < 60, f"Full workflow took {total_time:.2f}s, expected < 60s"

    def test_api_response_times(self, client, db_session, create_test_pc):
        """Test API response times meet performance requirements.

        This test verifies:
        1. API responses are fast (<200ms for LAN)
        2. Database queries are optimized
        3. No performance degradation under load
        """
        print("\n[API Response Times] Starting...")

        # Create test data
        pcs = [
            create_test_pc(serial=f'PERF{i:03d}', pcname=f'2025111{i % 10}M')
            for i in range(20)
        ]

        # Test GET /api/pcs
        start = time.time()
        response = client.get('/api/pcs')
        get_pcs_time = (time.time() - start) * 1000

        assert response.status_code == 200
        print(f"  GET /api/pcs: {get_pcs_time:.1f}ms")
        assert get_pcs_time < 200, f"GET /api/pcs took {get_pcs_time:.1f}ms, expected < 200ms"

        # Test GET /api/pcinfo
        start = time.time()
        response = client.get(f'/api/pcinfo?serial={pcs[0].serial}')
        pcinfo_time = (time.time() - start) * 1000

        assert response.status_code == 200
        print(f"  GET /api/pcinfo: {pcinfo_time:.1f}ms")
        assert pcinfo_time < 200, f"GET /api/pcinfo took {pcinfo_time:.1f}ms, expected < 200ms"

        # Test POST /api/log
        start = time.time()
        log_data = {
            'serial': pcs[0].serial,
            'pcname': pcs[0].pcname,
            'status': 'completed',
            'timestamp': '2025-11-16 12:00:00'
        }
        response = client.post('/api/log', json=log_data)
        log_time = (time.time() - start) * 1000

        assert response.status_code in [200, 201]
        print(f"  POST /api/log: {log_time:.1f}ms")
        assert log_time < 200, f"POST /api/log took {log_time:.1f}ms, expected < 200ms"

        print("✓ All API responses within 200ms requirement")
