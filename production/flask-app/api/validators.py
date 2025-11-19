"""Validation helper functions for API endpoints."""
import re
from datetime import datetime


def validate_serial(serial):
    """Validate serial number format.

    Args:
        serial: Serial number string

    Returns:
        tuple: (is_valid, error_message)
    """
    if not serial:
        return False, "Serial number is required"

    if not isinstance(serial, str):
        return False, "Serial number must be a string"

    if len(serial) < 1 or len(serial) > 100:
        return False, "Serial number must be between 1 and 100 characters"

    # Allow alphanumeric characters, hyphens, and underscores
    if not re.match(r'^[A-Za-z0-9_-]+$', serial):
        return False, "Serial must contain only alphanumeric characters, hyphens, and underscores"

    return True, None


def validate_pcname(pcname):
    """Validate PC name format.

    Args:
        pcname: PC name string

    Returns:
        tuple: (is_valid, error_message)
    """
    if not pcname:
        return False, "PC name is required"

    if not isinstance(pcname, str):
        return False, "PC name must be a string"

    if len(pcname) < 1 or len(pcname) > 50:
        return False, "PC name must be between 1 and 50 characters"

    # Optionally validate YYYYMMDDM format
    # if not re.match(r'^\d{8}M$', pcname):
    #     return False, "PC name must be in YYYYMMDDM format (e.g., 20251116M)"

    return True, None


def validate_odj_path(odj_path):
    """Validate ODJ file path format.

    Args:
        odj_path: ODJ file path string

    Returns:
        tuple: (is_valid, error_message)
    """
    if odj_path is None:
        return True, None  # ODJ path is optional

    if not isinstance(odj_path, str):
        return False, "ODJ path must be a string"

    if len(odj_path) > 255:
        return False, "ODJ path must not exceed 255 characters"

    return True, None


def validate_status(status):
    """Validate setup status.

    Args:
        status: Status string

    Returns:
        tuple: (is_valid, error_message)
    """
    valid_statuses = ['pending', 'in_progress', 'completed', 'failed']

    if not status:
        return False, "Status is required"

    if status not in valid_statuses:
        return False, f"Status must be one of: {', '.join(valid_statuses)}"

    return True, None


def validate_timestamp(timestamp):
    """Validate and parse timestamp.

    Args:
        timestamp: Timestamp string or datetime object

    Returns:
        tuple: (is_valid, error_message, parsed_timestamp)
    """
    if timestamp is None:
        return True, None, None

    if isinstance(timestamp, datetime):
        return True, None, timestamp

    if isinstance(timestamp, str):
        try:
            # Try to parse timestamp string (ISO format)
            parsed = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
            return True, None, parsed
        except (ValueError, AttributeError):
            # Try alternative format: "YYYY-MM-DD HH:MM:SS"
            try:
                parsed = datetime.strptime(timestamp, '%Y-%m-%d %H:%M:%S')
                return True, None, parsed
            except ValueError:
                return False, "Invalid timestamp format. Use ISO format or 'YYYY-MM-DD HH:MM:SS'", None

    return False, "Timestamp must be a string or datetime object", None


def validate_pagination(page, per_page, max_per_page=100):
    """Validate pagination parameters.

    Args:
        page: Page number (1-indexed)
        per_page: Items per page
        max_per_page: Maximum items per page

    Returns:
        tuple: (is_valid, error_message, validated_page, validated_per_page)
    """
    # Validate page
    try:
        page = int(page) if page else 1
        if page < 1:
            return False, "Page must be >= 1", None, None
    except (ValueError, TypeError):
        return False, "Page must be a valid integer", None, None

    # Validate per_page
    try:
        if per_page is None or per_page == '':
            per_page = 20
        else:
            per_page = int(per_page)
            if per_page < 1:
                return False, "Per page must be >= 1", None, None
            if per_page > max_per_page:
                return False, f"Per page must be <= {max_per_page}", None, None
    except (ValueError, TypeError):
        return False, "Per page must be a valid integer", None, None

    return True, None, page, per_page


def validate_pc_data(data, is_update=False):
    """Validate PC data for creation or update.

    Args:
        data: PC data dictionary
        is_update: Whether this is an update operation

    Returns:
        tuple: (is_valid, error_message, validated_data)
    """
    if not data:
        return False, "Request body is required", None

    validated_data = {}

    # Validate serial (required for creation, optional for update)
    if 'serial' in data or not is_update:
        serial = data.get('serial')
        is_valid, error_msg = validate_serial(serial)
        if not is_valid:
            return False, error_msg, None
        validated_data['serial'] = serial

    # Validate pcname (required for creation, optional for update)
    if 'pcname' in data or not is_update:
        pcname = data.get('pcname')
        is_valid, error_msg = validate_pcname(pcname)
        if not is_valid:
            return False, error_msg, None
        validated_data['pcname'] = pcname

    # Validate odj_path (optional)
    if 'odj_path' in data:
        odj_path = data.get('odj_path')
        is_valid, error_msg = validate_odj_path(odj_path)
        if not is_valid:
            return False, error_msg, None
        validated_data['odj_path'] = odj_path

    return True, None, validated_data


def validate_csv_row(row):
    """Validate a single CSV row for PC import.

    Args:
        row: Dictionary representing a CSV row

    Returns:
        tuple: (is_valid, error_message, validated_data)
    """
    validated_data = {}

    # Validate serial
    serial = row.get('serial', '').strip()
    is_valid, error_msg = validate_serial(serial)
    if not is_valid:
        return False, f"Invalid serial: {error_msg}", None
    validated_data['serial'] = serial

    # Validate pcname
    pcname = row.get('pcname', '').strip()
    is_valid, error_msg = validate_pcname(pcname)
    if not is_valid:
        return False, f"Invalid pcname: {error_msg}", None
    validated_data['pcname'] = pcname

    # Validate odj_path (optional)
    odj_path = row.get('odj_path', '').strip() or None
    if odj_path:
        is_valid, error_msg = validate_odj_path(odj_path)
        if not is_valid:
            return False, f"Invalid odj_path: {error_msg}", None
    validated_data['odj_path'] = odj_path

    return True, None, validated_data
