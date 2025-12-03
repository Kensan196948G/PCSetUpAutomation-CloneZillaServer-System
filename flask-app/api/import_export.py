"""CSV Import/Export API endpoints."""
import csv
import io
import logging
from datetime import datetime
from flask import request, jsonify, current_app
from sqlalchemy.exc import IntegrityError
from . import api_bp
from models import db
from models.pc_master import PCMaster
from api.validators import validate_serial, validate_pcname

logger = logging.getLogger(__name__)


@api_bp.route('/import/csv', methods=['POST'])
def import_csv():
    """Import PC data from CSV file.

    Expected CSV format:
    serial,pcname,odj_path(optional)

    Returns:
        JSON response with import results
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
        if not file.filename.endswith('.csv'):
            return jsonify({
                'error': 'Invalid file format. Only CSV files are allowed',
                'field': 'file'
            }), 400

        # Read and parse CSV
        stream = io.StringIO(file.stream.read().decode('UTF-8'), newline=None)
        csv_reader = csv.DictReader(stream)

        # Validate CSV headers
        required_headers = {'serial', 'pcname'}
        headers = set(csv_reader.fieldnames or [])

        if not required_headers.issubset(headers):
            missing = required_headers - headers
            return jsonify({
                'error': f'Missing required columns: {", ".join(missing)}',
                'required_headers': list(required_headers),
                'found_headers': list(headers)
            }), 400

        # Process CSV rows
        success_count = 0
        error_count = 0
        errors = []
        duplicates = []
        imported_records = []

        for row_num, row in enumerate(csv_reader, start=2):  # Start from 2 (1 is header)
            try:
                serial = row.get('serial', '').strip()
                pcname = row.get('pcname', '').strip()
                odj_path = row.get('odj_path', '').strip() or None

                # Validate data
                if not serial:
                    errors.append({
                        'row': row_num,
                        'error': 'Serial number is required',
                        'data': row
                    })
                    error_count += 1
                    continue

                if not pcname:
                    errors.append({
                        'row': row_num,
                        'error': 'PC name is required',
                        'data': row
                    })
                    error_count += 1
                    continue

                # Validate serial format
                if not validate_serial(serial):
                    errors.append({
                        'row': row_num,
                        'error': 'Invalid serial number format',
                        'data': row
                    })
                    error_count += 1
                    continue

                # Validate PC name format
                if not validate_pcname(pcname):
                    errors.append({
                        'row': row_num,
                        'error': 'Invalid PC name format (expected: YYYYMMDDM)',
                        'data': row
                    })
                    error_count += 1
                    continue

                # Check for duplicates in database
                existing = PCMaster.find_by_serial(serial)
                if existing:
                    duplicates.append({
                        'row': row_num,
                        'serial': serial,
                        'existing_pcname': existing.pcname,
                        'new_pcname': pcname
                    })
                    error_count += 1
                    continue

                # Create new PC record
                pc = PCMaster(
                    serial=serial,
                    pcname=pcname,
                    odj_path=odj_path
                )

                db.session.add(pc)
                imported_records.append({
                    'row': row_num,
                    'serial': serial,
                    'pcname': pcname
                })
                success_count += 1

            except Exception as e:
                logger.error(f'Error processing row {row_num}: {e}')
                errors.append({
                    'row': row_num,
                    'error': str(e),
                    'data': row
                })
                error_count += 1

        # Commit transaction if any records were added
        if success_count > 0:
            try:
                db.session.commit()
                logger.info(f'CSV import completed: {success_count} records imported')
            except IntegrityError as e:
                db.session.rollback()
                logger.error(f'Database integrity error during CSV import: {e}')
                return jsonify({
                    'error': 'Database integrity error. Some records may have duplicate serial numbers.',
                    'details': str(e)
                }), 500
            except Exception as e:
                db.session.rollback()
                logger.error(f'Error committing CSV import: {e}')
                return jsonify({
                    'error': 'Failed to save imported records',
                    'details': str(e)
                }), 500

        # Return results
        return jsonify({
            'success': True,
            'summary': {
                'total_rows': success_count + error_count,
                'success_count': success_count,
                'error_count': error_count,
                'duplicate_count': len(duplicates)
            },
            'imported_records': imported_records[:10],  # Show first 10
            'errors': errors[:10],  # Show first 10 errors
            'duplicates': duplicates[:10],  # Show first 10 duplicates
            'message': f'Imported {success_count} records successfully'
        }), 200

    except Exception as e:
        db.session.rollback()
        logger.error(f'CSV import error: {e}')
        return jsonify({
            'error': 'Failed to process CSV file',
            'details': str(e)
        }), 500


@api_bp.route('/export/csv', methods=['GET'])
def export_csv():
    """Export PC data to CSV format.

    Returns:
        CSV file with PC data
    """
    try:
        # Get all PC records
        pcs = PCMaster.query.order_by(PCMaster.created_at.desc()).all()

        # Create CSV in memory
        output = io.StringIO()
        writer = csv.writer(output)

        # Write header
        writer.writerow(['serial', 'pcname', 'odj_path', 'created_at'])

        # Write data
        for pc in pcs:
            writer.writerow([
                pc.serial,
                pc.pcname,
                pc.odj_path or '',
                pc.created_at.isoformat() if pc.created_at else ''
            ])

        # Prepare response
        output.seek(0)
        response = current_app.make_response(output.getvalue())
        response.headers['Content-Type'] = 'text/csv'
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        response.headers['Content-Disposition'] = f'attachment; filename=pc_master_export_{timestamp}.csv'

        logger.info(f'CSV export completed: {len(pcs)} records')
        return response

    except Exception as e:
        logger.error(f'CSV export error: {e}')
        return jsonify({
            'error': 'Failed to export CSV',
            'details': str(e)
        }), 500
