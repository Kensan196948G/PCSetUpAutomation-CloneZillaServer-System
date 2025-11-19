#!/bin/bash
#
# PXE Boot Environment Fix Script
# Automatically repairs TFTP/DHCP configuration mismatches
# Based on comprehensive diagnosis of 2025-11-17
#
# Usage: sudo ./fix_pxe_boot.sh
#

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log function
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root (use sudo)"
    exit 1
fi

log_info "Starting PXE Boot Environment Fix..."
echo ""

# Backup configuration files
BACKUP_DIR="/root/pxe_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
log_info "Backing up configuration files to $BACKUP_DIR"

cp /etc/dhcp/dhcpd.conf "$BACKUP_DIR/dhcpd.conf.bak"
cp /etc/default/tftpd-hpa "$BACKUP_DIR/tftpd-hpa.bak"
cp /etc/default/isc-dhcp-server "$BACKUP_DIR/isc-dhcp-server.bak"

log_info "Backup completed"
echo ""

# ============================================================================
# FIX 1: TFTP Configuration - Set root to /tftpboot (CRITICAL)
# ============================================================================
log_info "Fix 1: Correcting TFTP root directory"

# Update /etc/default/tftpd-hpa
cat > /etc/default/tftpd-hpa <<'EOF'
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/tftpboot"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure"
EOF

log_info "Updated /etc/default/tftpd-hpa - TFTP root set to /tftpboot"

# ============================================================================
# FIX 2: DHCP Configuration - Update filename path (CRITICAL)
# ============================================================================
log_info "Fix 2: Updating DHCP filename configuration"

# Update dhcpd.conf to use symlink path
# Change: filename "pxelinux.0";
# To: filename "pxelinux.0";  (remains same, but TFTP root is now /tftpboot)
# The symlink /tftpboot/pxelinux.0 -> /tftpboot/nbi_img/pxelinux.0 will work

log_info "DHCP configuration: filename remains 'pxelinux.0' (symlink in /tftpboot will be used)"

# ============================================================================
# FIX 3: Add DHCP host declaration for client (HIGH)
# ============================================================================
log_info "Fix 3: Adding DHCP host declaration for client MAC"

CLIENT_MAC="ec:b1:d7:72:e8:38"
CLIENT_IP="192.168.3.2"
CLIENT_NAME="pxe-client-1"

# Check if host declaration already exists
if grep -q "$CLIENT_MAC" /etc/dhcp/dhcpd.conf; then
    log_warn "Host declaration for $CLIENT_MAC already exists, skipping"
else
    # Add host declaration before the subnet declaration
    sed -i "/^subnet 192.168.3.0 netmask 255.255.255.0 {/i\\
# Fixed IP assignment for PXE client\\
host $CLIENT_NAME {\\
    hardware ethernet $CLIENT_MAC;\\
    fixed-address $CLIENT_IP;\\
}\\
" /etc/dhcp/dhcpd.conf

    log_info "Added host declaration: $CLIENT_NAME ($CLIENT_MAC) -> $CLIENT_IP"
fi

# ============================================================================
# FIX 4: Verify file structure (MEDIUM)
# ============================================================================
log_info "Fix 4: Verifying TFTP file structure"

# Check if symlinks exist
if [ -L "/tftpboot/pxelinux.0" ]; then
    log_info "Symlink /tftpboot/pxelinux.0 exists"
else
    log_warn "Creating symlink /tftpboot/pxelinux.0 -> /tftpboot/nbi_img/pxelinux.0"
    ln -sf /tftpboot/nbi_img/pxelinux.0 /tftpboot/pxelinux.0
fi

if [ -L "/tftpboot/pxelinux.cfg" ]; then
    log_info "Symlink /tftpboot/pxelinux.cfg exists"
else
    log_warn "Creating symlink /tftpboot/pxelinux.cfg -> /tftpboot/nbi_img/pxelinux.cfg"
    ln -sf /tftpboot/nbi_img/pxelinux.cfg /tftpboot/pxelinux.cfg
fi

if [ -L "/tftpboot/initrd-pxe.img" ]; then
    log_info "Symlink /tftpboot/initrd-pxe.img exists"
else
    log_warn "Creating symlink /tftpboot/initrd-pxe.img -> /tftpboot/nbi_img/initrd-pxe.img"
    ln -sf /tftpboot/nbi_img/initrd-pxe.img /tftpboot/initrd-pxe.img
fi

if [ -L "/tftpboot/vmlinuz-pxe" ] || [ -f "/tftpboot/vmlinuz-pxe" ]; then
    log_info "vmlinuz-pxe exists"
else
    log_warn "Creating symlink /tftpboot/vmlinuz-pxe -> /tftpboot/nbi_img/vmlinuz-pxe"
    ln -sf /tftpboot/nbi_img/vmlinuz-pxe /tftpboot/vmlinuz-pxe
fi

# Verify actual files exist
if [ -f "/tftpboot/nbi_img/pxelinux.0" ]; then
    log_info "Actual file /tftpboot/nbi_img/pxelinux.0 exists ($(stat -c%s /tftpboot/nbi_img/pxelinux.0) bytes)"
else
    log_error "CRITICAL: /tftpboot/nbi_img/pxelinux.0 does NOT exist!"
    exit 1
fi

# ============================================================================
# FIX 5: Restart services (CRITICAL)
# ============================================================================
log_info "Fix 5: Restarting TFTP and DHCP services"

# Kill any manually started TFTP processes
log_info "Killing existing TFTP processes..."
pkill -9 in.tftpd || true
sleep 2

# Restart TFTP service
log_info "Starting tftpd-hpa service..."
systemctl restart tftpd-hpa.service || {
    log_error "Failed to restart tftpd-hpa via systemctl"
    log_warn "Starting TFTP manually..."
    /usr/sbin/in.tftpd --listen --user tftp --address 0.0.0.0:69 --secure /tftpboot &
}

sleep 2

# Check TFTP status
if systemctl is-active --quiet tftpd-hpa.service; then
    log_info "tftpd-hpa service is active"
elif pgrep -x in.tftpd > /dev/null; then
    log_warn "tftpd-hpa service not active, but in.tftpd process is running"
else
    log_error "TFTP service failed to start!"
    exit 1
fi

# Restart DHCP service
log_info "Restarting isc-dhcp-server service..."
systemctl restart isc-dhcp-server.service

if systemctl is-active --quiet isc-dhcp-server.service; then
    log_info "isc-dhcp-server service is active"
else
    log_error "DHCP service failed to start!"
    exit 1
fi

# ============================================================================
# FIX 6: Verify service status and network bindings
# ============================================================================
log_info "Fix 6: Verifying service status and network bindings"
echo ""

# Check TFTP
log_info "TFTP Status:"
if ss -uln | grep -q ":69 "; then
    log_info "  ✓ Port 69 is listening"
    ss -uln | grep ":69 "
else
    log_error "  ✗ Port 69 is NOT listening"
fi

TFTP_PID=$(pgrep -x in.tftpd || echo "none")
if [ "$TFTP_PID" != "none" ]; then
    log_info "  ✓ TFTP process is running (PID: $TFTP_PID)"
    ps aux | grep -E "^\S+\s+$TFTP_PID" | grep -v grep
else
    log_error "  ✗ TFTP process is NOT running"
fi

echo ""

# Check DHCP
log_info "DHCP Status:"
if systemctl is-active --quiet isc-dhcp-server.service; then
    log_info "  ✓ isc-dhcp-server service is active"
    DHCP_PID=$(systemctl show -p MainPID --value isc-dhcp-server.service)
    log_info "  ✓ DHCP process PID: $DHCP_PID"
else
    log_error "  ✗ isc-dhcp-server service is NOT active"
fi

if ss -uln | grep -q ":67 "; then
    log_info "  ✓ Port 67 is listening"
else
    log_error "  ✗ Port 67 is NOT listening"
fi

echo ""

# ============================================================================
# FIX 7: Configuration verification
# ============================================================================
log_info "Fix 7: Configuration verification"
echo ""

log_info "DHCP Configuration:"
echo "  next-server: $(grep -A5 '^subnet 192.168.3.0' /etc/dhcp/dhcpd.conf | grep next-server)"
echo "  filename: $(grep -A5 '^subnet 192.168.3.0' /etc/dhcp/dhcpd.conf | grep 'filename ')"

echo ""

log_info "TFTP Configuration:"
echo "  Root directory: $(grep TFTP_DIRECTORY /etc/default/tftpd-hpa)"
echo "  Actual process: $(ps aux | grep in.tftpd | grep -v grep | awk '{print $NF}')"

echo ""

# ============================================================================
# FIX 8: Create monitoring script
# ============================================================================
log_info "Fix 8: Creating monitoring script"

cat > /usr/local/bin/monitor_pxe.sh <<'MONITOR_EOF'
#!/bin/bash
# PXE Boot Monitoring Script
# Monitors TFTP and DHCP logs in real-time

echo "Monitoring PXE boot environment..."
echo "Press Ctrl+C to stop"
echo ""

# Monitor both DHCP and TFTP logs
tail -f /var/log/syslog | grep -E --line-buffered 'dhcpd|tftpd|in.tftpd' | while read line; do
    echo "[$(date '+%H:%M:%S')] $line"
done
MONITOR_EOF

chmod +x /usr/local/bin/monitor_pxe.sh
log_info "Created monitoring script: /usr/local/bin/monitor_pxe.sh"

echo ""
echo "============================================================================"
log_info "PXE Boot Environment Fix COMPLETED"
echo "============================================================================"
echo ""

log_info "Summary of changes:"
echo "  1. TFTP root directory set to: /tftpboot"
echo "  2. DHCP filename: pxelinux.0 (symlink will be used)"
echo "  3. Client MAC $CLIENT_MAC fixed to IP $CLIENT_IP"
echo "  4. File structure verified and symlinks created"
echo "  5. Services restarted (TFTP + DHCP)"
echo ""

log_info "Backup location: $BACKUP_DIR"
echo ""

log_info "Next steps:"
echo "  1. Ensure home router DHCP does not conflict (range should start from .100+)"
echo "  2. Boot the PXE client and observe the output"
echo "  3. Monitor logs with: /usr/local/bin/monitor_pxe.sh"
echo "  4. Or check logs manually: tail -f /var/log/syslog | grep -E 'dhcpd|tftpd'"
echo ""

log_info "Expected behavior:"
echo "  - Client MAC: $CLIENT_MAC"
echo "  - Assigned IP: $CLIENT_IP"
echo "  - TFTP request: 'RRQ from $CLIENT_IP filename pxelinux.0'"
echo "  - Client screen: 'PXELINUX 6.03 ...'"
echo ""

log_info "Testing TFTP manually:"
echo "  From another machine: tftp 192.168.3.135 -c get pxelinux.0"
echo ""

echo "============================================================================"
