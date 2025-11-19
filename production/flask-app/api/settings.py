"""Settings API endpoints."""
from flask import request, jsonify, current_app
from pathlib import Path
import os
import shutil
from . import api_bp


@api_bp.route('/settings', methods=['GET'])
def get_settings():
    """Get current settings.

    Returns:
        JSON: Current application settings
    """
    return jsonify({
        'clonezilla_image_path': current_app.config['CLONEZILLA_IMAGE_PATH'],
        'odj_files_path': current_app.config['ODJ_FILES_PATH'],
        'api_port': current_app.config['API_PORT'],
        'api_host': current_app.config['API_HOST']
    })


@api_bp.route('/settings/image-path', methods=['POST'])
def update_image_path():
    """Update Clonezilla image path.

    Request JSON:
        {
            "path": "/path/to/images"
        }

    Returns:
        JSON: Success/error response
    """
    try:
        data = request.get_json()
        new_path = data.get('path')

        # Validation
        if not new_path:
            return jsonify({'error': 'パスが指定されていません'}), 400

        # Remove trailing slash if present
        new_path = new_path.rstrip('/')

        # Path existence check
        path_obj = Path(new_path)
        if not path_obj.exists():
            return jsonify({'error': f'パスが存在しません: {new_path}'}), 400

        # Directory check
        if not path_obj.is_dir():
            return jsonify({'error': f'ディレクトリではありません: {new_path}'}), 400

        # Write permission check
        if not os.access(new_path, os.W_OK):
            return jsonify({'error': f'書き込み権限がありません: {new_path}'}), 403

        # Read permission check
        if not os.access(new_path, os.R_OK):
            return jsonify({'error': f'読み取り権限がありません: {new_path}'}), 403

        # Update configuration
        current_app.config['CLONEZILLA_IMAGE_PATH'] = new_path

        # Update .env file for persistence
        update_env_file('CLONEZILLA_IMAGE_PATH', new_path)

        current_app.logger.info(f'Clonezilla image path updated to: {new_path}')

        return jsonify({
            'success': True,
            'message': 'イメージパスを更新しました',
            'new_path': new_path
        })

    except Exception as e:
        current_app.logger.error(f'Error updating image path: {str(e)}')
        return jsonify({'error': f'エラーが発生しました: {str(e)}'}), 500


@api_bp.route('/settings/image-path/validate', methods=['POST'])
def validate_image_path():
    """Validate Clonezilla image path.

    Request JSON:
        {
            "path": "/path/to/validate"
        }

    Returns:
        JSON: Validation result with path information
    """
    try:
        data = request.get_json()
        path = data.get('path')

        if not path:
            return jsonify({'valid': False, 'error': 'パスが指定されていません'})

        # Remove trailing slash
        path = path.rstrip('/')
        path_obj = Path(path)

        # Existence check
        if not path_obj.exists():
            return jsonify({'valid': False, 'error': 'パスが存在しません'})

        # Directory check
        if not path_obj.is_dir():
            return jsonify({'valid': False, 'error': 'ディレクトリではありません'})

        # Read permission check
        if not os.access(path, os.R_OK):
            return jsonify({'valid': False, 'error': '読み取り権限がありません'})

        # Write permission check
        writable = os.access(path, os.W_OK)
        if not writable:
            return jsonify({'valid': False, 'error': '書き込み権限がありません'})

        # Count image directories (Clonezilla images are directories)
        image_count = 0
        try:
            for item in path_obj.iterdir():
                if item.is_dir():
                    image_count += 1
        except PermissionError:
            return jsonify({'valid': False, 'error': 'ディレクトリの内容を読み取れません'})

        # Get disk free space
        disk_free = get_disk_free(path)

        return jsonify({
            'valid': True,
            'path': path,
            'writable': writable,
            'image_count': image_count,
            'disk_free': disk_free
        })

    except Exception as e:
        current_app.logger.error(f'Error validating path: {str(e)}')
        return jsonify({'valid': False, 'error': f'検証エラー: {str(e)}'})


def get_disk_free(path):
    """Get disk free space for a given path.

    Args:
        path: Directory path

    Returns:
        str: Formatted free space (e.g., "123.45 GB")
    """
    try:
        stat = shutil.disk_usage(path)
        free_gb = stat.free / (1024 ** 3)
        total_gb = stat.total / (1024 ** 3)
        used_gb = stat.used / (1024 ** 3)
        percent_used = (stat.used / stat.total) * 100

        return {
            'free': f"{free_gb:.2f} GB",
            'total': f"{total_gb:.2f} GB",
            'used': f"{used_gb:.2f} GB",
            'percent_used': f"{percent_used:.1f}%"
        }
    except Exception as e:
        current_app.logger.error(f'Error getting disk space: {str(e)}')
        return {
            'free': '不明',
            'total': '不明',
            'used': '不明',
            'percent_used': '不明'
        }


def update_env_file(key, value):
    """Update .env file with new value.

    Args:
        key: Environment variable key
        value: New value
    """
    try:
        env_path = Path(__file__).resolve().parent.parent / '.env'

        # Create .env if not exists
        if not env_path.exists():
            with open(env_path, 'w') as f:
                f.write(f'{key}={value}\n')
            return

        # Read existing content
        with open(env_path, 'r') as f:
            lines = f.readlines()

        # Update or add the key
        found = False
        for i, line in enumerate(lines):
            if line.startswith(f'{key}='):
                lines[i] = f'{key}={value}\n'
                found = True
                break

        if not found:
            lines.append(f'{key}={value}\n')

        # Write back
        with open(env_path, 'w') as f:
            f.writelines(lines)

        current_app.logger.info(f'Updated .env file: {key}={value}')

    except Exception as e:
        current_app.logger.error(f'Error updating .env file: {str(e)}')
        raise
