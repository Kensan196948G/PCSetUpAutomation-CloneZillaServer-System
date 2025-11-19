"""Deployment views."""
import logging
from flask import render_template, request, redirect, url_for, flash
from . import views_bp
from models import db
from models.deployment import Deployment
from models.pc_master import PCMaster

logger = logging.getLogger(__name__)


@views_bp.route('/deployment', methods=['GET', 'POST'])
def deployment():
    """Deployment configuration page.

    GET: Display deployment configuration form
    POST: Create deployment (handled by API)
    """
    if request.method == 'POST':
        # This will be handled by JavaScript calling the API
        return redirect(url_for('views.deployment_list'))

    try:
        # Get all PCs for selection
        pcs = PCMaster.query.order_by(PCMaster.pcname).all()

        return render_template(
            'deployment/create.html',
            pcs=pcs
        )

    except Exception as e:
        logger.error(f'Error loading deployment page: {e}')
        flash('Failed to load deployment page', 'error')
        return redirect(url_for('views.index'))


@views_bp.route('/deployment-list', methods=['GET'])
def deployment_list():
    """Deployment list page.

    Displays all deployments with their status.
    """
    try:
        # Get filter from query parameters
        status_filter = request.args.get('status', '')

        # Build query
        query = Deployment.query

        if status_filter:
            query = query.filter_by(status=status_filter)

        # Get deployments
        deployments = query.order_by(
            Deployment.created_at.desc()
        ).limit(100).all()

        # Get counts by status
        status_counts = {
            'pending': Deployment.query.filter_by(status='pending').count(),
            'running': Deployment.query.filter_by(status='running').count(),
            'completed': Deployment.query.filter_by(status='completed').count(),
            'failed': Deployment.query.filter_by(status='failed').count()
        }

        return render_template(
            'deployment/list.html',
            deployments=deployments,
            status_counts=status_counts,
            current_filter=status_filter
        )

    except Exception as e:
        logger.error(f'Error loading deployment list: {e}')
        flash('Failed to load deployment list', 'error')
        return redirect(url_for('views.index'))


@views_bp.route('/deployment/<int:deployment_id>', methods=['GET'])
def deployment_detail(deployment_id):
    """Deployment detail page.

    Args:
        deployment_id: Deployment ID

    Displays detailed information about a specific deployment.
    """
    try:
        deployment = Deployment.query.get(deployment_id)

        if not deployment:
            flash('Deployment not found', 'error')
            return redirect(url_for('views.deployment_list'))

        # Get target PCs
        target_pcs = []
        if deployment.target_serials:
            serials = deployment.target_serials.split(',')
            for serial in serials:
                pc = PCMaster.find_by_serial(serial)
                if pc:
                    target_pcs.append(pc)

        return render_template(
            'deployment/detail.html',
            deployment=deployment,
            target_pcs=target_pcs
        )

    except Exception as e:
        logger.error(f'Error loading deployment detail: {e}')
        flash('Failed to load deployment detail', 'error')
        return redirect(url_for('views.deployment_list'))


@views_bp.route('/deployment-status', methods=['GET'])
@views_bp.route('/deploy-status', methods=['GET'])
@views_bp.route('/deployment/status', methods=['GET'])
def deploy_status():
    """Deployment status dashboard page.

    Displays real-time status of all active deployments.
    """
    try:
        # Mock data for demonstration
        from models.setup_log import SetupLog

        # Get all logs grouped by PC
        logs = SetupLog.query.order_by(SetupLog.timestamp.desc()).all()

        # Create deployment items from logs
        deploy_items = []
        seen_serials = set()

        for log in logs:
            if log.serial not in seen_serials:
                seen_serials.add(log.serial)

                # Calculate progress based on status
                progress = 0
                if log.status == 'completed':
                    progress = 100
                elif log.status == 'in_progress':
                    progress = 50
                elif log.status == 'failed':
                    progress = 25

                deploy_items.append({
                    'pcname': log.pcname,
                    'serial': log.serial,
                    'status': log.status,
                    'progress': progress,
                    'timestamp': log.timestamp
                })

        # Calculate counts
        total_deploys = len(deploy_items)
        completed_count = sum(1 for item in deploy_items if item['status'] == 'completed')
        in_progress_count = sum(1 for item in deploy_items if item['status'] == 'in_progress')
        failed_count = sum(1 for item in deploy_items if item['status'] == 'failed')
        overall_progress = int((completed_count / total_deploys * 100)) if total_deploys > 0 else 0

        return render_template(
            'deployment/status.html',
            deploy_items=deploy_items,
            total_deploys=total_deploys,
            completed_count=completed_count,
            in_progress_count=in_progress_count,
            failed_count=failed_count,
            overall_progress=overall_progress
        )

    except Exception as e:
        logger.error(f'Error loading deployment status: {e}')
        flash('Failed to load deployment status', 'error')
        return redirect(url_for('views.index'))


@views_bp.route('/images', methods=['GET'])
@views_bp.route('/image-management', methods=['GET'])
@views_bp.route('/deployment/images', methods=['GET'])
def image_management():
    """Master images list page.

    Displays all Clonezilla master images.
    """
    # Mock data for demonstration
    images = [
        {
            'name': 'Windows 11 Pro Master 2025',
            'path': '/home/partimag/win11-master-2025',
            'description': 'Windows 11 Pro + Microsoft 365 Apps + セキュリティソフト',
            'size': '18.5 GB',
            'created_date': '2025-01-15',
            'is_active': True
        }
    ]

    return render_template('deployment/images.html', images=images)


@views_bp.route('/deploy-settings', methods=['GET'])
@views_bp.route('/deployment/settings', methods=['GET'])
def deploy_settings():
    """Deployment settings page.

    Displays Clonezilla and PXE boot configuration.
    """
    return render_template('deployment/settings.html')
