#!/bin/bash
#
# TFTP Manual Test Script
# Tests TFTP server responses before attempting PXE boot
#
# Usage: ./test_tftp_manually.sh
#

set -e

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

TFTP_SERVER="192.168.3.135"

echo "============================================================================"
log_info "TFTP Server Manual Test"
echo "============================================================================"
echo ""

# Check if tftp client is installed
if ! command -v tftp &> /dev/null; then
    log_error "tftp client is not installed"
    log_info "Install with: sudo apt install tftp-hpa"
    exit 1
fi

# Create temp directory
TEST_DIR="/tmp/tftp_test_$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

log_info "Testing TFTP server at $TFTP_SERVER"
echo ""

# Test 1: Get pxelinux.0 from root
log_info "Test 1: Fetching pxelinux.0 (from root)"
if timeout 5 tftp "$TFTP_SERVER" -c get pxelinux.0 2>&1; then
    if [ -f "pxelinux.0" ]; then
        SIZE=$(stat -c%s pxelinux.0)
        log_info "  ✓ SUCCESS: Downloaded pxelinux.0 ($SIZE bytes)"
        rm pxelinux.0
    else
        log_error "  ✗ FAILED: File not downloaded"
    fi
else
    log_error "  ✗ FAILED: TFTP request timed out or failed"
fi

echo ""

# Test 2: Get pxelinux.0 from nbi_img subdirectory
log_info "Test 2: Fetching nbi_img/pxelinux.0 (from subdirectory)"
if timeout 5 tftp "$TFTP_SERVER" -c get nbi_img/pxelinux.0 2>&1; then
    if [ -f "pxelinux.0" ]; then
        SIZE=$(stat -c%s pxelinux.0)
        log_info "  ✓ SUCCESS: Downloaded nbi_img/pxelinux.0 ($SIZE bytes)"
        rm pxelinux.0
    else
        log_error "  ✗ FAILED: File not downloaded"
    fi
else
    log_error "  ✗ FAILED: TFTP request timed out or failed"
fi

echo ""

# Test 3: Get pxelinux.cfg/default
log_info "Test 3: Fetching pxelinux.cfg/default"
if timeout 5 tftp "$TFTP_SERVER" -c get pxelinux.cfg/default 2>&1; then
    if [ -f "default" ]; then
        SIZE=$(stat -c%s default)
        log_info "  ✓ SUCCESS: Downloaded pxelinux.cfg/default ($SIZE bytes)"
        log_info "  First 3 lines:"
        head -3 default | sed 's/^/    /'
        rm default
    else
        log_error "  ✗ FAILED: File not downloaded"
    fi
else
    log_error "  ✗ FAILED: TFTP request timed out or failed"
fi

echo ""

# Test 4: Verify TFTP server listening
log_info "Test 4: Checking TFTP server port 69"
if ss -uln | grep -q ":69 "; then
    log_info "  ✓ Port 69 is listening"
    ss -uln | grep ":69 " | sed 's/^/    /'
else
    log_error "  ✗ Port 69 is NOT listening"
fi

echo ""

# Test 5: Check TFTP process
log_info "Test 5: Checking TFTP process"
TFTP_PID=$(pgrep -x in.tftpd || echo "")
if [ -n "$TFTP_PID" ]; then
    log_info "  ✓ TFTP process is running (PID: $TFTP_PID)"
    ps aux | grep -E "^\S+\s+$TFTP_PID" | grep -v grep | sed 's/^/    /'

    # Extract TFTP root from process command line
    TFTP_ROOT=$(ps aux | grep -E "^\S+\s+$TFTP_PID" | grep -v grep | awk '{print $NF}')
    log_info "  TFTP root directory: $TFTP_ROOT"
else
    log_error "  ✗ TFTP process is NOT running"
fi

echo ""

# Test 6: Check file existence on server
log_info "Test 6: Verifying files on server"
echo "  Checking /tftpboot/pxelinux.0:"
if [ -f "/tftpboot/pxelinux.0" ] || [ -L "/tftpboot/pxelinux.0" ]; then
    ls -lh /tftpboot/pxelinux.0 | sed 's/^/    /'
else
    log_error "    ✗ NOT FOUND"
fi

echo "  Checking /tftpboot/nbi_img/pxelinux.0:"
if [ -f "/tftpboot/nbi_img/pxelinux.0" ]; then
    ls -lh /tftpboot/nbi_img/pxelinux.0 | sed 's/^/    /'
else
    log_error "    ✗ NOT FOUND"
fi

echo "  Checking /tftpboot/pxelinux.cfg/default:"
if [ -f "/tftpboot/pxelinux.cfg/default" ] || [ -L "/tftpboot/pxelinux.cfg/default" ]; then
    ls -lh /tftpboot/pxelinux.cfg/default 2>/dev/null | sed 's/^/    /' || echo "    (symlink)"
else
    log_error "    ✗ NOT FOUND"
fi

echo "  Checking /tftpboot/nbi_img/pxelinux.cfg/default:"
if [ -f "/tftpboot/nbi_img/pxelinux.cfg/default" ]; then
    ls -lh /tftpboot/nbi_img/pxelinux.cfg/default | sed 's/^/    /'
else
    log_error "    ✗ NOT FOUND"
fi

echo ""

# Cleanup
cd /
rm -rf "$TEST_DIR"

echo "============================================================================"
log_info "TFTP Manual Test COMPLETED"
echo "============================================================================"
echo ""

log_info "Interpretation:"
echo "  - Test 1 should succeed if TFTP root is /tftpboot (recommended)"
echo "  - Test 2 should succeed if TFTP root is /tftpboot"
echo "  - If Test 1 fails but Test 2 succeeds, TFTP root is likely /tftpboot/nbi_img"
echo ""

log_info "Next steps:"
echo "  1. If all tests pass, try PXE boot on the client"
echo "  2. Monitor logs: tail -f /var/log/syslog | grep -E 'dhcpd|tftpd'"
echo "  3. Or use: /usr/local/bin/monitor_pxe.sh"
echo ""
