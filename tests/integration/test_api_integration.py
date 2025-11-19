"""
Integration tests for the Flask API endpoints.
"""
import json
from models.pc_master import PCMaster
from models import db


def test_get_pc_info_success(client, app, sample_pc_data):
    """
    Test successful retrieval of PC info.
    Scenario: The serial number exists in the database.
    """
    # Arrange: Add sample data to the test database
    with app.app_context():
        new_pc = PCMaster(
            serial=sample_pc_data['serial'],
            pcname=sample_pc_data['pcname'],
            odj_path=sample_pc_data['odj_path']
        )
        db.session.add(new_pc)
        db.session.commit()

    # Act: Make a GET request to the pcinfo endpoint with a query parameter
    response = client.get(f"/api/pcinfo?serial={sample_pc_data['serial']}")

    # Assert: Check the response
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['pcname'] == sample_pc_data['pcname']
    assert data['odj_path'] == sample_pc_data['odj_path']


def test_get_pc_info_not_found(client):
    """
    Test PC info retrieval for a non-existent serial number.
    Scenario: The serial number does not exist in the database.
    """
    # Act: Make a GET request with a serial that does not exist
    response = client.get("/api/pcinfo?serial=NONEXISTENTSERIAL")

    # Assert: Check the response
    assert response.status_code == 404
    data = json.loads(response.data)
    assert data['error'] == 'Not Found'
    assert 'not found' in data['message']


def test_create_log_success(client, app, sample_log_data):
    """
    Test successful creation of a setup log entry.
    """
    # Act: Make a POST request to the log endpoint
    response = client.post('/api/log',
                           data=json.dumps(sample_log_data),
                           content_type='application/json')

    # Assert: Check the response
    assert response.status_code == 201
    data = json.loads(response.data)
    assert data['result'] == 'ok'
    assert 'log_id' in data

    # Assert: Check if the log was actually saved to the database
    with app.app_context():
        from models.setup_log import SetupLog
        log_entry = SetupLog.query.filter_by(serial=sample_log_data['serial']).first()
        assert log_entry is not None
        assert log_entry.id == data['log_id']
        assert log_entry.status == sample_log_data['status']
