"""PC Management views."""
from flask import render_template, request, redirect, url_for, flash
from . import views_bp
from models import db, PCMaster, SetupLog


@views_bp.route('/pcs')
def list_pcs():
    """List all PCs.

    Returns:
        Rendered PC list template
    """
    page = request.args.get('page', 1, type=int)
    per_page = 20

    pagination = PCMaster.query.order_by(
        PCMaster.created_at.desc()
    ).paginate(page=page, per_page=per_page, error_out=False)

    pcs = pagination.items

    return render_template(
        'pcs.html',
        pcs=pcs,
        pagination=pagination
    )


@views_bp.route('/pcs/add', methods=['GET', 'POST'])
def add_pc():
    """Add new PC.

    Returns:
        Rendered add PC form or redirect after submission
    """
    if request.method == 'POST':
        serial = request.form.get('serial')
        pcname = request.form.get('pcname')
        odj_path = request.form.get('odj_path')

        # Validation
        if not serial or not pcname:
            flash('Serial番号とPC名は必須です', 'danger')
            return render_template('add_pc.html')

        # Check for duplicate
        existing = PCMaster.find_by_serial(serial)
        if existing:
            flash(f'Serial番号 {serial} は既に登録されています', 'warning')
            return render_template('add_pc.html')

        # Create new PC
        try:
            pc = PCMaster(
                serial=serial,
                pcname=pcname,
                odj_path=odj_path
            )
            db.session.add(pc)
            db.session.commit()

            flash(f'PC {pcname} ({serial}) を登録しました', 'success')
            return redirect(url_for('views.list_pcs'))
        except Exception as e:
            db.session.rollback()
            flash(f'エラーが発生しました: {str(e)}', 'danger')
            return render_template('add_pc.html')

    return render_template('add_pc.html')


@views_bp.route('/pcs/edit/<int:pc_id>', methods=['GET', 'POST'])
def edit_pc(pc_id):
    """Edit PC details.

    Args:
        pc_id: PC ID

    Returns:
        Rendered edit PC form or redirect after submission
    """
    pc = PCMaster.query.get_or_404(pc_id)

    if request.method == 'POST':
        pcname = request.form.get('pcname')
        odj_path = request.form.get('odj_path')

        # Validation
        if not pcname:
            flash('PC名は必須です', 'danger')
            return render_template('edit_pc.html', pc=pc)

        try:
            pc.pcname = pcname
            pc.odj_path = odj_path if odj_path else None
            db.session.commit()

            flash(f'PC {pcname} の情報を更新しました', 'success')
            return redirect(url_for('views.list_pcs'))
        except Exception as e:
            db.session.rollback()
            flash(f'エラーが発生しました: {str(e)}', 'danger')
            return render_template('edit_pc.html', pc=pc)

    return render_template('edit_pc.html', pc=pc)


@views_bp.route('/logs')
def list_logs():
    """List setup logs.

    Returns:
        Rendered logs list template
    """
    page = request.args.get('page', 1, type=int)
    per_page = 50
    status_filter = request.args.get('status')

    query = SetupLog.query

    # Filter by status if specified
    if status_filter:
        query = query.filter_by(status=status_filter)

    pagination = query.order_by(
        SetupLog.timestamp.desc()
    ).paginate(page=page, per_page=per_page, error_out=False)

    logs = pagination.items

    return render_template(
        'logs.html',
        logs=logs,
        pagination=pagination,
        status_filter=status_filter
    )
