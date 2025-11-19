#!/bin/bash

################################################################################
# VirtualBox検証環境セットアップスクリプト
#
# 概要: Windows 11テスト用仮想マシンを自動作成
# 用途: マスターイメージ作成前のISOテスト、自動セットアップスクリプトの検証
#
# 実行方法:
#   ./setup-test-vm.sh [VM_NAME] [ISO_PATH]
#
# 例:
#   ./setup-test-vm.sh Win11-Test /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/media/Windows11.iso
################################################################################

set -e  # エラー時に停止

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_separator() {
    echo "================================================================================"
}

################################################################################
# パラメータ設定
################################################################################

# VM名（引数 or デフォルト）
VM_NAME="${1:-Win11-Test-$(date +%Y%m%d%H%M%S)}"

# ISOパス（引数 or デフォルト）
ISO_PATH="${2:-/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/media/Windows11.iso}"

# VM設定
VM_MEMORY=8192          # 8GB RAM
VM_CPUS=2               # 2コア
VM_DISK_SIZE=65536      # 64GB
VM_VRAM=128             # 128MB VRAM
VM_NETWORK="nat"        # ネットワークタイプ

# VirtualBox VM保存ディレクトリ
VBOX_DIR="$HOME/VirtualBox VMs"
VM_DIR="$VBOX_DIR/$VM_NAME"

print_separator
log_info "VirtualBox仮想マシン作成スクリプト"
log_info "VM名: $VM_NAME"
log_info "ISOパス: $ISO_PATH"
print_separator

################################################################################
# 前提条件チェック
################################################################################

echo ""
log_info "[1/8] 前提条件チェック"

# VirtualBox インストール確認
if ! command -v VBoxManage &> /dev/null; then
    log_error "VirtualBoxがインストールされていません"
    log_info "インストール方法: sudo apt install virtualbox"
    exit 1
else
    VBOX_VERSION=$(VBoxManage --version)
    log_success "VirtualBox検出: $VBOX_VERSION"
fi

# ISOファイル存在確認
if [ ! -f "$ISO_PATH" ]; then
    log_error "ISOファイルが見つかりません: $ISO_PATH"
    exit 1
else
    ISO_SIZE=$(du -h "$ISO_PATH" | cut -f1)
    log_success "ISOファイル検出: $ISO_PATH ($ISO_SIZE)"
fi

# VM名の重複チェック
if VBoxManage list vms | grep -q "\"$VM_NAME\""; then
    log_warning "VM名 '$VM_NAME' は既に存在します"
    read -p "削除して再作成しますか？ (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "既存VMを削除中..."
        VBoxManage unregistervm "$VM_NAME" --delete 2>/dev/null || true
        log_success "既存VM削除完了"
    else
        log_error "処理を中断しました"
        exit 1
    fi
fi

################################################################################
# 仮想マシン作成
################################################################################

echo ""
log_info "[2/8] 仮想マシン作成"

VBoxManage createvm \
    --name "$VM_NAME" \
    --ostype "Windows11_64" \
    --register \
    --basefolder "$VBOX_DIR"

log_success "VM作成完了: $VM_NAME"

################################################################################
# 基本設定
################################################################################

echo ""
log_info "[3/8] 基本設定（メモリ・CPU・VRAM）"

VBoxManage modifyvm "$VM_NAME" \
    --memory $VM_MEMORY \
    --cpus $VM_CPUS \
    --vram $VM_VRAM \
    --graphicscontroller vmsvga \
    --acpi on \
    --ioapic on \
    --pae on \
    --hwvirtex on \
    --nestedpaging on

log_success "基本設定完了 (RAM: ${VM_MEMORY}MB, CPU: ${VM_CPUS}コア, VRAM: ${VM_VRAM}MB)"

################################################################################
# UEFI/セキュアブート/TPM設定（Windows 11要件）
################################################################################

echo ""
log_info "[4/8] UEFI/セキュアブート/TPM設定"

# UEFI有効化
VBoxManage modifyvm "$VM_NAME" --firmware efi

log_success "UEFI有効化完了"

# セキュアブート有効化（VirtualBox 7.0以降）
if VBoxManage modifyvm "$VM_NAME" --secure-boot on 2>/dev/null; then
    log_success "セキュアブート有効化完了"
else
    log_warning "セキュアブート設定失敗（VirtualBox 7.0以降が必要）"
fi

# TPM 2.0設定（VirtualBox 7.0以降）
if VBoxManage modifyvm "$VM_NAME" --tpm-type 2.0 2>/dev/null; then
    log_success "TPM 2.0有効化完了"
else
    log_warning "TPM設定失敗（VirtualBox 7.0以降が必要）"
    log_info "Windows 11インストール時にTPMチェックをバイパスする必要があります"
fi

################################################################################
# ストレージ設定
################################################################################

echo ""
log_info "[5/8] ストレージ設定"

# SATAコントローラー追加
VBoxManage storagectl "$VM_NAME" \
    --name "SATA Controller" \
    --add sata \
    --controller IntelAhci \
    --portcount 4 \
    --bootable on

log_success "SATAコントローラー追加完了"

# 仮想ディスク作成
VBoxManage createhd \
    --filename "$VM_DIR/$VM_NAME.vdi" \
    --size $VM_DISK_SIZE \
    --format VDI \
    --variant Standard

log_success "仮想ディスク作成完了 (${VM_DISK_SIZE}MB)"

# ディスクをアタッチ
VBoxManage storageattach "$VM_NAME" \
    --storagectl "SATA Controller" \
    --port 0 \
    --device 0 \
    --type hdd \
    --medium "$VM_DIR/$VM_NAME.vdi"

log_success "ディスクアタッチ完了"

# ISOをアタッチ
VBoxManage storageattach "$VM_NAME" \
    --storagectl "SATA Controller" \
    --port 1 \
    --device 0 \
    --type dvddrive \
    --medium "$ISO_PATH"

log_success "ISOアタッチ完了: $ISO_PATH"

################################################################################
# ネットワーク設定
################################################################################

echo ""
log_info "[6/8] ネットワーク設定"

VBoxManage modifyvm "$VM_NAME" \
    --nic1 "$VM_NETWORK" \
    --nictype1 82540EM \
    --cableconnected1 on

log_success "ネットワーク設定完了 (タイプ: $VM_NETWORK)"

################################################################################
# その他の設定
################################################################################

echo ""
log_info "[7/8] その他の設定"

# クリップボード共有
VBoxManage modifyvm "$VM_NAME" --clipboard bidirectional

# ドラッグ&ドロップ
VBoxManage modifyvm "$VM_NAME" --draganddrop bidirectional

# USB 2.0/3.0サポート（Extension Pack必要）
VBoxManage modifyvm "$VM_NAME" --usb on
if VBoxManage modifyvm "$VM_NAME" --usbxhci on 2>/dev/null; then
    log_success "USB 3.0有効化完了"
else
    log_warning "USB 3.0設定失敗（VirtualBox Extension Pack推奨）"
fi

# オーディオ設定
VBoxManage modifyvm "$VM_NAME" --audio pulse --audiocontroller hda

log_success "その他の設定完了"

################################################################################
# 設定サマリー表示
################################################################################

echo ""
log_info "[8/8] 設定サマリー"

print_separator
cat << EOF
VM名:           $VM_NAME
OS種類:         Windows 11 (64-bit)
メモリ:         ${VM_MEMORY}MB ($(echo "scale=1; $VM_MEMORY/1024" | bc)GB)
CPU:            ${VM_CPUS}コア
VRAM:           ${VM_VRAM}MB
ディスク:       ${VM_DISK_SIZE}MB ($(echo "scale=0; $VM_DISK_SIZE/1024" | bc)GB)
ファームウェア: UEFI
TPM:            2.0
セキュアブート: 有効
ネットワーク:   $VM_NETWORK
ISOイメージ:    $ISO_PATH
保存場所:       $VM_DIR
EOF
print_separator

################################################################################
# VM起動確認
################################################################################

echo ""
log_success "仮想マシン作成完了！"
echo ""
read -p "仮想マシンを起動しますか？ (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "仮想マシンを起動中..."

    # GUI起動
    VBoxManage startvm "$VM_NAME" --type gui

    log_success "仮想マシン起動完了"
    echo ""
    log_info "Windows 11インストールを開始してください"
    log_info "インストール後、以下のコマンドでVMを管理できます:"
    echo ""
    echo "  # VMを起動"
    echo "  VBoxManage startvm \"$VM_NAME\" --type gui"
    echo ""
    echo "  # VMをシャットダウン"
    echo "  VBoxManage controlvm \"$VM_NAME\" acpipowerbutton"
    echo ""
    echo "  # VMを強制停止"
    echo "  VBoxManage controlvm \"$VM_NAME\" poweroff"
    echo ""
    echo "  # VM情報表示"
    echo "  VBoxManage showvminfo \"$VM_NAME\""
    echo ""
    echo "  # VMを削除"
    echo "  VBoxManage unregistervm \"$VM_NAME\" --delete"
    echo ""
else
    log_info "後で以下のコマンドで起動できます:"
    echo ""
    echo "  VBoxManage startvm \"$VM_NAME\" --type gui"
    echo ""
fi

################################################################################
# VBoxManage スナップショット作成補助
################################################################################

cat << 'EOF'

[オプション] スナップショット機能の使い方

Windowsインストール後、スナップショットを作成しておくと便利です：

# スナップショット作成
VBoxManage snapshot "$VM_NAME" take "CleanInstall" --description "Windows 11 クリーンインストール直後"

# スナップショット一覧
VBoxManage snapshot "$VM_NAME" list

# スナップショット復元
VBoxManage snapshot "$VM_NAME" restore "CleanInstall"

EOF

################################################################################
# PXEブート設定（オプション）
################################################################################

cat << 'EOF'

[オプション] PXEブート設定

DRBLサーバからの自動展開をテストする場合：

# ブートオーダー変更（ネットワークブート優先）
VBoxManage modifyvm "$VM_NAME" --boot1 net --boot2 disk --boot3 none --boot4 none

# ネットワークをブリッジモードに変更
VBoxManage modifyvm "$VM_NAME" --nic1 bridged --bridgeadapter1 eth0

EOF

print_separator
log_success "すべての処理が完了しました"
print_separator
