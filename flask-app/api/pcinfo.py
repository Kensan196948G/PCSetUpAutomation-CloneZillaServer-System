"""PC Info API endpoint.

GET /api/pcinfo?serial=XXX
Returns PC name and ODJ file path for a given serial number.
"""
import logging
import time
import re
from flask import request, jsonify, current_app
from . import api_bp
from models import PCMaster

logger = logging.getLogger(__name__)


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
        return False, "Serial number must contain only alphanumeric characters, hyphens, and underscores"

    return True, None


@api_bp.route('/pcinfo', methods=['GET'])
def get_pc_info():
    """Get PC information by serial number.

    Query Parameters:
        serial (str): PC serial number (required, 1-100 alphanumeric characters)

    Returns:
        JSON response with pcname and odj_path
        {
            "pcname": "20251116M",
            "odj_path": "/srv/odj/20251116M.txt"
        }

    Status Codes:
        200: Success - PC information found
        400: Bad Request - Missing or invalid serial parameter
        404: Not Found - PC not found in database
        500: Internal Server Error

    Response Time Target: < 200ms
    """
    start_time = time.time()

    # Get serial parameter from query string
    serial = request.args.get('serial')

    # Log access
    logger.info(f"GET /api/pcinfo - serial={serial} - IP={request.remote_addr}")

    # Validate serial parameter
    is_valid, error_message = validate_serial(serial)
    if not is_valid:
        logger.warning(f"Invalid serial parameter: {error_message} - serial={serial}")
        return jsonify({
            'error': 'Bad Request',
            'message': error_message
        }), 400

    try:
        # Query database for PC information
        pc = PCMaster.find_by_serial(serial)

        if pc is None:
            # PC not found
            elapsed_time = (time.time() - start_time) * 1000
            logger.warning(f"PC not found - serial={serial} - elapsed={elapsed_time:.2f}ms")
            return jsonify({
                'error': 'Not Found',
                'message': f'PC with serial number "{serial}" not found'
            }), 404

        # Success - return PC information
        elapsed_time = (time.time() - start_time) * 1000
        logger.info(
            f"PC info retrieved - serial={serial} pcname={pc.pcname} "
            f"elapsed={elapsed_time:.2f}ms"
        )

        # Warn if response time exceeds target
        if elapsed_time > 200:
            logger.warning(
                f"Response time exceeded target (200ms): {elapsed_time:.2f}ms - "
                f"serial={serial}"
            )

        return jsonify({
            'pcname': pc.pcname,
            'odj_path': pc.odj_path
        }), 200

    except Exception as e:
        # Internal server error
        elapsed_time = (time.time() - start_time) * 1000
        logger.error(
            f"Internal error - serial={serial} elapsed={elapsed_time:.2f}ms - "
            f"error={str(e)}",
            exc_info=True
        )
        return jsonify({
            'error': 'Internal Server Error',
            'message': 'An unexpected error occurred while retrieving PC information'
        }), 500
