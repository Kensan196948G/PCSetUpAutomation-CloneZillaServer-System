"""Main views."""
from flask import render_template
from . import views_bp
from models import PCMaster, SetupLog


@views_bp.route('/')
def index():
    """Dashboard page.

    Returns:
        Rendered dashboard template
    """
    # Get statistics
    total_pcs = PCMaster.query.count()
    completed_logs = SetupLog.query.filter_by(status='completed').count()
    in_progress_logs = SetupLog.query.filter_by(status='in_progress').count()
    failed_logs = SetupLog.query.filter_by(status='failed').count()

    # Get latest logs
    latest_logs = SetupLog.query.order_by(
        SetupLog.timestamp.desc()
    ).limit(5).all()

    # Get recent PCs
    recent_pcs = PCMaster.query.order_by(
        PCMaster.created_at.desc()
    ).limit(5).all()

    return render_template(
        'index.html',
        total_pcs=total_pcs,
        completed_logs=completed_logs,
        in_progress_logs=in_progress_logs,
        failed_logs=failed_logs,
        latest_logs=latest_logs,
        recent_pcs=recent_pcs
    )


@views_bp.route('/health')
def health_check():
    """Health check endpoint.

    Returns:
        JSON response indicating service status
    """
    return {
        'status': 'healthy',
        'service': 'PC Setup Automation',
        'version': '1.0.0'
    }
