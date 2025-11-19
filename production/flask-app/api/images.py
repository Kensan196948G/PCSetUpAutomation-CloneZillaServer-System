"""Clonezilla Master Image Management API endpoints."""
import os
import logging
import shutil
from pathlib import Path
from datetime import datetime
from flask import request, jsonify, current_app
from . import api_bp
from utils.drbl_client import DRBLClient

logger = logging.getLogger(__name__)

# Initialize DRBL client
drbl_client = DRBLClient()


def parse_clonezilla_info(image_path):
    """Parse Clonezilla image information.

    Args:
        image_path: Path to Clonezilla image directory

    Returns:
        dict: Image information
    """
    info = {}

    # Read parts file to get disk info
    parts_file = image_path / 'parts'
    if parts_file.exists():
        with open(parts_file, 'r') as f:
            info['partitions'] = f.read().strip().split()

    # Read dev-fs.list to get filesystem info
    dev_fs_file = image_path / 'dev-fs.list'
    if dev_fs_file.exists():
        with open(dev_fs_file, 'r') as f:
            info['filesystems'] = f.read().strip()

    # Read disk file to get disk name
    disk_file = image_path / 'disk'
    if disk_file.exists():
        with open(disk_file, 'r') as f:
            info['disk'] = f.read().strip()

    # Read clonezilla-img file for image metadata
    img_file = image_path / 'clonezilla-img'
    if img_file.exists():
        with open(img_file, 'r') as f:
            info['metadata'] = f.read().strip()

    return info


@api_bp.route('/images', methods=['GET'])
def list_images():
    """List all Clonezilla master images.

    Returns:
        JSON response with list of images
    """
    try:
        # Use DRBL client to list images
        images = drbl_client.list_images()

        # Parse additional Clonezilla info for each image
        for image in images:
            try:
                image_path = Path(image['path'])
                clonezilla_info = parse_clonezilla_info(image_path)

                # Add Clonezilla-specific info
                image['partitions'] = clonezilla_info.get('partitions', [])
                image['disk'] = clonezilla_info.get('disk', '')
                image['has_metadata'] = 'metadata' in clonezilla_info

            except Exception as e:
                logger.warning(f"Error reading Clonezilla info for {image['name']}: {e}")
                continue

        return jsonify({
            'success': True,
            'count': len(images),
            'images': images
        }), 200

    except Exception as e:
        logger.error(f'Error listing images: {e}')
        return jsonify({
            'error': 'Failed to list images',
            'details': str(e)
        }), 500


@api_bp.route('/images/<image_name>', methods=['GET'])
def get_image_details(image_name):
    """Get detailed information about a specific image.

    Args:
        image_name: Name of the image directory

    Returns:
        JSON response with image details
    """
    try:
        # Use DRBL client to get image info
        image_info = drbl_client.get_image_info(image_name)

        if not image_info:
            return jsonify({
                'error': 'Image not found',
                'image_name': image_name
            }), 404

        # Get additional Clonezilla info
        image_path = Path(image_info['path'])
        clonezilla_info = parse_clonezilla_info(image_path)

        # List all files in image directory
        files = []
        for file_path in image_path.iterdir():
            if file_path.is_file():
                file_stat = file_path.stat()
                files.append({
                    'name': file_path.name,
                    'size': file_stat.st_size,
                    'size_mb': round(file_stat.st_size / 1024 / 1024, 2),
                    'modified_at': datetime.fromtimestamp(file_stat.st_mtime).strftime('%Y-%m-%d %H:%M:%S')
                })

        # Sort files by name
        files.sort(key=lambda x: x['name'])

        # Merge info
        image_details = {
            **image_info,
            'partitions': clonezilla_info.get('partitions', []),
            'disk': clonezilla_info.get('disk', ''),
            'filesystems': clonezilla_info.get('filesystems', ''),
            'metadata': clonezilla_info.get('metadata', ''),
            'files': files,
            'file_count': len(files)
        }

        return jsonify({
            'success': True,
            'image': image_details
        }), 200

    except Exception as e:
        logger.error(f'Error getting image details: {e}')
        return jsonify({
            'error': 'Failed to get image details',
            'details': str(e)
        }), 500


@api_bp.route('/images', methods=['POST'])
def register_image():
    """Register a new master image.

    This endpoint is used to register metadata about an image
    that was created externally (e.g., via Clonezilla CLI).

    Request JSON:
        - name: Image name
        - description: Image description (optional)
        - created_by: Creator name (optional)

    Returns:
        JSON response with registration result
    """
    try:
        data = request.get_json()

        if not data:
            return jsonify({
                'error': 'No data provided'
            }), 400

        image_name = data.get('name', '').strip()
        description = data.get('description', '').strip()
        created_by = data.get('created_by', '').strip()

        if not image_name:
            return jsonify({
                'error': 'Image name is required',
                'field': 'name'
            }), 400

        # Check if image exists using DRBL client
        image_info = drbl_client.get_image_info(image_name)

        if not image_info:
            return jsonify({
                'error': 'Image directory not found',
                'image_name': image_name
            }), 404

        image_path = Path(image_info['path'])

        # Create metadata file (custom)
        metadata = {
            'name': image_name,
            'description': description,
            'created_by': created_by,
            'registered_at': datetime.now().isoformat(),
            'size': image_info['size_bytes'],
            'partitions': image_info.get('partitions', []),
            'disk': image_info.get('disk', '')
        }

        # Save metadata to file
        metadata_file = image_path / 'image_metadata.txt'
        with open(metadata_file, 'w') as f:
            for key, value in metadata.items():
                f.write(f'{key}: {value}\n')

        logger.info(f'Image registered: {image_name}')

        return jsonify({
            'success': True,
            'message': 'Image registered successfully',
            'image': {
                'name': image_name,
                'path': str(image_path),
                'size_human': image_info['size_human'],
                'metadata': metadata
            }
        }), 201

    except Exception as e:
        logger.error(f'Error registering image: {e}')
        return jsonify({
            'error': 'Failed to register image',
            'details': str(e)
        }), 500


@api_bp.route('/images/upload', methods=['POST'])
def upload_image():
    """Upload a Clonezilla image archive (tar.gz or zip).

    This endpoint accepts a compressed Clonezilla image archive,
    extracts it to the image directory, and registers it.

    Form data:
        - file: Compressed image file (tar.gz, zip)
        - image_name: Target image name (optional, uses filename if not provided)
        - description: Image description (optional)

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

        if file.filename == '':
            return jsonify({
                'error': 'No file selected',
                'field': 'file'
            }), 400

        # Get image name from form or filename
        image_name = request.form.get('image_name', '').strip()
        if not image_name:
            # Use filename without extension
            image_name = Path(file.filename).stem

        description = request.form.get('description', '').strip()

        # Validate image name (no special characters)
        import re
        if not re.match(r'^[a-zA-Z0-9_-]+$', image_name):
            return jsonify({
                'error': 'Invalid image name. Use only alphanumeric, underscore, and hyphen.',
                'field': 'image_name'
            }), 400

        # Check if image already exists
        existing_image = drbl_client.get_image_info(image_name)
        if existing_image:
            return jsonify({
                'error': 'Image already exists',
                'image_name': image_name
            }), 409

        # Create temporary directory for extraction
        import tempfile
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            archive_path = temp_path / file.filename

            # Save uploaded file
            file.save(str(archive_path))

            logger.info(f"Uploaded file: {archive_path} ({archive_path.stat().st_size} bytes)")

            # Extract archive
            extract_path = temp_path / 'extracted'
            extract_path.mkdir()

            if file.filename.endswith('.tar.gz') or file.filename.endswith('.tgz'):
                import tarfile
                with tarfile.open(archive_path, 'r:gz') as tar:
                    tar.extractall(extract_path)
            elif file.filename.endswith('.zip'):
                import zipfile
                with zipfile.ZipFile(archive_path, 'r') as zip_ref:
                    zip_ref.extractall(extract_path)
            else:
                return jsonify({
                    'error': 'Unsupported file format. Use .tar.gz or .zip',
                    'field': 'file'
                }), 400

            # Find the image directory in extracted files
            # Clonezilla images typically have a single directory
            extracted_dirs = [d for d in extract_path.iterdir() if d.is_dir()]

            if len(extracted_dirs) == 0:
                return jsonify({
                    'error': 'No directory found in archive',
                }), 400

            # Use first directory or the one named same as archive
            source_dir = extracted_dirs[0]
            if len(extracted_dirs) > 1:
                # Try to find directory matching the image name
                for d in extracted_dirs:
                    if d.name == image_name:
                        source_dir = d
                        break

            # Validate it's a Clonezilla image (has required files)
            if not (source_dir / 'disk').exists() and not (source_dir / 'parts').exists():
                return jsonify({
                    'error': 'Invalid Clonezilla image: missing disk or parts file',
                }), 400

            # Move to image directory
            target_path = Path(drbl_client.image_home) / image_name

            if target_path.exists():
                return jsonify({
                    'error': 'Target directory already exists',
                    'path': str(target_path)
                }), 409

            shutil.move(str(source_dir), str(target_path))

            logger.info(f"Image extracted to: {target_path}")

        # Register image metadata
        if description:
            metadata_file = target_path / 'image_metadata.txt'
            with open(metadata_file, 'w') as f:
                f.write(f"description: {description}\n")
                f.write(f"uploaded_at: {datetime.now().isoformat()}\n")

        # Get image info
        image_info = drbl_client.get_image_info(image_name)

        logger.info(f"Image uploaded successfully: {image_name}")

        return jsonify({
            'success': True,
            'message': 'Image uploaded successfully',
            'image': {
                'name': image_name,
                'path': str(target_path),
                'size_human': image_info['size_human'] if image_info else 'Unknown',
                'description': description
            }
        }), 201

    except Exception as e:
        logger.error(f'Error uploading image: {e}')
        return jsonify({
            'error': 'Failed to upload image',
            'details': str(e)
        }), 500


@api_bp.route('/images/<image_name>', methods=['DELETE'])
def delete_image(image_name):
    """Delete a master image.

    WARNING: This will permanently delete the image directory and all its contents.

    Args:
        image_name: Name of the image directory

    Returns:
        JSON response with deletion result
    """
    try:
        # Get image info using DRBL client
        image_info = drbl_client.get_image_info(image_name)

        if not image_info:
            return jsonify({
                'error': 'Image not found',
                'image_name': image_name
            }), 404

        image_path = Path(image_info['path'])
        size_bytes = image_info['size_bytes']

        # Delete directory and all contents
        shutil.rmtree(image_path)

        logger.warning(f"Image deleted: {image_name} ({image_info['size_human']})")

        return jsonify({
            'success': True,
            'message': 'Image deleted successfully',
            'image_name': image_name,
            'size_freed': image_info['size_human']
        }), 200

    except Exception as e:
        logger.error(f'Error deleting image: {e}')
        return jsonify({
            'error': 'Failed to delete image',
            'details': str(e)
        }), 500
