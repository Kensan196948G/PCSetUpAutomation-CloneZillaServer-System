"""Import and Upload views."""
import os
import csv
from io import StringIO
from datetime import datetime
from werkzeug.utils import secure_filename
from flask import (
    render_template, request, redirect, url_for,
    flash, jsonify, current_app
)
from . import views_bp
from models import db, PCMaster


ALLOWED_CSV_EXTENSIONS = {'csv'}
ALLOWED_ODJ_EXTENSIONS = {'txt', 'blob'}


def allowed_file(filename, extensions):
    """Check if file extension is allowed.

    Args:
        filename: Name of the file
        extensions: Set of allowed extensions

    Returns:
        bool: True if allowed, False otherwise
    """
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in extensions


@views_bp.route('/import')
def csv_import():
    """CSV import page.

    Returns:
        Rendered import template
    """
    return render_template('import.html')


@views_bp.route('/import/upload', methods=['POST'])
def import_upload():
    """Handle CSV file upload and preview.

    Returns:
        JSON response with preview data or error
    """
    if 'file' not in request.files:
        return jsonify({'error': 'ファイルが選択されていません'}), 400

    file = request.files['file']

    if file.filename == '':
        return jsonify({'error': 'ファイルが選択されていません'}), 400

    if not allowed_file(file.filename, ALLOWED_CSV_EXTENSIONS):
        return jsonify({'error': 'CSVファイルのみアップロード可能です'}), 400

    try:
        # Read CSV file
        stream = StringIO(file.stream.read().decode('utf-8'))
        csv_reader = csv.DictReader(stream)

        # Get headers
        headers = csv_reader.fieldnames

        # Validate required columns
        required_columns = {'serial', 'pcname'}
        if not required_columns.issubset(set(headers)):
            return jsonify({
                'error': f'必須列が不足しています: {", ".join(required_columns)}'
            }), 400

        # Read rows (preview first 10)
        rows = []
        all_rows = []
        for i, row in enumerate(csv_reader):
            all_rows.append(row)
            if i < 10:
                rows.append(row)

        return jsonify({
            'success': True,
            'headers': headers,
            'preview': rows,
            'total_rows': len(all_rows),
            'data': all_rows  # Store for actual import
        })

    except Exception as e:
        current_app.logger.error(f'CSV parse error: {str(e)}')
        return jsonify({'error': f'CSVファイルの解析に失敗しました: {str(e)}'}), 400


@views_bp.route('/import/execute', methods=['POST'])
def import_execute():
    """Execute CSV import to database.

    Returns:
        JSON response with import results
    """
    try:
        data = request.get_json()
        rows = data.get('rows', [])

        if not rows:
            return jsonify({'error': 'インポートするデータがありません'}), 400

        success_count = 0
        error_count = 0
        errors = []

        for row in rows:
            serial = row.get('serial', '').strip()
            pcname = row.get('pcname', '').strip()
            odj_path = row.get('odj_path', '').strip()

            # Validation
            if not serial or not pcname:
                errors.append(f'行をスキップ: Serial={serial}, PCName={pcname} (必須項目が空)')
                error_count += 1
                continue

            # Check for duplicate
            existing = PCMaster.find_by_serial(serial)
            if existing:
                errors.append(f'Serial番号 {serial} は既に登録されています (スキップ)')
                error_count += 1
                continue

            # Create new PC record
            try:
                pc = PCMaster(
                    serial=serial,
                    pcname=pcname,
                    odj_path=odj_path if odj_path else None
                )
                db.session.add(pc)
                success_count += 1
            except Exception as e:
                errors.append(f'Serial={serial}: {str(e)}')
                error_count += 1

        # Commit all records
        try:
            db.session.commit()

            return jsonify({
                'success': True,
                'success_count': success_count,
                'error_count': error_count,
                'errors': errors
            })
        except Exception as e:
            db.session.rollback()
            current_app.logger.error(f'Import commit error: {str(e)}')
            return jsonify({'error': f'データベースへの保存に失敗しました: {str(e)}'}), 500

    except Exception as e:
        current_app.logger.error(f'Import execute error: {str(e)}')
        return jsonify({'error': f'インポート処理に失敗しました: {str(e)}'}), 500


@views_bp.route('/odj-upload')
def odj_upload():
    """ODJ file upload page.

    Returns:
        Rendered ODJ upload template
    """
    # Get all PCs without ODJ files
    pcs_without_odj = PCMaster.query.filter(
        (PCMaster.odj_path == None) | (PCMaster.odj_path == '')
    ).order_by(PCMaster.created_at.desc()).all()

    # Get all PCs with ODJ files
    pcs_with_odj = PCMaster.query.filter(
        PCMaster.odj_path != None,
        PCMaster.odj_path != ''
    ).order_by(PCMaster.created_at.desc()).limit(20).all()

    return render_template(
        'odj_upload.html',
        pcs_without_odj=pcs_without_odj,
        pcs_with_odj=pcs_with_odj
    )


@views_bp.route('/odj-upload/upload', methods=['POST'])
def odj_upload_file():
    """Handle ODJ file upload.

    Returns:
        JSON response with upload results
    """
    if 'files[]' not in request.files:
        return jsonify({'error': 'ファイルが選択されていません'}), 400

    files = request.files.getlist('files[]')

    if not files or files[0].filename == '':
        return jsonify({'error': 'ファイルが選択されていません'}), 400

    odj_path = current_app.config['ODJ_FILES_PATH']
    os.makedirs(odj_path, exist_ok=True)

    uploaded_files = []
    errors = []

    for file in files:
        if file and allowed_file(file.filename, ALLOWED_ODJ_EXTENSIONS):
            try:
                filename = secure_filename(file.filename)
                filepath = os.path.join(odj_path, filename)
                file.save(filepath)

                uploaded_files.append({
                    'filename': filename,
                    'path': filepath
                })
            except Exception as e:
                current_app.logger.error(f'File save error: {str(e)}')
                errors.append(f'{file.filename}: {str(e)}')
        else:
            errors.append(f'{file.filename}: 許可されていないファイル形式です')

    return jsonify({
        'success': True,
        'uploaded_files': uploaded_files,
        'errors': errors
    })


@views_bp.route('/odj-upload/bind', methods=['POST'])
def odj_bind():
    """Bind ODJ file to PC.

    Returns:
        JSON response
    """
    try:
        data = request.get_json()
        pc_id = data.get('pc_id')
        odj_path = data.get('odj_path')

        if not pc_id or not odj_path:
            return jsonify({'error': 'PC IDとODJパスが必要です'}), 400

        pc = PCMaster.query.get(pc_id)
        if not pc:
            return jsonify({'error': 'PCが見つかりません'}), 404

        # Update ODJ path
        pc.odj_path = odj_path
        db.session.commit()

        return jsonify({
            'success': True,
            'message': f'PC {pc.pcname} にODJファイルを紐付けました'
        })

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f'ODJ bind error: {str(e)}')
        return jsonify({'error': f'紐付けに失敗しました: {str(e)}'}), 500


@views_bp.route('/deployment/images')
def image_management():
    """Master image management page.

    Returns:
        Rendered image management template
    """
    # Get available Clonezilla images
    image_path = current_app.config['CLONEZILLA_IMAGE_PATH']
    images = []

    try:
        if os.path.exists(image_path):
            for d in os.listdir(image_path):
                full_path = os.path.join(image_path, d)
                if os.path.isdir(full_path):
                    # Get directory stats
                    stat = os.stat(full_path)
                    images.append({
                        'name': d,
                        'path': full_path,
                        'size': stat.st_size,
                        'modified': datetime.fromtimestamp(stat.st_mtime)
                    })
            images.sort(key=lambda x: x['modified'], reverse=True)
    except Exception as e:
        current_app.logger.error(f'Failed to list images: {str(e)}')
        flash('マスターイメージの一覧取得に失敗しました', 'warning')

    return render_template('image_management.html', images=images)


@views_bp.route('/deployment/settings')
def deploy_settings():
    """Deployment settings page.

    Returns:
        Rendered deployment template
    """
    # Get available Clonezilla images
    image_path = current_app.config['CLONEZILLA_IMAGE_PATH']
    images = []

    try:
        if os.path.exists(image_path):
            images = [d for d in os.listdir(image_path)
                     if os.path.isdir(os.path.join(image_path, d))]
            images.sort(reverse=True)  # Latest first
    except Exception as e:
        current_app.logger.error(f'Failed to list images: {str(e)}')
        flash('マスターイメージの一覧取得に失敗しました', 'warning')

    # Get all PCs with ODJ files
    pcs = PCMaster.query.filter(
        PCMaster.odj_path != None,
        PCMaster.odj_path != ''
    ).order_by(PCMaster.created_at.desc()).all()

    return render_template(
        'deployment.html',
        images=images,
        pcs=pcs
    )


@views_bp.route('/deployment/start', methods=['POST'])
def deployment_start():
    """Start deployment process.

    Returns:
        JSON response
    """
    try:
        data = request.get_json()
        image = data.get('image')
        pc_ids = data.get('pc_ids', [])
        mode = data.get('mode', 'multicast')  # multicast or unicast

        if not image or not pc_ids:
            return jsonify({'error': 'イメージとPCを選択してください'}), 400

        # Validate image exists
        image_path = current_app.config['CLONEZILLA_IMAGE_PATH']
        full_image_path = os.path.join(image_path, image)

        if not os.path.exists(full_image_path):
            return jsonify({'error': 'マスターイメージが見つかりません'}), 404

        # Validate PCs exist
        pcs = PCMaster.query.filter(PCMaster.id.in_(pc_ids)).all()

        if len(pcs) != len(pc_ids):
            return jsonify({'error': '一部のPCが見つかりません'}), 404

        # TODO: Implement actual Clonezilla deployment trigger
        # This would typically involve:
        # 1. Creating a Clonezilla job file
        # 2. Triggering DRBL/Clonezilla via command line
        # 3. Setting up monitoring

        current_app.logger.info(
            f'Deployment started: image={image}, mode={mode}, '
            f'pcs={[pc.pcname for pc in pcs]}'
        )

        return jsonify({
            'success': True,
            'message': f'{len(pcs)}台のPCへの展開を開始しました',
            'job_id': f'deploy_{image}_{len(pc_ids)}',  # Placeholder
            'pcs': [pc.to_dict() for pc in pcs]
        })

    except Exception as e:
        current_app.logger.error(f'Deployment start error: {str(e)}')
        return jsonify({'error': f'展開の開始に失敗しました: {str(e)}'}), 500


@views_bp.route('/deployment/status')
def deploy_status():
    """Deployment status dashboard.

    Returns:
        Rendered deployment status template
    """
    # Get recent setup logs
    from models import SetupLog

    # In-progress deployments
    in_progress = SetupLog.query.filter_by(
        status='in_progress'
    ).order_by(SetupLog.timestamp.desc()).all()

    # Completed deployments (last 20)
    completed = SetupLog.query.filter_by(
        status='completed'
    ).order_by(SetupLog.timestamp.desc()).limit(20).all()

    # Failed deployments
    failed = SetupLog.query.filter_by(
        status='failed'
    ).order_by(SetupLog.timestamp.desc()).limit(20).all()

    return render_template(
        'deployment_status.html',
        in_progress=in_progress,
        completed=completed,
        failed=failed
    )


@views_bp.route('/deployment-status/api')
def deployment_status_api():
    """API endpoint for real-time deployment status.

    Returns:
        JSON response with current deployment status
    """
    from models import SetupLog

    # Get all in-progress deployments
    in_progress = SetupLog.query.filter_by(
        status='in_progress'
    ).order_by(SetupLog.timestamp.desc()).all()

    return jsonify({
        'in_progress': [log.to_dict() for log in in_progress],
        'count': len(in_progress),
        'timestamp': datetime.now().isoformat()
    })
