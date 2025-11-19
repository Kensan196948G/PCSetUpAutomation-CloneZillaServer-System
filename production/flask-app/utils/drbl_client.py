"""DRBL/Clonezilla client wrapper for automated PC deployment.

This module provides a Python interface to DRBL/Clonezilla server commands,
enabling automated image deployment, status monitoring, and configuration.
"""

import os
import subprocess
import logging
import json
import time
from typing import Dict, List, Optional, Tuple
from datetime import datetime
from pathlib import Path

logger = logging.getLogger(__name__)


class DRBLException(Exception):
    """Base exception for DRBL-related errors."""
    pass


class DRBLCommandError(DRBLException):
    """Exception raised when DRBL command execution fails."""
    pass


class DRBLConfigError(DRBLException):
    """Exception raised when DRBL configuration is invalid."""
    pass


class DRBLClient:
    """Client wrapper for DRBL/Clonezilla server operations.

    This class provides high-level methods to interact with DRBL server,
    including image management, deployment execution, and status monitoring.

    Attributes:
        drbl_installed (bool): Whether DRBL is installed on this system
        image_home (str): Path to Clonezilla image directory
        odj_home (str): Path to ODJ files directory
    """

    def __init__(
        self,
        image_home: str = "/home/partimag",
        odj_home: str = "/srv/odj",
        drbl_bin: str = "/opt/drbl/sbin"
    ):
        """Initialize DRBL client.

        Args:
            image_home: Directory containing Clonezilla images
            odj_home: Directory containing ODJ files
            drbl_bin: Directory containing DRBL binaries
        """
        self.image_home = Path(image_home)
        self.odj_home = Path(odj_home)
        self.drbl_bin = Path(drbl_bin)
        self.drbl_installed = self._check_drbl_installation()

        # Create directories if they don't exist and we have permissions
        try:
            self.image_home.mkdir(parents=True, exist_ok=True)
        except PermissionError:
            logger.warning(f"No permission to create image directory: {self.image_home}")

        try:
            self.odj_home.mkdir(parents=True, exist_ok=True)
        except PermissionError:
            logger.warning(f"No permission to create ODJ directory: {self.odj_home}")

        logger.info(f"DRBL Client initialized (installed: {self.drbl_installed})")

    def _check_drbl_installation(self) -> bool:
        """Check if DRBL is properly installed.

        Returns:
            True if DRBL commands are available, False otherwise
        """
        try:
            result = subprocess.run(
                ['which', 'dcs'],
                capture_output=True,
                text=True,
                timeout=5
            )
            return result.returncode == 0
        except (subprocess.TimeoutExpired, FileNotFoundError):
            logger.warning("DRBL not found on system")
            return False

    def _run_command(
        self,
        command: List[str],
        timeout: int = 300,
        check: bool = True
    ) -> Tuple[int, str, str]:
        """Execute a shell command and return results.

        Args:
            command: Command and arguments as list
            timeout: Maximum execution time in seconds
            check: Whether to raise exception on non-zero exit code

        Returns:
            Tuple of (return_code, stdout, stderr)

        Raises:
            DRBLCommandError: If command fails and check=True
        """
        logger.info(f"Executing command: {' '.join(command)}")

        try:
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=timeout,
                check=False
            )

            if check and result.returncode != 0:
                error_msg = f"Command failed: {' '.join(command)}\n{result.stderr}"
                logger.error(error_msg)
                raise DRBLCommandError(error_msg)

            return result.returncode, result.stdout, result.stderr

        except subprocess.TimeoutExpired as e:
            error_msg = f"Command timeout after {timeout}s: {' '.join(command)}"
            logger.error(error_msg)
            raise DRBLCommandError(error_msg) from e
        except Exception as e:
            error_msg = f"Command execution error: {str(e)}"
            logger.error(error_msg)
            raise DRBLCommandError(error_msg) from e

    # ============================================================
    # Image Management
    # ============================================================

    def list_images(self) -> List[Dict[str, any]]:
        """List all available Clonezilla images.

        Returns:
            List of image dictionaries with metadata

        Example:
            [
                {
                    'name': 'win11-master-20251116',
                    'path': '/home/partimag/win11-master-20251116',
                    'size_bytes': 15728640000,
                    'size_human': '14.6 GB',
                    'created': '2025-11-16 10:30:00',
                    'disk_count': 1
                }
            ]
        """
        images = []

        if not self.image_home.exists():
            logger.warning(f"Image directory not found: {self.image_home}")
            return images

        for image_dir in self.image_home.iterdir():
            if not image_dir.is_dir():
                continue

            # Check if directory contains Clonezilla image files
            if not (image_dir / 'disk').exists() and not (image_dir / 'parts').exists():
                continue

            # Calculate directory size
            size_bytes = sum(
                f.stat().st_size
                for f in image_dir.rglob('*')
                if f.is_file()
            )

            # Get creation time
            created_timestamp = image_dir.stat().st_ctime
            created = datetime.fromtimestamp(created_timestamp).strftime('%Y-%m-%d %H:%M:%S')

            # Count disk images
            disk_count = len(list(image_dir.glob('*-pt.sf')))

            images.append({
                'name': image_dir.name,
                'path': str(image_dir),
                'size_bytes': size_bytes,
                'size_human': self._format_bytes(size_bytes),
                'created': created,
                'disk_count': disk_count
            })

        return sorted(images, key=lambda x: x['name'], reverse=True)

    def get_image_info(self, image_name: str) -> Optional[Dict[str, any]]:
        """Get detailed information about a specific image.

        Args:
            image_name: Name of the Clonezilla image

        Returns:
            Image metadata dictionary or None if not found
        """
        images = self.list_images()
        for image in images:
            if image['name'] == image_name:
                return image
        return None

    # ============================================================
    # Deployment Operations
    # ============================================================

    def start_multicast_deployment(
        self,
        image_name: str,
        clients_to_wait: int = 10,
        max_wait_time: int = 300,
        compression: str = "zstd"
    ) -> Dict[str, any]:
        """Start a multicast deployment session.

        Args:
            image_name: Name of the Clonezilla image to deploy
            clients_to_wait: Number of clients to wait for before starting
            max_wait_time: Maximum time to wait for clients (seconds)
            compression: Compression algorithm (zstd, gzip, lz4)

        Returns:
            Deployment session information

        Raises:
            DRBLConfigError: If image doesn't exist
            DRBLCommandError: If deployment start fails
        """
        # Validate image exists
        image_info = self.get_image_info(image_name)
        if not image_info:
            raise DRBLConfigError(f"Image not found: {image_name}")

        if not self.drbl_installed:
            logger.warning("DRBL not installed, simulating deployment")
            return {
                'status': 'simulated',
                'image_name': image_name,
                'clients_to_wait': clients_to_wait,
                'start_time': datetime.now().isoformat(),
                'message': 'DRBL not installed, deployment simulated'
            }

        # Build dcs command
        command = [
            'dcs',
            '-b',  # Batch mode
            '-g', 'auto',  # Auto mode
            '-e1', 'auto',  # Auto partition
            '-e2',  # Skip language selection
            '-r',  # Auto reboot
            '-j2',  # Clone hidden data
            '-sc0',  # Skip confirmation
            '-p', 'choose',  # Restore partition
            '-k1',  # Create partition table
            '-icds',  # Skip checking destination
            '-t', str(clients_to_wait),  # Clients to wait
            image_name
        ]

        try:
            # Start deployment in background
            returncode, stdout, stderr = self._run_command(
                command,
                timeout=max_wait_time,
                check=True
            )

            logger.info(f"Multicast deployment started: {image_name}")

            return {
                'status': 'started',
                'image_name': image_name,
                'clients_to_wait': clients_to_wait,
                'start_time': datetime.now().isoformat(),
                'stdout': stdout,
                'stderr': stderr
            }

        except DRBLCommandError as e:
            logger.error(f"Failed to start deployment: {str(e)}")
            raise

    def start_unicast_deployment(
        self,
        image_name: str,
        target_mac: str
    ) -> Dict[str, any]:
        """Start a unicast deployment to a specific client.

        Args:
            image_name: Name of the Clonezilla image to deploy
            target_mac: MAC address of target client

        Returns:
            Deployment session information
        """
        # Validate image exists
        image_info = self.get_image_info(image_name)
        if not image_info:
            raise DRBLConfigError(f"Image not found: {image_name}")

        if not self.drbl_installed:
            logger.warning("DRBL not installed, simulating unicast deployment")
            return {
                'status': 'simulated',
                'image_name': image_name,
                'target_mac': target_mac,
                'start_time': datetime.now().isoformat(),
                'message': 'DRBL not installed, deployment simulated'
            }

        # For unicast, we use drbl-ocs with specific client
        command = [
            'drbl-ocs',
            '-b',
            '-g', 'auto',
            '-e1', 'auto',
            '-e2',
            '-r',
            '-j2',
            '-p', 'choose',
            '-k1',
            '-icds',
            '--clients', target_mac,
            image_name
        ]

        try:
            returncode, stdout, stderr = self._run_command(
                command,
                timeout=600,
                check=True
            )

            logger.info(f"Unicast deployment started: {image_name} -> {target_mac}")

            return {
                'status': 'started',
                'image_name': image_name,
                'target_mac': target_mac,
                'start_time': datetime.now().isoformat(),
                'stdout': stdout,
                'stderr': stderr
            }

        except DRBLCommandError as e:
            logger.error(f"Failed to start unicast deployment: {str(e)}")
            raise

    def stop_deployment(self) -> Dict[str, any]:
        """Stop the current deployment session.

        Returns:
            Stop operation result
        """
        if not self.drbl_installed:
            logger.warning("DRBL not installed, cannot stop deployment")
            return {
                'status': 'simulated',
                'message': 'DRBL not installed, stop simulated'
            }

        try:
            # Kill dcs processes
            self._run_command(['pkill', '-f', 'dcs'], check=False)
            self._run_command(['pkill', '-f', 'drbl-ocs'], check=False)

            logger.info("Deployment stopped")

            return {
                'status': 'stopped',
                'stop_time': datetime.now().isoformat()
            }

        except Exception as e:
            logger.error(f"Error stopping deployment: {str(e)}")
            raise DRBLCommandError(f"Failed to stop deployment: {str(e)}")

    def get_deployment_status(self) -> Dict[str, any]:
        """Get current deployment status.

        Returns:
            Deployment status information including progress
        """
        if not self.drbl_installed:
            return {
                'running': False,
                'message': 'DRBL not installed'
            }

        # Check if dcs or drbl-ocs is running
        try:
            result = subprocess.run(
                ['pgrep', '-f', 'dcs|drbl-ocs'],
                capture_output=True,
                text=True
            )

            is_running = result.returncode == 0

            if is_running:
                # Try to get progress from log files
                progress = self._parse_deployment_logs()

                return {
                    'running': True,
                    'progress': progress,
                    'check_time': datetime.now().isoformat()
                }
            else:
                return {
                    'running': False,
                    'message': 'No deployment in progress',
                    'check_time': datetime.now().isoformat()
                }

        except Exception as e:
            logger.error(f"Error checking deployment status: {str(e)}")
            return {
                'running': False,
                'error': str(e),
                'check_time': datetime.now().isoformat()
            }

    def _parse_deployment_logs(self) -> Dict[str, any]:
        """Parse DRBL deployment logs for progress information.

        Returns:
            Progress information dictionary
        """
        # DRBL logs are typically in /var/log/clonezilla/
        log_dir = Path('/var/log/clonezilla')

        if not log_dir.exists():
            return {'percentage': 0, 'message': 'Log directory not found'}

        # Look for latest log file
        log_files = sorted(log_dir.glob('*.log'), key=lambda x: x.stat().st_mtime, reverse=True)

        if not log_files:
            return {'percentage': 0, 'message': 'No log files found'}

        try:
            with open(log_files[0], 'r') as f:
                lines = f.readlines()

            # Parse for progress indicators (this is simplified)
            # Real implementation would parse actual Clonezilla progress format
            for line in reversed(lines):
                if '%' in line:
                    # Extract percentage
                    import re
                    match = re.search(r'(\d+)%', line)
                    if match:
                        percentage = int(match.group(1))
                        return {
                            'percentage': percentage,
                            'message': line.strip()
                        }

            return {'percentage': 0, 'message': 'Progress parsing in progress'}

        except Exception as e:
            logger.error(f"Error parsing logs: {str(e)}")
            return {'percentage': 0, 'error': str(e)}

    # ============================================================
    # ODJ Management
    # ============================================================

    def list_odj_files(self) -> List[Dict[str, any]]:
        """List all available ODJ files.

        Returns:
            List of ODJ file information dictionaries
        """
        odj_files = []

        if not self.odj_home.exists():
            logger.warning(f"ODJ directory not found: {self.odj_home}")
            return odj_files

        for odj_file in self.odj_home.glob('*.txt'):
            size_bytes = odj_file.stat().st_size
            created_timestamp = odj_file.stat().st_ctime
            created = datetime.fromtimestamp(created_timestamp).strftime('%Y-%m-%d %H:%M:%S')

            odj_files.append({
                'filename': odj_file.name,
                'path': str(odj_file),
                'size_bytes': size_bytes,
                'size_human': self._format_bytes(size_bytes),
                'created': created
            })

        return sorted(odj_files, key=lambda x: x['filename'])

    def get_odj_path(self, filename: str) -> Optional[str]:
        """Get full path to ODJ file.

        Args:
            filename: ODJ filename

        Returns:
            Full path string or None if not found
        """
        odj_path = self.odj_home / filename
        return str(odj_path) if odj_path.exists() else None

    # ============================================================
    # Utility Methods
    # ============================================================

    @staticmethod
    def _format_bytes(bytes_count: int) -> str:
        """Format bytes into human-readable string.

        Args:
            bytes_count: Number of bytes

        Returns:
            Formatted string (e.g., "14.6 GB")
        """
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if bytes_count < 1024.0:
                return f"{bytes_count:.1f} {unit}"
            bytes_count /= 1024.0
        return f"{bytes_count:.1f} PB"

    def health_check(self) -> Dict[str, any]:
        """Perform health check on DRBL system.

        Returns:
            Health status dictionary
        """
        status = {
            'drbl_installed': self.drbl_installed,
            'image_home_exists': self.image_home.exists(),
            'image_home_writable': os.access(self.image_home, os.W_OK) if self.image_home.exists() else False,
            'odj_home_exists': self.odj_home.exists(),
            'odj_home_writable': os.access(self.odj_home, os.W_OK) if self.odj_home.exists() else False,
            'image_count': len(self.list_images()),
            'odj_count': len(self.list_odj_files()),
            'check_time': datetime.now().isoformat()
        }

        return status
