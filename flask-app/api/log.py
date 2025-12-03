"""Setup Log API endpoint.

POST /api/log
Records setup progress logs.
"""
import logging
import re
from datetime import datetime
from flask import request, jsonify
from . import api_bp
from models import db, SetupLog

logger = logging.getLogger(__name__)


def validate_log_data(data):
    """Validate log request data.

    Args:
        data: Request data dictionary

    Returns:
        tuple: (is_valid, error_message, validated_data)
    """
    if not data:
        return False, "Request body is required", None

    # Required fields
    required_fields = ['serial', 'pcname', 'status', 'timestamp']
    missing_fields = [field for field in required_fields if field not in data]

    if missing_fields:
        return False, f"Missing required fields: {', '.join(missing_fields)}", None

    # Validate serial
    serial = data.get('serial')
    if not isinstance(serial, str) or len(serial) < 1 or len(serial) > 100:
        return False, "Serial must be a string between 1 and 100 characters", None

    if not re.match(r'^[A-Za-z0-9_-]+$', serial):
        return False, "Serial must contain only alphanumeric characters, hyphens, and underscores", None

    # Validate pcname
    pcname = data.get('pcname')
    if not isinstance(pcname, str) or len(pcname) < 1 or len(pcname) > 50:
        return False, "PC name must be a string between 1 and 50 characters", None

    # Validate status
    status = data.get('status')
    valid_statuses = [
        SetupLog.STATUS_PENDING,
        SetupLog.STATUS_IN_PROGRESS,
        SetupLog.STATUS_COMPLETED,
        SetupLog.STATUS_FAILED
    ]

    if status not in valid_statuses:
        return False, f"Status must be one of: {', '.join(valid_statuses)}", None

    # Validate timestamp (can be string or datetime)
    timestamp = data.get('timestamp')
    if isinstance(timestamp, str):
        try:
            # Try to parse timestamp string
            timestamp = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
        except (ValueError, AttributeError):
            # Try alternative format: "YYYY-MM-DD HH:MM:SS"
            try:
                timestamp = datetime.strptime(timestamp, '%Y-%m-%d %H:%M:%S')
            except ValueError:
                return False, "Invalid timestamp format. Use ISO format or 'YYYY-MM-DD HH:MM:SS'", None
    elif not isinstance(timestamp, datetime):
        return False, "Timestamp must be a string or datetime object", None

    # Optional fields validation
    logs = data.get('logs')
    if logs is not None and not isinstance(logs, str):
        return False, "Logs must be a string", None

    step = data.get('step')
    if step is not None:
        if not isinstance(step, str) or len(step) > 50:
            return False, "Step must be a string up to 50 characters", None

    error_message = data.get('error_message')
    if error_message is not None and not isinstance(error_message, str):
        return False, "Error message must be a string", None

    # Prepare validated data
    validated_data = {
        'serial': serial,
        'pcname': pcname,
        'status': status,
        'timestamp': timestamp,
        'logs': logs,
        'step': step,
        'error_message': error_message
    }

    return True, None, validated_data


@api_bp.route('/log', methods=['POST'])
def create_log():
    """Create a setup log entry.

    Request Body (JSON):
        {
            "serial": "ABC123456",           # Required: PC serial number
            "pcname": "20251116M",           # Required: PC name
            "status": "completed",           # Required: pending/in_progress/completed/failed
            "timestamp": "2025-11-16 12:33:22",  # Required: ISO format or YYYY-MM-DD HH:MM:SS
            "logs": "Setup completed",       # Optional: Log message
            "step": "windows_update",        # Optional: Current setup step
            "error_message": null            # Optional: Error message if failed
        }

    Returns:
        JSON response
        {
            "result": "ok",
            "log_id": 123
        }

    Status Codes:
        201: Created - Log entry created successfully
        400: Bad Request - Invalid request data
        500: Internal Server Error
    """
    # Get JSON data from request
    try:
        data = request.get_json()
    except Exception as e:
        logger.warning(f"Invalid JSON in request body - IP={request.remote_addr} - error={str(e)}")
        return jsonify({
            'error': 'Bad Request',
            'message': 'Invalid JSON in request body'
        }), 400

    # Log request
    logger.info(
        f"POST /api/log - serial={data.get('serial') if data else None} "
        f"pcname={data.get('pcname') if data else None} "
        f"status={data.get('status') if data else None} - "
        f"IP={request.remote_addr}"
    )

    # Validate request data
    is_valid, error_message, validated_data = validate_log_data(data)
    if not is_valid:
        logger.warning(f"Validation failed: {error_message} - data={data}")
        return jsonify({
            'error': 'Bad Request',
            'message': error_message
        }), 400

    try:
        # Create log entry
        log_entry = SetupLog(
            serial=validated_data['serial'],
            pcname=validated_data['pcname'],
            status=validated_data['status'],
            timestamp=validated_data['timestamp'],
            logs=validated_data['logs'],
            step=validated_data['step'],
            error_message=validated_data['error_message']
        )

        # Save to database
        db.session.add(log_entry)
        db.session.commit()

        logger.info(
            f"Log entry created - log_id={log_entry.id} serial={log_entry.serial} "
            f"pcname={log_entry.pcname} status={log_entry.status}"
        )

        # Return success response
        return jsonify({
            'result': 'ok',
            'log_id': log_entry.id
        }), 201

    except Exception as e:
        # Rollback on error
        db.session.rollback()

        logger.error(
            f"Failed to create log entry - serial={validated_data.get('serial')} "
            f"pcname={validated_data.get('pcname')} - error={str(e)}",
            exc_info=True
        )

        return jsonify({
            'error': 'Internal Server Error',
            'message': 'An unexpected error occurred while creating log entry'
        }), 500
