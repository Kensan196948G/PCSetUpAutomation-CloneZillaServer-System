#!/bin/bash
# =============================================================================
#
# Unified DRBL/Clonezilla Server Setup Script
#
# Description:
#   This script automates the complete setup of a DRBL/Clonezilla server
#   by reading a centralized configuration file. It handles network
#   preparation, DRBL initialization, DHCP/NFS configuration, and service
#   management.
#
# Author: Gemini
# Date: 2025-11-18
#
# =============================================================================

set -eEuo pipefail

# --- 言語設定 ---
LANG_MSG="en"
if [[ "${LANG}" == "ja_JP.UTF-8" ]]; then
    LANG_MSG="ja"
fi

# --- グローバル変数と設定 ---
CONFIG_FILE_EN="configs/drbl_config.conf"
CONFIG_FILE_JA="configs/drbl_config.jp.conf"
CONFIG_FILE="" # 動的に設定
DRBL_CONF_DIR="/etc/drbl"
DHCPD_CONF="/etc/dhcp/dhcpd.conf"
DHCP_DEFAULT_CONF="/etc/default/isc-dhcp-server"
EXPORTS_CONF="/etc/exports"
TFTP_ROOT_DIR="/tftpboot"

# --- メッセージ ---
MSG_LOADING_CONFIG_EN="Loading configuration from"
MSG_LOADING_CONFIG_JA="設定ファイルを読み込んでいます:"
MSG_CONFIG_LOADED_EN="Configuration loaded successfully."
MSG_CONFIG_LOADED_JA="設定の読み込みが完了しました。"
MSG_CONFIG_NOT_FOUND_EN="Configuration file not found at"
MSG_CONFIG_NOT_FOUND_JA="設定ファイルが見つかりません:"
MSG_PREPARING_ENV_EN="Preparing environment for DRBL setup..."
MSG_PREPARING_ENV_JA="DRBLセットアップのための環境を準備しています..."
MSG_STOPPING_DOCKER_EN="Stopping Docker service to avoid network conflicts..."
MSG_STOPPING_DOCKER_JA="ネットワークの競合を避けるため、Dockerサービスを停止しています..."
MSG_DOCKER_STOPPED_EN="Docker service is already stopped."
MSG_DOCKER_STOPPED_JA="Dockerサービスは既に停止しています。"
MSG_REMOVING_DOCKER_IF_EN="Removing"
MSG_REMOVING_DOCKER_IF_JA="ネットワークインターフェースを削除しています:"
MSG_DOCKER_IF_NOT_EXIST_EN="interface does not exist, skipping."
MSG_DOCKER_IF_NOT_EXIST_JA="インターフェースが存在しないため、スキップします。"
MSG_ENV_PREP_COMPLETE_EN="Environment preparation complete."
MSG_ENV_PREP_COMPLETE_JA="環境の準備が完了しました。"
MSG_GEN_DRBL_CONF_EN="Generating DRBL configuration at"
MSG_GEN_DRBL_CONF_JA="DRBL設定を生成しています:"
MSG_DRBL_CONF_GENERATED_EN="DRBL configuration generated."
MSG_DRBL_CONF_GENERATED_JA="DRBL設定の生成が完了しました。"
MSG_CONFIGURING_DHCP_EN="Configuring ISC DHCP Server..."
MSG_CONFIGURING_DHCP_JA="ISC DHCPサーバーを設定しています..."
MSG_DHCP_CONF_GENERATED_EN="Generated"
MSG_DHCP_CONF_GENERATED_JA="を生成しました。"
MSG_SET_DHCP_INTERFACE_EN="Set DHCP listening interface to"
MSG_SET_DHCP_INTERFACE_JA="DHCPの待機インターフェースを"
MSG_DHCP_CONFIG_COMPLETE_EN="DHCP configuration complete."
MSG_DHCP_CONFIG_COMPLETE_JA="DHCPの設定が完了しました。"
MSG_CONFIGURING_NFS_EN="Configuring NFS server..."
MSG_CONFIGURING_NFS_JA="NFSサーバーを設定しています..."
MSG_CREATING_NODE_DIRS_EN="Creating node directories from"
MSG_CREATING_NODE_DIRS_JA="ノードディレクトリを作成しています:"
MSG_NODE_DIRS_CREATED_EN="Node directories created."
MSG_NODE_DIRS_CREATED_JA="ノードディレクトリの作成が完了しました。"
MSG_NFS_CONFIG_COMPLETE_EN="NFS configuration complete."
MSG_NFS_CONFIG_COMPLETE_JA="NFSの設定が完了しました。"
MSG_RUNNING_DRBL_PUSH_EN="Running 'drblpush -c' to create client configuration..."
MSG_RUNNING_DRBL_PUSH_JA="'drblpush -c' を実行してクライアント設定を作成しています..."
MSG_DRBL_PUSH_COMPLETE_EN="'drblpush -c' completed."
MSG_DRBL_PUSH_COMPLETE_JA="'drblpush -c' が完了しました。"
MSG_RESTARTING_SERVICES_EN="Restarting essential services..."
MSG_RESTARTING_SERVICES_JA="必須サービスを再起動しています..."
MSG_RESTARTING_DHCP_EN="Restarting ISC DHCP Server..."
MSG_RESTARTING_DHCP_JA="ISC DHCPサーバーを再起動しています..."
MSG_RESTARTING_TFTP_EN="Restarting TFTP (tftpd-hpa) Server..."
MSG_RESTARTING_TFTP_JA="TFTP (tftpd-hpa) サーバーを再起動しています..."
MSG_RESTARTING_NFS_EN="Applying NFS exports and restarting NFS Server..."
MSG_RESTARTING_NFS_JA="NFSエクスポートを適用し、NFSサーバーを再起動しています..."
MSG_SERVICES_RESTARTED_EN="All essential services have been restarted."
MSG_SERVICES_RESTARTED_JA="すべての必須サービスが再起動されました。"
MSG_FINAL_STATUS_CHECK_EN="Performing final status checks..."
MSG_FINAL_STATUS_CHECK_JA="最終ステータスを確認しています..."
MSG_DHCP_ACTIVE_EN="✅ DHCP Server is active."
MSG_DHCP_ACTIVE_JA="✅ DHCPサーバーは正常に動作しています。"
MSG_DHCP_INACTIVE_EN="❌ DHCP Server is INACTIVE."
MSG_DHCP_INACTIVE_JA="❌ DHCPサーバーは停止しています。"
MSG_TFTP_ACTIVE_EN="✅ TFTP Server is active."
MSG_TFTP_ACTIVE_JA="✅ TFTPサーバーは正常に動作しています。"
MSG_TFTP_INACTIVE_EN="❌ TFTP Server is INACTIVE."
MSG_TFTP_INACTIVE_JA="❌ TFTPサーバーは停止しています。"
MSG_NFS_ACTIVE_EN="✅ NFS Server is active."
MSG_NFS_ACTIVE_JA="✅ NFSサーバーは正常に動作しています。"
MSG_NFS_INACTIVE_EN="❌ NFS Server is INACTIVE."
MSG_NFS_INACTIVE_JA="❌ NFSサーバーは停止しています。"
MSG_PXE_BOOT_FOUND_EN="✅ PXE boot file (pxelinux.0) found."
MSG_PXE_BOOT_FOUND_JA="✅ PXEブートファイル (pxelinux.0) が見つかりました。"
MSG_PXE_BOOT_NOT_FOUND_EN="❌ PXE boot file (pxelinux.0) NOT found in"
MSG_PXE_BOOT_NOT_FOUND_JA="❌ PXEブートファイル (pxelinux.0) が見つかりません:"
MSG_SYSTEM_READY_EN="🎉 System is Ready for PXE Boot! 🎉"
MSG_SYSTEM_READY_JA="🎉 PXEブートの準備が完了しました! 🎉"
MSG_ERRORS_DETECTED_EN="🔥 Errors detected. Please review the logs. 🔥"
MSG_ERRORS_DETECTED_JA="🔥 エラーが検出されました。ログを確認してください。 🔥"
MSG_UNIFIED_SETUP_STARTED_EN="Unified DRBL/Clonezilla Server Setup Started"
MSG_UNIFIED_SETUP_STARTED_JA="統合DRBL/Clonezillaサーバーセットアップ開始"
MSG_UNIFIED_SETUP_COMPLETED_EN="Unified Setup Script Completed Successfully"
MSG_UNIFIED_SETUP_COMPLETED_JA="統合セットアップスクリプトは正常に完了しました"

# --- Utility Functions ---
log() {
    if [[ "${LANG_MSG}" == "ja" ]]; then
        echo "情報: $1"
    else
        echo "INFO: $1"
    fi
}

error() {
    if [[ "${LANG_MSG}" == "ja" ]]; then
        echo "エラー: $1" >&2
    else
        echo "ERROR: $1" >&2
    fi
    exit 1
}

# --- Main Setup Functions ---

# 1. Load Configuration
load_config() {
    if [[ "${LANG_MSG}" == "ja" ]]; then
        CONFIG_FILE="${CONFIG_FILE_JA}"
        log "${MSG_LOADING_CONFIG_JA} ${CONFIG_FILE}"
    else
        CONFIG_FILE="${CONFIG_FILE_EN}"
        log "${MSG_LOADING_CONFIG_EN} ${CONFIG_FILE}"
    fi

    if [[ ! -f "${CONFIG_FILE}" ]]; then
        if [[ "${LANG_MSG}" == "ja" ]]; then
            error "${MSG_CONFIG_NOT_FOUND_JA} ${CONFIG_FILE}"
        else
            error "${MSG_CONFIG_NOT_FOUND_EN} ${CONFIG_FILE}"
        fi
    fi
    # shellcheck source=configs/drbl_config.conf
    source "${CONFIG_FILE}"
    if [[ "${LANG_MSG}" == "ja" ]]; then
        log "${MSG_CONFIG_LOADED_JA}"
    else
        log "${MSG_CONFIG_LOADED_EN}"
    fi
}

# 2. Prepare Environment (Handle Docker Conflict)
prepare_environment() {
    if [[ "${LANG_MSG}" == "ja" ]]; then
        log "${MSG_PREPARING_ENV_JA}"
    else
        log "${MSG_PREPARING_ENV_EN}"
    fi

    if systemctl is-active --quiet docker; then
        if [[ "${LANG_MSG}" == "ja" ]]; then
            log "${MSG_STOPPING_DOCKER_JA}"
        else
            log "${MSG_STOPPING_DOCKER_EN}"
        fi
        sudo systemctl stop docker
    else
        if [[ "${LANG_MSG}" == "ja" ]]; then
            log "${MSG_DOCKER_STOPPED_JA}"
        else
            log "${MSG_DOCKER_STOPPED_EN}"
        fi
    fi

    if ip link show "${DOCKER_INTERFACE}" &>/dev/null; then
        if [[ "${LANG_MSG}" == "ja" ]]; then
            log "${MSG_REMOVING_DOCKER_IF_JA} ${DOCKER_INTERFACE}"
        else
            log "${MSG_REMOVING_DOCKER_IF_EN} ${DOCKER_INTERFACE}"
        fi
        sudo ip link delete "${DOCKER_INTERFACE}"
    else
        if [[ "${LANG_MSG}" == "ja" ]]; then
            log "${DOCKER_INTERFACE} ${MSG_DOCKER_IF_NOT_EXIST_JA}"
        else
            log "${DOCKER_INTERFACE} ${MSG_DOCKER_IF_NOT_EXIST_EN}"
        fi
    fi
    if [[ "${LANG_MSG}" == "ja" ]]; then
        log "${MSG_ENV_PREP_COMPLETE_JA}"
    else
        log "${MSG_ENV_PREP_COMPLETE_EN}"
    fi
}

# 3. Generate DRBL Configuration
generate_drbl_conf() {
    if [[ "${LANG_MSG}" == "ja" ]]; then
        log "${MSG_GEN_DRBL_CONF_JA} ${DRBL_CONF_DIR}/drblpush.conf"
    else
        log "${MSG_GEN_DRBL_CONF_EN} ${DRBL_CONF_DIR}/drblpush.conf"
    fi
    sudo mkdir -p "${DRBL_CONF_DIR}"
    sudo bash -c "cat > ${DRBL_CONF_DIR}/drblpush.conf" <<EOF
[general]
domain=${DRBL_DOMAIN}
nisdomain=${DRBL_DOMAIN}
clients_hostname_prefix=${CLIENT_HOSTNAME_PREFIX}
language=en_US.UTF-8
[ethernet]
eth_card_num=1
[eth_card_1]
eth_card_dev=${DRBL_NIC}
eth_card_ip=${DRBL_SERVER_IP}
eth_card_netmask=255.255.255.0
[dhcp]
dhcp_server_program=isc-dhcp
dhcpd_pxe_filename="pxelinux.0"
dhcpd_range=${DHCP_RANGE_START} ${DHCP_RANGE_END}
[client]
client_architecture=i386
client_system_suite=bionic
client_system_type=ubuntu
[clonezilla]
clonezilla_mode=${CLONEZILLA_MODE}
clonezilla_home=${IMAGE_REPO}
EOF
    if [[ "${LANG_MSG}" == "ja" ]]; then
        log "${MSG_DRBL_CONF_GENERATED_JA}"
    else
        log "${MSG_DRBL_CONF_GENERATED_EN}"
    fi
}

# 4. Configure DHCP Server
configure_dhcp() {
    if [[ "${LANG_MSG}" == "ja" ]]; then
        log "${MSG_CONFIGURING_DHCP_JA}"
    else
        log "${MSG_CONFIGURING_DHCP_EN}"
    fi

    # Create dhcpd.conf
    sudo bash -c "cat > ${DHCPD_CONF}" <<EOF
# DHCP Server Configuration file.
# see /usr/share/doc/isc-dhcp-server/dhcpd.conf.example
#
option domain-name "${DRBL_DOMAIN}";
option domain-name-servers ${DRBL_SERVER_IP};
default-lease-time 600;
max-lease-time 7200;
ddns-update-style none;
authoritative;
log-facility local7;

subnet 192.168.3.0 netmask 255.255.255.0 {
  range ${DHCP_RANGE_START} ${DHCP_RANGE_END};
  option routers ${DRBL_SERVER_IP};
  filename "pxelinux.0";
  next-server ${DRBL_SERVER_IP};
}
EOF
    if [[ "${LANG_MSG}" == "ja" ]]; then
        log "${DHCPD_CONF} ${MSG_DHCP_CONF_GENERATED_JA}"
    else
        log "${MSG_DHCP_CONF_GENERATED_EN} ${DHCPD_CONF}."
    fi

    # Set listening interface
    if [[ "${LANG_MSG}" == "ja" ]]; then
        log "${MSG_SET_DHCP_INTERFACE_JA} ${DRBL_NIC}"
    else
        log "${MSG_SET_DHCP_INTERFACE_EN} ${DRBL_NIC} in ${DHCP_DEFAULT_CONF}."
    fi
    sudo sed -i "s/INTERFACESv4=.*/INTERFACESv4=\"${DRBL_NIC}\"/" "${DHCP_DEFAULT_CONF}"
    if [[ "${LANG_MSG}" == "ja" ]]; then
        log "${MSG_DHCP_CONFIG_COMPLETE_JA}"
    else
        log "${MSG_DHCP_CONFIG_COMPLETE_EN}"
    fi
}

# 5. Configure NFS
configure_nfs() {
    if [[ "${LANG_MSG}" == "ja" ]]; then
        log "${MSG_CONFIGURING_NFS_JA}"
    else
        log "${MSG_CONFIGURING_NFS_EN}"
    fi

    # Create node directories
    if [[ "${LANG_MSG}" == "ja" ]]; then
        log "${MSG_CREATING_NODE_DIRS_JA} ${NODE_IP_START} から ${NODE_IP_END}"
    else
        log "${MSG_CREATING_NODE_DIRS_EN} ${NODE_IP_START} to ${NODE_IP_END}..."
    fi
    for i in $(seq "${NODE_IP_START}" "${NODE_IP_END}"); do
        dir="${NFS_ROOT}/${NODE_IP_PREFIX}.${i}"
        if [[ ! -d "$dir" ]]; then
            if [[ "${LANG_MSG}" == "ja" ]]; then
                log "新規ディレクトリを作成中: ${dir}"
            else
                log "Creating new directory: ${dir}"
            fi
            sudo mkdir -p "${dir}"
        else
            if [[ "${LANG_MSG}" == "ja" ]]; then
                log "既存ディレクトリを確認: ${dir}"
            else
                log "Checking existing directory: ${dir}"
            fi
        fi
    done
    sudo chmod -R 755 "${NFS_ROOT}"
    if [[ "${LANG_MSG}" == "ja" ]]; then
        log "${MSG_NODE_DIRS_CREATED_JA}"
    else
        log "${MSG_NODE_DIRS_CREATED_EN}"
    fi

    # Create /etc/exports
    sudo bash -c "cat > ${EXPORTS_CONF}" <<EOF
# /etc/exports: the access control list for filesystems which may be exported
#               to NFS clients.  See exports(5).
#
${IMAGE_REPO} *(ro,sync,no_wdelay,insecure_locks,no_root_squash,insecure)
${TFTP_ROOT_DIR} *(ro,sync,no_wdelay,insecure_locks,no_root_squash,insecure)
EOF
    if [[ "${LANG_MSG}" == "ja" ]]; then
        log "${EXPORTS_CONF} ${MSG_DHCP_CONF_GENERATED_JA}"
    else
        log "Generated ${EXPORTS_CONF}."
    fi
    if [[ "${LANG_MSG}" == "ja" ]]; then
        log "${MSG_NFS_CONFIG_COMPLETE_JA}"
    else
        log "${MSG_NFS_CONFIG_COMPLETE_EN}"
    fi
}

# 6. Run DRBL Push Command
run_drbl_push() {
    if [[ "${LANG_MSG}" == "ja" ]]; then
        log "${MSG_RUNNING_DRBL_PUSH_JA}"
    else
        log "${MSG_RUNNING_DRBL_PUSH_EN}"
    fi
    # The 'drblpush -c' command generates the final configs based on drblpush.conf
    sudo /usr/sbin/drblpush -c
    if [[ "${LANG_MSG}" == "ja" ]]; then
        log "${MSG_DRBL_PUSH_COMPLETE_JA}"
    else
        log "${MSG_DRBL_PUSH_COMPLETE_EN}"
    fi
}

# 7. Restart Essential Services
restart_services() {
    if [[ "${LANG_MSG}" == "ja" ]]; then
        log "${MSG_RESTARTING_SERVICES_JA}"
    else
        log "${MSG_RESTARTING_SERVICES_EN}"
    fi
    
    # Restart DHCP Server
    if [[ "${LANG_MSG}" == "ja" ]]; then log "${MSG_RESTARTING_DHCP_JA}"; else log "${MSG_RESTARTING_DHCP_EN}"; fi
    sudo systemctl restart isc-dhcp-server
    if sudo systemctl is-active --quiet isc-dhcp-server; then
        if [[ "${LANG_MSG}" == "ja" ]]; then log "✅ DHCPサーバーの再起動に成功しました。"; else log "✅ DHCP server restarted successfully."; fi
    else
        if [[ "${LANG_MSG}" == "ja" ]]; then error "❌ DHCPサーバーの再起動に失敗しました。"; else error "❌ Failed to restart DHCP server."; fi
    fi

    # Restart TFTP Server
    if [[ "${LANG_MSG}" == "ja" ]]; then log "${MSG_RESTARTING_TFTP_JA}"; else log "${MSG_RESTARTING_TFTP_EN}"; fi
    sudo systemctl restart tftpd-hpa
    if sudo systemctl is-active --quiet tftpd-hpa; then
        if [[ "${LANG_MSG}" == "ja" ]]; then log "✅ TFTPサーバーの再起動に成功しました。"; else log "✅ TFTP server restarted successfully."; fi
    else
        if [[ "${LANG_MSG}" == "ja" ]]; then error "❌ TFTPサーバーの再起動に失敗しました。"; else error "❌ Failed to restart TFTP server."; fi
    fi

    # Re-export NFS filesystems and restart NFS Server
    if [[ "${LANG_MSG}" == "ja" ]]; then log "${MSG_RESTARTING_NFS_JA}"; else log "${MSG_RESTARTING_NFS_EN}"; fi
    sudo exportfs -ra
    sudo systemctl restart nfs-kernel-server
    if sudo systemctl is-active --quiet nfs-kernel-server; then
        if [[ "${LANG_MSG}" == "ja" ]]; then log "✅ NFSサーバーの再起動に成功しました。"; else log "✅ NFS server restarted successfully."; fi
    else
        if [[ "${LANG_MSG}" == "ja" ]]; then error "❌ NFSサーバーの再起動に失敗しました。"; else error "❌ Failed to restart NFS server."; fi
    fi
    
    if [[ "${LANG_MSG}" == "ja" ]]; then
        log "${MSG_SERVICES_RESTARTED_JA}"
    else
        log "${MSG_SERVICES_RESTARTED_EN}"
    fi
}

# 8. Final Status Check
final_status_check() {
    if [[ "${LANG_MSG}" == "ja" ]]; then
        log "${MSG_FINAL_STATUS_CHECK_JA}"
    else
        log "${MSG_FINAL_STATUS_CHECK_EN}"
    fi
    local all_ok=true

    # Check DHCP
    if sudo systemctl is-active --quiet isc-dhcp-server; then
        if [[ "${LANG_MSG}" == "ja" ]]; then
            log "${MSG_DHCP_ACTIVE_JA}"
        else
            log "${MSG_DHCP_ACTIVE_EN}"
        fi
    else
        if [[ "${LANG_MSG}" == "ja" ]]; then
            log "${MSG_DHCP_INACTIVE_JA}"
        else
            log "${MSG_DHCP_INACTIVE_EN}"
        fi
        all_ok=false
    fi

    # Check TFTP
    if sudo systemctl is-active --quiet tftpd-hpa; then
        if [[ "${LANG_MSG}" == "ja" ]]; then
            log "${MSG_TFTP_ACTIVE_JA}"
        else
            log "${MSG_TFTP_ACTIVE_EN}"
        fi
    else
        if [[ "${LANG_MSG}" == "ja" ]]; then
            log "${MSG_TFTP_INACTIVE_JA}"
        else
            log "${MSG_TFTP_INACTIVE_EN}"
        fi
        all_ok=false
    fi

    # Check NFS
    if sudo systemctl is-active --quiet nfs-kernel-server; then
        if [[ "${LANG_MSG}" == "ja" ]]; then
            log "${MSG_NFS_ACTIVE_JA}"
        else
            log "${MSG_NFS_ACTIVE_EN}"
        fi
    else
        if [[ "${LANG_MSG}" == "ja" ]]; then
            log "${MSG_NFS_INACTIVE_JA}"
        else
            log "${MSG_NFS_INACTIVE_EN}"
        fi
        all_ok=false
    fi

    # Check for PXE boot file
    if [[ -f "${TFTP_ROOT_DIR}/pxelinux.0" ]]; then
        if [[ "${LANG_MSG}" == "ja" ]]; then
            log "${MSG_PXE_BOOT_FOUND_JA}"
        else
            log "${MSG_PXE_BOOT_FOUND_EN}"
        fi
    else
        if [[ "${LANG_MSG}" == "ja" ]]; then
            log "${MSG_PXE_BOOT_NOT_FOUND_JA} ${TFTP_ROOT_DIR}"
        else
            log "${MSG_PXE_BOOT_NOT_FOUND_EN} ${TFTP_ROOT_DIR}."
        fi
        all_ok=false
    fi

    if [[ "$all_ok" = true ]]; then
        echo "================================================="
        if [[ "${LANG_MSG}" == "ja" ]]; then
            echo "  ${MSG_SYSTEM_READY_JA}"
        else
            echo "  ${MSG_SYSTEM_READY_EN}"
        fi
        echo "================================================="
    else
        echo "================================================="
        if [[ "${LANG_MSG}" == "ja" ]]; then
            echo "  ${MSG_ERRORS_DETECTED_JA}"
        else
            echo "  ${MSG_ERRORS_DETECTED_EN}"
        fi
        echo "================================================="
        if [[ "${LANG_MSG}" == "ja" ]]; then
            error "一つ以上のサービスが起動に失敗しました。"
        else
            error "One or more services failed to start."
        fi
    fi
}


# --- Main Execution ---
main() {
    echo "================================================="
    if [[ "${LANG_MSG}" == "ja" ]]; then
        echo "  ${MSG_UNIFIED_SETUP_STARTED_JA}"
    else
        echo "  ${MSG_UNIFIED_SETUP_STARTED_EN}"
    fi
    echo "================================================="

    load_config
    prepare_environment
    generate_drbl_conf
    configure_dhcp
    configure_nfs
    run_drbl_push
    restart_services
    final_status_check

    echo "================================================="
    if [[ "${LANG_MSG}" == "ja" ]]; then
        echo "  ${MSG_UNIFIED_SETUP_COMPLETED_JA}"
    else
        echo "  ${MSG_UNIFIED_SETUP_COMPLETED_EN}"
    fi
    echo "================================================="
}


# --- Script Entry Point ---
main "$@"