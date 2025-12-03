"""PC CRUD API endpoints.

GET /api/pcs - List all PCs (with pagination)
POST /api/pcs - Create new PC or bulk import from CSV
PUT /api/pcs/<id> - Update PC information
DELETE /api/pcs/<id> - Delete PC
"""
import logging
import csv
import io
from flask import request, jsonify
from sqlalchemy.exc import IntegrityError
from . import api_bp
from .validators import (
    validate_pc_data,
    validate_pagination,
    validate_csv_row
)
from models import db, PCMaster

logger = logging.getLogger(__name__)


@api_bp.route('/pcs', methods=['GET'])
def list_pcs():
    """List all PCs with pagination support.

    Query Parameters:
        page (int): Page number (default: 1)
        per_page (int): Items per page (default: 20, max: 100)
        serial (str): Filter by serial number (partial match)
        pcname (str): Filter by PC name (partial match)

    Returns:
        JSON response with paginated PC list
        {
            "items": [...],
            "total": 100,
            "page": 1,
            "per_page": 20,
            "pages": 5
        }

    Status Codes:
        200: Success
        400: Bad Request - Invalid pagination parameters
        500: Internal Server Error
    """
    logger.info(f"GET /api/pcs - IP={request.remote_addr}")

    # Get pagination parameters
    page = request.args.get('page', 1)
    per_page = request.args.get('per_page', 20)

    # Validate pagination
    is_valid, error_msg, page, per_page = validate_pagination(page, per_page)
    if not is_valid:
        return jsonify({
            'error': 'Bad Request',
            'message': error_msg
        }), 400

    try:
        # Build query
        query = PCMaster.query

        # Apply filters
        serial_filter = request.args.get('serial')
        if serial_filter:
            query = query.filter(PCMaster.serial.ilike(f'%{serial_filter}%'))

        pcname_filter = request.args.get('pcname')
        if pcname_filter:
            query = query.filter(PCMaster.pcname.ilike(f'%{pcname_filter}%'))

        # Order by created_at descending
        query = query.order_by(PCMaster.created_at.desc())

        # Paginate
        pagination = query.paginate(
            page=page,
            per_page=per_page,
            error_out=False
        )

        # Convert to dict
        items = [pc.to_dict() for pc in pagination.items]

        logger.info(
            f"PCs listed - page={page} per_page={per_page} total={pagination.total}"
        )

        return jsonify({
            'items': items,
            'total': pagination.total,
            'page': pagination.page,
            'per_page': pagination.per_page,
            'pages': pagination.pages
        }), 200

    except Exception as e:
        logger.error(f"Failed to list PCs - error={str(e)}", exc_info=True)
        return jsonify({
            'error': 'Internal Server Error',
            'message': 'An unexpected error occurred while listing PCs'
        }), 500


@api_bp.route('/pcs', methods=['POST'])
def create_pc():
    """Create new PC or bulk import from CSV.

    Request Body (JSON):
        Single PC:
        {
            "serial": "ABC123456",
            "pcname": "20251116M",
            "odj_path": "/srv/odj/20251116M.txt"
        }

        CSV Import (multipart/form-data):
        - file: CSV file with columns: serial, pcname, odj_path

    Returns:
        JSON response
        Single PC: {"result": "ok", "pc_id": 123}
        CSV Import: {"result": "ok", "imported": 50, "failed": 2, "errors": [...]}

    Status Codes:
        201: Created - PC created successfully
        400: Bad Request - Invalid request data
        409: Conflict - PC with serial already exists
        500: Internal Server Error
    """
    logger.info(f"POST /api/pcs - IP={request.remote_addr}")

    # Check if this is a CSV import
    if 'file' in request.files:
        return handle_csv_import()

    # Handle single PC creation
    try:
        data = request.get_json()
    except Exception as e:
        logger.warning(f"Invalid JSON - error={str(e)}")
        return jsonify({
            'error': 'Bad Request',
            'message': 'Invalid JSON in request body'
        }), 400

    # Validate PC data
    is_valid, error_msg, validated_data = validate_pc_data(data)
    if not is_valid:
        logger.warning(f"Validation failed: {error_msg}")
        return jsonify({
            'error': 'Bad Request',
            'message': error_msg
        }), 400

    try:
        # Check if PC with serial already exists
        existing_pc = PCMaster.find_by_serial(validated_data['serial'])
        if existing_pc:
            logger.warning(f"PC already exists - serial={validated_data['serial']}")
            return jsonify({
                'error': 'Conflict',
                'message': f'PC with serial "{validated_data["serial"]}" already exists'
            }), 409

        # Create new PC
        pc = PCMaster(
            serial=validated_data['serial'],
            pcname=validated_data['pcname'],
            odj_path=validated_data.get('odj_path')
        )

        db.session.add(pc)
        db.session.commit()

        logger.info(
            f"PC created - pc_id={pc.id} serial={pc.serial} pcname={pc.pcname}"
        )

        return jsonify({
            'result': 'ok',
            'pc_id': pc.id,
            'pc': pc.to_dict()
        }), 201

    except IntegrityError as e:
        db.session.rollback()
        logger.error(f"Integrity error - error={str(e)}")
        return jsonify({
            'error': 'Conflict',
            'message': 'PC with this serial already exists'
        }), 409

    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to create PC - error={str(e)}", exc_info=True)
        return jsonify({
            'error': 'Internal Server Error',
            'message': 'An unexpected error occurred while creating PC'
        }), 500


def handle_csv_import():
    """Handle CSV bulk import.

    Returns:
        JSON response with import results
    """
    file = request.files['file']

    if not file or not file.filename:
        return jsonify({
            'error': 'Bad Request',
            'message': 'No file provided'
        }), 400

    if not file.filename.endswith('.csv'):
        return jsonify({
            'error': 'Bad Request',
            'message': 'File must be a CSV file'
        }), 400

    try:
        # Read CSV file
        stream = io.StringIO(file.stream.read().decode('utf-8'), newline=None)
        csv_reader = csv.DictReader(stream)

        imported = 0
        failed = 0
        errors = []

        for row_num, row in enumerate(csv_reader, start=2):  # Start at 2 (1 is header)
            # Validate row
            is_valid, error_msg, validated_data = validate_csv_row(row)
            if not is_valid:
                failed += 1
                errors.append({
                    'row': row_num,
                    'error': error_msg,
                    'data': row
                })
                continue

            # Check if PC already exists
            existing_pc = PCMaster.find_by_serial(validated_data['serial'])
            if existing_pc:
                failed += 1
                errors.append({
                    'row': row_num,
                    'error': f'PC with serial "{validated_data["serial"]}" already exists',
                    'data': row
                })
                continue

            try:
                # Create PC
                pc = PCMaster(
                    serial=validated_data['serial'],
                    pcname=validated_data['pcname'],
                    odj_path=validated_data.get('odj_path')
                )
                db.session.add(pc)
                imported += 1

            except Exception as e:
                failed += 1
                errors.append({
                    'row': row_num,
                    'error': str(e),
                    'data': row
                })

        # Commit all changes
        db.session.commit()

        logger.info(f"CSV import completed - imported={imported} failed={failed}")

        return jsonify({
            'result': 'ok',
            'imported': imported,
            'failed': failed,
            'errors': errors if errors else None
        }), 201

    except Exception as e:
        db.session.rollback()
        logger.error(f"CSV import failed - error={str(e)}", exc_info=True)
        return jsonify({
            'error': 'Internal Server Error',
            'message': f'CSV import failed: {str(e)}'
        }), 500


@api_bp.route('/pcs/<int:pc_id>', methods=['PUT'])
def update_pc(pc_id):
    """Update PC information.

    Path Parameters:
        pc_id (int): PC ID

    Request Body (JSON):
        {
            "pcname": "20251117M",
            "odj_path": "/srv/odj/20251117M.txt"
        }

    Returns:
        JSON response
        {
            "result": "ok",
            "pc": {...}
        }

    Status Codes:
        200: Success - PC updated
        400: Bad Request - Invalid request data
        404: Not Found - PC not found
        500: Internal Server Error
    """
    logger.info(f"PUT /api/pcs/{pc_id} - IP={request.remote_addr}")

    # Get PC by ID
    pc = PCMaster.query.get(pc_id)
    if not pc:
        logger.warning(f"PC not found - pc_id={pc_id}")
        return jsonify({
            'error': 'Not Found',
            'message': f'PC with ID {pc_id} not found'
        }), 404

    # Get request data
    try:
        data = request.get_json()
    except Exception as e:
        logger.warning(f"Invalid JSON - error={str(e)}")
        return jsonify({
            'error': 'Bad Request',
            'message': 'Invalid JSON in request body'
        }), 400

    # Validate PC data (for update)
    is_valid, error_msg, validated_data = validate_pc_data(data, is_update=True)
    if not is_valid:
        logger.warning(f"Validation failed: {error_msg}")
        return jsonify({
            'error': 'Bad Request',
            'message': error_msg
        }), 400

    try:
        # Update PC fields
        if 'pcname' in validated_data:
            pc.pcname = validated_data['pcname']

        if 'odj_path' in validated_data:
            pc.odj_path = validated_data['odj_path']

        db.session.commit()

        logger.info(
            f"PC updated - pc_id={pc.id} serial={pc.serial} pcname={pc.pcname}"
        )

        return jsonify({
            'result': 'ok',
            'pc': pc.to_dict()
        }), 200

    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to update PC - pc_id={pc_id} error={str(e)}", exc_info=True)
        return jsonify({
            'error': 'Internal Server Error',
            'message': 'An unexpected error occurred while updating PC'
        }), 500


@api_bp.route('/pcs/<int:pc_id>', methods=['DELETE'])
def delete_pc(pc_id):
    """Delete PC.

    Path Parameters:
        pc_id (int): PC ID

    Returns:
        JSON response
        {
            "result": "ok",
            "message": "PC deleted successfully"
        }

    Status Codes:
        200: Success - PC deleted
        404: Not Found - PC not found
        500: Internal Server Error
    """
    logger.info(f"DELETE /api/pcs/{pc_id} - IP={request.remote_addr}")

    # Get PC by ID
    pc = PCMaster.query.get(pc_id)
    if not pc:
        logger.warning(f"PC not found - pc_id={pc_id}")
        return jsonify({
            'error': 'Not Found',
            'message': f'PC with ID {pc_id} not found'
        }), 404

    try:
        # Delete PC
        serial = pc.serial
        pcname = pc.pcname

        db.session.delete(pc)
        db.session.commit()

        logger.info(f"PC deleted - pc_id={pc_id} serial={serial} pcname={pcname}")

        return jsonify({
            'result': 'ok',
            'message': 'PC deleted successfully'
        }), 200

    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to delete PC - pc_id={pc_id} error={str(e)}", exc_info=True)
        return jsonify({
            'error': 'Internal Server Error',
            'message': 'An unexpected error occurred while deleting PC'
        }), 500
