#!/bin/bash
# DRBL/Clonezilla Server Installation Script
# Ubuntu 22.04 LTS

set -e

echo "========================================="
echo "DRBL/Clonezilla Server Installation"
echo "========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Update system
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Add DRBL repository
echo "Adding DRBL repository..."
wget -q https://drbl.org/GPG-KEY-DRBL -O- | apt-key add -
echo "deb http://drbl.sourceforge.net/drbl-core drbl stable" > /etc/apt/sources.list.d/drbl.list

# Update package list
apt-get update

# Install DRBL
echo "Installing DRBL..."
apt-get install -y drbl

# Install additional packages
echo "Installing additional packages..."
apt-get install -y \
    clonezilla \
    partclone \
    udpcast \
    tftp-hpa \
    tftpd-hpa \
    isc-dhcp-server \
    nfs-kernel-server

# Create directories
echo "Creating directories..."
mkdir -p /home/partimag
mkdir -p /srv/odj
mkdir -p /var/log/pc-setup

# Set permissions
chmod 755 /home/partimag
chmod 700 /srv/odj

echo "========================================="
echo "Installation completed!"
echo ""
echo "Next steps:"
echo "1. Run: sudo /opt/drbl/sbin/drblsrv -i"
echo "2. Run: sudo /opt/drbl/sbin/drblpush -i"
echo "3. Configure network interfaces"
echo "4. Place master images in /home/partimag/"
echo "========================================="
