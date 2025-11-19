"""ODJ File Upload API endpoints."""
import os
import logging
from pathlib import Path
from flask import request, jsonify, current_app
from werkzeug.utils import secure_filename
from . import api_bp
from models import db
from models.pc_master import PCMaster
from utils.drbl_client import DRBLClient

logger = logging.getLogger(__name__)

# Initialize DRBL client
drbl_client = DRBLClient()

# Allowed file extensions
ALLOWED_EXTENSIONS = {'txt', 'odj'}


def allowed_file(filename):
    """Check if file extension is allowed.

    Args:
        filename: Name of the file

    Returns:
        bool: True if allowed, False otherwise
    """
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


@api_bp.route('/odj/upload', methods=['POST'])
def upload_odj():
    """Upload ODJ file and associate with PC.

    Request form data:
        - file: ODJ file
        - pcname: PC name to associate with (optional)
        - serial: Serial number to associate with (optional)

    Returns:
        JSON response with upload result
    """
    try:
        # Check if file is present
        if 'file' not in request.files:
            return jsonify({
                'error': 'No file provided',
                'field': 'file'
            }), 400

        file = request.files['file']

        # Check if file is selected
        if file.filename == '':
            return jsonify({
                'error': 'No file selected',
                'field': 'file'
            }), 400

        # Check file extension
        if not allowed_file(file.filename):
            return jsonify({
                'error': f'Invalid file format. Allowed extensions: {", ".join(ALLOWED_EXTENSIONS)}',
                'field': 'file'
            }), 400

        # Get ODJ files directory from config
        odj_dir = Path(current_app.config['ODJ_FILES_PATH'])

        # Create directory if it doesn't exist
        odj_dir.mkdir(parents=True, exist_ok=True)

        # Secure filename
        filename = secure_filename(file.filename)

        # Check for file size (max 10MB)
        file.seek(0, os.SEEK_END)
        file_size = file.tell()
        file.seek(0)

        max_size = 10 * 1024 * 1024  # 10MB
        if file_size > max_size:
            return jsonify({
                'error': f'File size exceeds maximum allowed size ({max_size / 1024 / 1024:.1f}MB)',
                'field': 'file',
                'file_size': file_size,
                'max_size': max_size
            }), 400

        # Save file
        file_path = odj_dir / filename
        file.save(str(file_path))

        logger.info(f'ODJ file uploaded: {filename} ({file_size} bytes)')

        # Get pcname or serial from form
        pcname = request.form.get('pcname', '').strip()
        serial = request.form.get('serial', '').strip()

        # Associate with PC if pcname or serial provided
        pc_updated = None
        if pcname or serial:
            try:
                # Find PC record
                if serial:
                    pc = PCMaster.find_by_serial(serial)
                elif pcname:
                    pc = PCMaster.find_by_pcname(pcname)
                else:
                    pc = None

                if pc:
                    # Update ODJ path
                    pc.odj_path = str(file_path)
                    db.session.commit()
                    pc_updated = pc.to_dict()
                    logger.info(f'ODJ file associated with PC: {pc.pcname} ({pc.serial})')
                else:
                    logger.warning(f'PC not found for ODJ file association: pcname={pcname}, serial={serial}')

            except Exception as e:
                logger.error(f'Error associating ODJ file with PC: {e}')
                # Don't fail the upload, just log the error

        return jsonify({
            'success': True,
            'message': 'ODJ file uploaded successfully',
            'file': {
                'filename': filename,
                'path': str(file_path),
                'size': file_size
            },
            'pc_updated': pc_updated
        }), 201

    except Exception as e:
        logger.error(f'ODJ upload error: {e}')
        return jsonify({
            'error': 'Failed to upload ODJ file',
            'details': str(e)
        }), 500


@api_bp.route('/odj/list', methods=['GET'])
def list_odj_files():
    """List all ODJ files in the directory.

    Returns:
        JSON response with list of ODJ files
    """
    try:
        # Use DRBL client to list ODJ files
        odj_files = drbl_client.list_odj_files()

        # Get associated PCs for each ODJ file
        for odj_file in odj_files:
            pc = PCMaster.query.filter_by(odj_path=odj_file['path']).first()
            odj_file['associated_pc'] = pc.to_dict() if pc else None

        return jsonify({
            'success': True,
            'count': len(odj_files),
            'files': odj_files
        }), 200

    except Exception as e:
        logger.error(f'Error listing ODJ files: {e}')
        return jsonify({
            'error': 'Failed to list ODJ files',
            'details': str(e)
        }), 500


@api_bp.route('/odj/associate', methods=['POST'])
def associate_odj():
    """Associate ODJ file with PC.

    Request JSON:
        - odj_path: Path to ODJ file
        - pcname: PC name (optional)
        - serial: Serial number (optional)

    Returns:
        JSON response with association result
    """
    try:
        data = request.get_json()

        if not data:
            return jsonify({
                'error': 'No data provided'
            }), 400

        odj_path = data.get('odj_path', '').strip()
        pcname = data.get('pcname', '').strip()
        serial = data.get('serial', '').strip()

        # Validate inputs
        if not odj_path:
            return jsonify({
                'error': 'ODJ file path is required',
                'field': 'odj_path'
            }), 400

        if not pcname and not serial:
            return jsonify({
                'error': 'Either pcname or serial is required',
                'fields': ['pcname', 'serial']
            }), 400

        # Check if ODJ file exists
        if not Path(odj_path).exists():
            return jsonify({
                'error': 'ODJ file not found',
                'field': 'odj_path',
                'path': odj_path
            }), 404

        # Find PC record
        if serial:
            pc = PCMaster.find_by_serial(serial)
        elif pcname:
            pc = PCMaster.find_by_pcname(pcname)
        else:
            pc = None

        if not pc:
            return jsonify({
                'error': 'PC not found',
                'pcname': pcname,
                'serial': serial
            }), 404

        # Update ODJ path
        pc.odj_path = odj_path
        db.session.commit()

        logger.info(f'ODJ file associated: {odj_path} -> {pc.pcname} ({pc.serial})')

        return jsonify({
            'success': True,
            'message': 'ODJ file associated successfully',
            'pc': pc.to_dict()
        }), 200

    except Exception as e:
        db.session.rollback()
        logger.error(f'Error associating ODJ file: {e}')
        return jsonify({
            'error': 'Failed to associate ODJ file',
            'details': str(e)
        }), 500


@api_bp.route('/odj/delete/<path:filename>', methods=['DELETE'])
def delete_odj(filename):
    """Delete ODJ file.

    Args:
        filename: Name of the ODJ file to delete

    Returns:
        JSON response with deletion result
    """
    try:
        # Secure filename
        filename = secure_filename(filename)

        # Get ODJ files directory from config
        odj_dir = Path(current_app.config['ODJ_FILES_PATH'])
        file_path = odj_dir / filename

        # Check if file exists
        if not file_path.exists():
            return jsonify({
                'error': 'ODJ file not found',
                'filename': filename
            }), 404

        # Check if file is associated with any PC
        associated_pcs = PCMaster.query.filter_by(odj_path=str(file_path)).all()

        if associated_pcs:
            # Remove associations
            for pc in associated_pcs:
                pc.odj_path = None

            db.session.commit()
            logger.info(f'Removed ODJ associations for {len(associated_pcs)} PCs')

        # Delete file
        file_path.unlink()

        logger.info(f'ODJ file deleted: {filename}')

        return jsonify({
            'success': True,
            'message': 'ODJ file deleted successfully',
            'filename': filename,
            'removed_associations': len(associated_pcs)
        }), 200

    except Exception as e:
        db.session.rollback()
        logger.error(f'Error deleting ODJ file: {e}')
        return jsonify({
            'error': 'Failed to delete ODJ file',
            'details': str(e)
        }), 500
