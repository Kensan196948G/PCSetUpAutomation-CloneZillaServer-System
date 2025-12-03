"""Test helper functions and utilities."""
import os
import tempfile


def assert_valid_json_response(response, expected_status=200):
    """Assert response is valid JSON with expected status.

    Args:
        response: Flask test response
        expected_status: Expected HTTP status code

    Returns:
        Parsed JSON data
    """
    assert response.status_code == expected_status, \
        f"Expected status {expected_status}, got {response.status_code}"

    assert response.content_type == 'application/json' or \
           'application/json' in response.content_type, \
        f"Expected JSON response, got {response.content_type}"

    return response.get_json()


def assert_error_response(response, expected_status, error_keyword=None):
    """Assert response is an error response.

    Args:
        response: Flask test response
        expected_status: Expected HTTP status code
        error_keyword: Optional keyword to check in error message
    """
    assert response.status_code == expected_status

    json_data = response.get_json()
    assert 'error' in json_data, "Error response should contain 'error' field"

    if error_keyword:
        message = json_data.get('message', '').lower()
        assert error_keyword.lower() in message, \
            f"Expected '{error_keyword}' in error message, got: {message}"


def create_temp_csv_file(content, filename='test.csv'):
    """Create temporary CSV file for testing.

    Args:
        content: CSV content as string
        filename: Filename

    Returns:
        Path to temporary file
    """
    temp_dir = tempfile.mkdtemp()
    file_path = os.path.join(temp_dir, filename)

    with open(file_path, 'w') as f:
        f.write(content)

    return file_path


def create_temp_odj_file(content, filename='test.txt'):
    """Create temporary ODJ file for testing.

    Args:
        content: ODJ XML content as string
        filename: Filename

    Returns:
        Path to temporary file
    """
    temp_dir = tempfile.mkdtemp()
    file_path = os.path.join(temp_dir, filename)

    with open(file_path, 'w') as f:
        f.write(content)

    return file_path


def verify_pc_in_database(db_session, serial):
    """Verify PC exists in database.

    Args:
        db_session: Database session
        serial: PC serial number

    Returns:
        PCMaster object if found, None otherwise
    """
    from models import PCMaster
    return PCMaster.query.filter_by(serial=serial).first()


def verify_log_in_database(db_session, serial, status=None):
    """Verify setup log exists in database.

    Args:
        db_session: Database session
        serial: PC serial number
        status: Optional status to filter by

    Returns:
        List of SetupLog objects
    """
    from models import SetupLog

    query = SetupLog.query.filter_by(serial=serial)
    if status:
        query = query.filter_by(status=status)

    return query.all()


def compare_timestamps(ts1, ts2, tolerance_seconds=5):
    """Compare two timestamp strings with tolerance.

    Args:
        ts1: First timestamp string (ISO format)
        ts2: Second timestamp string (ISO format)
        tolerance_seconds: Tolerance in seconds

    Returns:
        True if timestamps are within tolerance
    """
    from datetime import datetime

    dt1 = datetime.fromisoformat(ts1.replace('Z', '+00:00'))
    dt2 = datetime.fromisoformat(ts2.replace('Z', '+00:00'))

    diff = abs((dt1 - dt2).total_seconds())
    return diff <= tolerance_seconds


def measure_execution_time(func, *args, **kwargs):
    """Measure function execution time.

    Args:
        func: Function to measure
        *args: Function arguments
        **kwargs: Function keyword arguments

    Returns:
        Tuple of (result, elapsed_time_seconds)
    """
    import time

    start_time = time.time()
    result = func(*args, **kwargs)
    elapsed_time = time.time() - start_time

    return result, elapsed_time


def generate_random_serial(prefix='TEST', length=8):
    """Generate random serial number for testing.

    Args:
        prefix: Serial number prefix
        length: Length of random suffix

    Returns:
        Random serial number string
    """
    import random
    import string

    suffix = ''.join(random.choices(string.digits, k=length))
    return f'{prefix}{suffix}'


def create_mock_deployment_status(deployment_id, pc_count, completed_count):
    """Create mock deployment status data.

    Args:
        deployment_id: Deployment ID
        pc_count: Total number of PCs
        completed_count: Number of completed PCs

    Returns:
        Mock deployment status dictionary
    """
    pcs = []
    for i in range(pc_count):
        status = 'completed' if i < completed_count else 'pending'
        progress = 100 if i < completed_count else 0

        pcs.append({
            'id': i + 1,
            'serial': f'PC{i:03d}',
            'pcname': f'2025111{i}M',
            'status': status,
            'progress': progress
        })

    overall_progress = (completed_count / pc_count) * 100 if pc_count > 0 else 0

    return {
        'id': deployment_id,
        'name': f'Test Deployment {deployment_id}',
        'status': 'running' if completed_count < pc_count else 'completed',
        'progress': overall_progress,
        'pcs': pcs,
        'total_pcs': pc_count,
        'completed_pcs': completed_count,
        'failed_pcs': 0,
        'pending_pcs': pc_count - completed_count
    }


class DatabaseTransaction:
    """Context manager for database transactions in tests."""

    def __init__(self, db_session):
        """Initialize transaction context.

        Args:
            db_session: Database session
        """
        self.db = db_session

    def __enter__(self):
        """Begin transaction."""
        return self.db

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Commit or rollback transaction."""
        if exc_type is None:
            self.db.session.commit()
        else:
            self.db.session.rollback()
        return False


class ResponseValidator:
    """Helper class for validating API responses."""

    def __init__(self, response):
        """Initialize validator.

        Args:
            response: Flask test response
        """
        self.response = response
        self.json_data = response.get_json() if response.data else None

    def assert_status(self, expected_status):
        """Assert response has expected status code."""
        assert self.response.status_code == expected_status, \
            f"Expected status {expected_status}, got {self.response.status_code}"
        return self

    def assert_success(self):
        """Assert response indicates success."""
        assert self.response.status_code in [200, 201], \
            f"Expected success status, got {self.response.status_code}"
        return self

    def assert_has_field(self, field_name):
        """Assert JSON response has specific field."""
        assert self.json_data is not None, "Response has no JSON data"
        assert field_name in self.json_data, \
            f"Expected field '{field_name}' in response"
        return self

    def assert_field_value(self, field_name, expected_value):
        """Assert JSON field has expected value."""
        self.assert_has_field(field_name)
        actual_value = self.json_data[field_name]
        assert actual_value == expected_value, \
            f"Expected {field_name}={expected_value}, got {actual_value}"
        return self

    def get_field(self, field_name):
        """Get field value from JSON response."""
        self.assert_has_field(field_name)
        return self.json_data[field_name]

    def get_json(self):
        """Get full JSON response."""
        return self.json_data
