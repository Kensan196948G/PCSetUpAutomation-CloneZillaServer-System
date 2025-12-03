"""Import/Export views."""
import logging
from flask import render_template, request, redirect, url_for, flash
from werkzeug.utils import secure_filename
import os
import csv
from . import views_bp
from models import db
from models.pc_master import PCMaster

logger = logging.getLogger(__name__)


@views_bp.route('/csv-import', methods=['GET'])
def csv_import():
    """CSV import page.

    Returns:
        Rendered CSV import template
    """
    return render_template('csv_import.html')


@views_bp.route('/csv-import/process', methods=['POST'])
def csv_import_process():
    """Process CSV import.

    Returns:
        Redirect to PC list page
    """
    if 'csv_file' not in request.files:
        flash('CSVファイルが選択されていません', 'danger')
        return redirect(url_for('views.csv_import'))

    file = request.files['csv_file']
    if file.filename == '':
        flash('CSVファイルが選択されていません', 'danger')
        return redirect(url_for('views.csv_import'))

    if not file.filename.endswith('.csv'):
        flash('CSVファイルを選択してください', 'danger')
        return redirect(url_for('views.csv_import'))

    try:
        # Read CSV file
        csv_content = file.read().decode('utf-8')
        csv_reader = csv.DictReader(csv_content.splitlines())

        imported_count = 0
        skipped_count = 0

        for row in csv_reader:
            serial = row.get('serial', '').strip()
            pcname = row.get('pcname', '').strip()
            odj_path = row.get('odj_path', '').strip()

            if not serial or not pcname:
                skipped_count += 1
                continue

            # Check for duplicates
            existing = PCMaster.query.filter_by(serial=serial).first()
            if existing:
                skipped_count += 1
                continue

            # Create new PC entry
            pc = PCMaster(
                serial=serial,
                pcname=pcname,
                odj_path=odj_path if odj_path else None
            )
            db.session.add(pc)
            imported_count += 1

        db.session.commit()

        flash(f'CSV一括登録完了: {imported_count}件登録, {skipped_count}件スキップ', 'success')
        return redirect(url_for('views.list_pcs'))

    except Exception as e:
        db.session.rollback()
        flash(f'CSV読み込みエラー: {str(e)}', 'danger')
        return redirect(url_for('views.csv_import'))


@views_bp.route('/import', methods=['GET', 'POST'])
def import_csv_legacy():
    """CSV import page (legacy route).

    GET: Display import form
    POST: Process CSV import (handled by API)
    """
    if request.method == 'POST':
        # This will be handled by JavaScript calling the API
        # Redirect to import page to show results
        return redirect(url_for('views.csv_import'))

    return render_template('import_export/import.html')


@views_bp.route('/export', methods=['GET'])
def export_page():
    """CSV export page.

    Displays current PC data and provides export functionality.
    """
    try:
        # Get all PCs
        pcs = PCMaster.query.order_by(PCMaster.created_at.desc()).all()

        return render_template(
            'import_export/export.html',
            pcs=pcs,
            total_count=len(pcs)
        )

    except Exception as e:
        logger.error(f'Error loading export page: {e}')
        flash('Failed to load export page', 'error')
        return redirect(url_for('views.index'))


@views_bp.route('/odj-upload', methods=['GET'])
def odj_upload():
    """ODJ file upload page.

    GET: Display upload form
    """
    try:
        # Get all PCs for association
        pcs = PCMaster.query.order_by(PCMaster.pcname).all()

        return render_template('odj_upload.html', pcs=pcs)

    except Exception as e:
        logger.error(f'Error loading ODJ upload page: {e}')
        flash('Failed to load ODJ upload page', 'error')
        return redirect(url_for('views.index'))


@views_bp.route('/odj-upload/process', methods=['POST'])
def odj_upload_process():
    """Process ODJ file upload.

    Returns:
        Redirect to PC list page
    """
    pc_id = request.form.get('pc_id')

    if not pc_id:
        flash('PCが選択されていません', 'danger')
        return redirect(url_for('views.odj_upload'))

    if 'odj_file' not in request.files:
        flash('ODJファイルが選択されていません', 'danger')
        return redirect(url_for('views.odj_upload'))

    file = request.files['odj_file']
    if file.filename == '':
        flash('ODJファイルが選択されていません', 'danger')
        return redirect(url_for('views.odj_upload'))

    # Validate file extension
    allowed_extensions = ['.txt', '.blob']
    file_ext = os.path.splitext(file.filename)[1].lower()
    if file_ext not in allowed_extensions:
        flash('ODJファイル（.txt または .blob）を選択してください', 'danger')
        return redirect(url_for('views.odj_upload'))

    try:
        # Get PC
        pc = PCMaster.query.get(pc_id)
        if not pc:
            flash('指定されたPCが見つかりません', 'danger')
            return redirect(url_for('views.odj_upload'))

        # Save ODJ file
        upload_folder = '/srv/odj'
        os.makedirs(upload_folder, exist_ok=True)

        filename = secure_filename(f"{pc.pcname}{file_ext}")
        file_path = os.path.join(upload_folder, filename)
        file.save(file_path)

        # Update PC record
        pc.odj_path = file_path
        db.session.commit()

        flash(f'ODJファイルを {pc.pcname} に紐付けました', 'success')
        return redirect(url_for('views.list_pcs'))

    except Exception as e:
        db.session.rollback()
        logger.error(f'ODJ upload error: {e}')
        flash(f'ODJアップロードエラー: {str(e)}', 'danger')
        return redirect(url_for('views.odj_upload'))


@views_bp.route('/odj-list', methods=['GET'])
def odj_list():
    """ODJ files list page.

    Displays all uploaded ODJ files and their associations.
    """
    return render_template('import_export/odj_list.html')
