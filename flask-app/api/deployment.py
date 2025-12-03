"""Deployment Management API endpoints."""
import logging
from datetime import datetime
from flask import request, jsonify
from . import api_bp
from models import db
from models.deployment import Deployment
from models.pc_master import PCMaster
from utils.drbl_client import DRBLClient, DRBLException

logger = logging.getLogger(__name__)

# Initialize DRBL client
drbl_client = DRBLClient()


@api_bp.route('/deployment', methods=['POST'])
def create_deployment():
    """Create a new deployment configuration.

    Request JSON:
        - name: Deployment name
        - image_name: Clonezilla image name
        - mode: Deployment mode (multicast/unicast)
        - target_serials: List of target PC serials (optional)
        - created_by: User who created the deployment (optional)
        - notes: Additional notes (optional)

    Returns:
        JSON response with deployment configuration
    """
    try:
        data = request.get_json()

        if not data:
            return jsonify({
                'error': 'No data provided'
            }), 400

        # Validate required fields
        name = data.get('name', '').strip()
        image_name = data.get('image_name', '').strip()
        mode = data.get('mode', 'multicast').strip().lower()

        if not name:
            return jsonify({
                'error': 'Deployment name is required',
                'field': 'name'
            }), 400

        if not image_name:
            return jsonify({
                'error': 'Image name is required',
                'field': 'image_name'
            }), 400

        # Validate mode
        if mode not in ['multicast', 'unicast']:
            return jsonify({
                'error': 'Invalid deployment mode. Must be "multicast" or "unicast"',
                'field': 'mode',
                'allowed_values': ['multicast', 'unicast']
            }), 400

        # Validate image exists using DRBL client
        image_info = drbl_client.get_image_info(image_name)

        if not image_info:
            return jsonify({
                'error': 'Image not found',
                'field': 'image_name',
                'image_name': image_name
            }), 404

        # Process target serials
        target_serials = data.get('target_serials', [])
        if isinstance(target_serials, list):
            target_serials_str = ','.join(target_serials)
            target_count = len(target_serials)
        else:
            target_serials_str = ''
            target_count = 0

        # Validate target PCs exist
        if target_serials:
            invalid_serials = []
            for serial in target_serials:
                pc = PCMaster.find_by_serial(serial)
                if not pc:
                    invalid_serials.append(serial)

            if invalid_serials:
                return jsonify({
                    'error': 'Some target PCs not found',
                    'invalid_serials': invalid_serials
                }), 404

        # Create deployment
        deployment = Deployment(
            name=name,
            image_name=image_name,
            mode=mode,
            target_serials=target_serials_str,
            target_count=target_count,
            status='pending',
            created_by=data.get('created_by', ''),
            notes=data.get('notes', '')
        )

        db.session.add(deployment)
        db.session.commit()

        logger.info(f'Deployment created: {name} (ID: {deployment.id})')

        return jsonify({
            'success': True,
            'message': 'Deployment created successfully',
            'deployment': deployment.to_dict()
        }), 201

    except Exception as e:
        db.session.rollback()
        logger.error(f'Error creating deployment: {e}')
        return jsonify({
            'error': 'Failed to create deployment',
            'details': str(e)
        }), 500


@api_bp.route('/deployment', methods=['GET'])
def list_deployments():
    """List all deployments.

    Query parameters:
        - status: Filter by status (optional)
        - limit: Number of records to return (default: 50)

    Returns:
        JSON response with list of deployments
    """
    try:
        # Get query parameters
        status = request.args.get('status', '').strip()
        limit = int(request.args.get('limit', 50))

        # Build query
        query = Deployment.query

        if status:
            query = query.filter_by(status=status)

        # Get deployments
        deployments = query.order_by(
            Deployment.created_at.desc()
        ).limit(limit).all()

        return jsonify({
            'success': True,
            'count': len(deployments),
            'deployments': [d.to_dict() for d in deployments]
        }), 200

    except Exception as e:
        logger.error(f'Error listing deployments: {e}')
        return jsonify({
            'error': 'Failed to list deployments',
            'details': str(e)
        }), 500


@api_bp.route('/deployment/active', methods=['GET'])
def get_active_deployments():
    """Get all active deployments.

    Returns:
        JSON response with active deployments
    """
    try:
        deployments = Deployment.get_active_deployments()

        return jsonify({
            'success': True,
            'count': len(deployments),
            'deployments': [d.to_dict() for d in deployments]
        }), 200

    except Exception as e:
        logger.error(f'Error getting active deployments: {e}')
        return jsonify({
            'error': 'Failed to get active deployments',
            'details': str(e)
        }), 500


@api_bp.route('/deployment/<int:deployment_id>', methods=['GET'])
def get_deployment(deployment_id):
    """Get deployment details.

    Args:
        deployment_id: Deployment ID

    Returns:
        JSON response with deployment details
    """
    try:
        deployment = Deployment.query.get(deployment_id)

        if not deployment:
            return jsonify({
                'error': 'Deployment not found',
                'deployment_id': deployment_id
            }), 404

        # Get target PC details
        target_pcs = []
        if deployment.target_serials:
            serials = deployment.target_serials.split(',')
            for serial in serials:
                pc = PCMaster.find_by_serial(serial)
                if pc:
                    target_pcs.append(pc.to_dict())

        deployment_dict = deployment.to_dict()
        deployment_dict['target_pcs'] = target_pcs

        return jsonify({
            'success': True,
            'deployment': deployment_dict
        }), 200

    except Exception as e:
        logger.error(f'Error getting deployment: {e}')
        return jsonify({
            'error': 'Failed to get deployment',
            'details': str(e)
        }), 500


@api_bp.route('/deployment/<int:deployment_id>/status', methods=['GET'])
def get_deployment_status(deployment_id):
    """Get real-time deployment status.

    Args:
        deployment_id: Deployment ID

    Returns:
        JSON response with deployment status
    """
    try:
        deployment = Deployment.query.get(deployment_id)

        if not deployment:
            return jsonify({
                'error': 'Deployment not found',
                'deployment_id': deployment_id
            }), 404

        # Get real-time status from DRBL/Clonezilla
        drbl_status = drbl_client.get_deployment_status()

        status_info = {
            'deployment_id': deployment.id,
            'status': deployment.status,
            'progress': deployment.progress,
            'started_at': deployment.started_at.isoformat() if deployment.started_at else None,
            'elapsed_seconds': None,
            'drbl_running': drbl_status.get('running', False),
            'drbl_progress': drbl_status.get('progress', {})
        }

        if deployment.started_at:
            elapsed = datetime.utcnow() - deployment.started_at
            status_info['elapsed_seconds'] = int(elapsed.total_seconds())

        if deployment.completed_at:
            duration = deployment.completed_at - deployment.started_at
            status_info['duration_seconds'] = int(duration.total_seconds())

        # Update progress from DRBL if available
        if drbl_status.get('running') and 'progress' in drbl_status:
            progress_data = drbl_status['progress']
            if 'percentage' in progress_data:
                deployment.progress = progress_data['percentage']
                db.session.commit()

        return jsonify({
            'success': True,
            'status': status_info
        }), 200

    except Exception as e:
        logger.error(f'Error getting deployment status: {e}')
        return jsonify({
            'error': 'Failed to get deployment status',
            'details': str(e)
        }), 500


@api_bp.route('/deployment/<int:deployment_id>/start', methods=['POST'])
def start_deployment(deployment_id):
    """Start a deployment.

    Args:
        deployment_id: Deployment ID

    Returns:
        JSON response with start result
    """
    try:
        deployment = Deployment.query.get(deployment_id)

        if not deployment:
            return jsonify({
                'error': 'Deployment not found',
                'deployment_id': deployment_id
            }), 404

        if deployment.status not in ['pending']:
            return jsonify({
                'error': 'Deployment cannot be started',
                'current_status': deployment.status,
                'allowed_status': ['pending']
            }), 400

        # Update status
        deployment.status = 'running'
        deployment.started_at = datetime.utcnow()
        deployment.progress = 0

        db.session.commit()

        logger.info(f'Starting deployment: {deployment.name} (ID: {deployment.id})')

        # Start actual DRBL deployment
        try:
            if deployment.mode == 'multicast':
                # Start multicast deployment
                result = drbl_client.start_multicast_deployment(
                    image_name=deployment.image_name,
                    clients_to_wait=deployment.target_count or 10,
                    max_wait_time=300
                )
            else:
                # Start unicast deployment
                # Get first target PC MAC address (would need to be stored in DB)
                if deployment.target_serials:
                    serials = deployment.target_serials.split(',')
                    first_pc = PCMaster.find_by_serial(serials[0])
                    # Note: MAC address would need to be stored in PCMaster model
                    target_mac = getattr(first_pc, 'mac_address', '00:00:00:00:00:00')
                else:
                    target_mac = '00:00:00:00:00:00'

                result = drbl_client.start_unicast_deployment(
                    image_name=deployment.image_name,
                    target_mac=target_mac
                )

            logger.info(f'DRBL deployment started: {result}')

            return jsonify({
                'success': True,
                'message': 'Deployment started successfully',
                'deployment': deployment.to_dict(),
                'drbl_result': result
            }), 200

        except DRBLException as e:
            # Rollback status on DRBL error
            deployment.status = 'failed'
            deployment.completed_at = datetime.utcnow()
            db.session.commit()

            logger.error(f'DRBL deployment failed: {str(e)}')

            return jsonify({
                'success': False,
                'error': 'Failed to start DRBL deployment',
                'details': str(e),
                'deployment': deployment.to_dict()
            }), 500

    except Exception as e:
        db.session.rollback()
        logger.error(f'Error starting deployment: {e}')
        return jsonify({
            'error': 'Failed to start deployment',
            'details': str(e)
        }), 500


@api_bp.route('/deployment/<int:deployment_id>/stop', methods=['POST'])
def stop_deployment(deployment_id):
    """Stop a running deployment.

    Args:
        deployment_id: Deployment ID

    Returns:
        JSON response with stop result
    """
    try:
        deployment = Deployment.query.get(deployment_id)

        if not deployment:
            return jsonify({
                'error': 'Deployment not found',
                'deployment_id': deployment_id
            }), 404

        if deployment.status not in ['running']:
            return jsonify({
                'error': 'Deployment is not running',
                'current_status': deployment.status
            }), 400

        # Stop actual DRBL deployment
        try:
            result = drbl_client.stop_deployment()

            # Update status
            deployment.status = 'failed'
            deployment.completed_at = datetime.utcnow()
            db.session.commit()

            logger.warning(f'Stopping deployment: {deployment.name} (ID: {deployment.id})')

            return jsonify({
                'success': True,
                'message': 'Deployment stopped',
                'deployment': deployment.to_dict(),
                'drbl_result': result
            }), 200

        except DRBLException as e:
            logger.error(f'Error stopping DRBL deployment: {str(e)}')

            # Update status anyway
            deployment.status = 'failed'
            deployment.completed_at = datetime.utcnow()
            db.session.commit()

            return jsonify({
                'success': False,
                'error': 'Failed to stop DRBL deployment cleanly',
                'details': str(e),
                'deployment': deployment.to_dict()
            }), 500

    except Exception as e:
        db.session.rollback()
        logger.error(f'Error stopping deployment: {e}')
        return jsonify({
            'error': 'Failed to stop deployment',
            'details': str(e)
        }), 500


@api_bp.route('/deployment/<int:deployment_id>', methods=['PUT'])
def update_deployment(deployment_id):
    """Update deployment configuration.

    Args:
        deployment_id: Deployment ID

    Request JSON:
        - name: Deployment name (optional)
        - notes: Notes (optional)
        - status: Status (optional)
        - progress: Progress 0-100 (optional)

    Returns:
        JSON response with update result
    """
    try:
        deployment = Deployment.query.get(deployment_id)

        if not deployment:
            return jsonify({
                'error': 'Deployment not found',
                'deployment_id': deployment_id
            }), 404

        data = request.get_json()

        if not data:
            return jsonify({
                'error': 'No data provided'
            }), 400

        # Update fields
        if 'name' in data:
            deployment.name = data['name'].strip()

        if 'notes' in data:
            deployment.notes = data['notes'].strip()

        if 'status' in data:
            deployment.status = data['status'].strip()

            if deployment.status == 'completed':
                deployment.completed_at = datetime.utcnow()
                deployment.progress = 100

        if 'progress' in data:
            deployment.progress = int(data['progress'])

        db.session.commit()

        logger.info(f'Deployment updated: {deployment.name} (ID: {deployment.id})')

        return jsonify({
            'success': True,
            'message': 'Deployment updated successfully',
            'deployment': deployment.to_dict()
        }), 200

    except Exception as e:
        db.session.rollback()
        logger.error(f'Error updating deployment: {e}')
        return jsonify({
            'error': 'Failed to update deployment',
            'details': str(e)
        }), 500


@api_bp.route('/deployment/<int:deployment_id>', methods=['DELETE'])
def delete_deployment(deployment_id):
    """Delete a deployment.

    Args:
        deployment_id: Deployment ID

    Returns:
        JSON response with deletion result
    """
    try:
        deployment = Deployment.query.get(deployment_id)

        if not deployment:
            return jsonify({
                'error': 'Deployment not found',
                'deployment_id': deployment_id
            }), 404

        # Only allow deletion of completed or failed deployments
        if deployment.status in ['running']:
            return jsonify({
                'error': 'Cannot delete running deployment',
                'current_status': deployment.status
            }), 400

        db.session.delete(deployment)
        db.session.commit()

        logger.info(f'Deployment deleted: {deployment.name} (ID: {deployment.id})')

        return jsonify({
            'success': True,
            'message': 'Deployment deleted successfully'
        }), 200

    except Exception as e:
        db.session.rollback()
        logger.error(f'Error deleting deployment: {e}')
        return jsonify({
            'error': 'Failed to delete deployment',
            'details': str(e)
        }), 500
