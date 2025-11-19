#!/bin/bash

################################################################################
# Windows 11 ISO検証スクリプト
#
# 概要: Windows11.isoファイルの整合性とマウント可否を検証
# 用途: 開発環境での事前検証、マスターイメージ作成前の確認
#
# 実行方法:
#   ./validate-windows-iso.sh [ISO_FILE_PATH]
#
# 例:
#   ./validate-windows-iso.sh /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/media/Windows11.iso
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

# セパレーター表示
print_separator() {
    echo "================================================================================"
}

# 検証結果サマリー
declare -a RESULTS=()

add_result() {
    local status=$1
    local message=$2
    RESULTS+=("$status|$message")
}

# ISOファイルパス（引数 or デフォルト）
ISO_FILE="${1:-/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/media/Windows11.iso}"
MOUNT_POINT="/tmp/win11_iso_mount_$$"
REPORT_FILE="./iso_validation_report_$(date +%Y%m%d_%H%M%S).txt"

# レポートヘッダー
{
    echo "Windows 11 ISO検証レポート"
    echo "生成日時: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "ISOファイル: $ISO_FILE"
    print_separator
} > "$REPORT_FILE"

print_separator
log_info "Windows 11 ISO検証を開始します"
log_info "ISOファイル: $ISO_FILE"
print_separator

################################################################################
# 1. ISOファイルの存在確認
################################################################################
echo ""
log_info "[1/7] ISOファイルの存在確認"

if [ ! -f "$ISO_FILE" ]; then
    log_error "ISOファイルが見つかりません: $ISO_FILE"
    add_result "FAIL" "ISOファイル存在確認"
    exit 1
else
    log_success "ISOファイルが存在します"
    add_result "PASS" "ISOファイル存在確認"
fi

################################################################################
# 2. ファイルサイズチェック
################################################################################
echo ""
log_info "[2/7] ファイルサイズチェック"

FILE_SIZE=$(stat -c%s "$ISO_FILE")
FILE_SIZE_GB=$(echo "scale=2; $FILE_SIZE / 1024 / 1024 / 1024" | bc)
MIN_SIZE=$((5 * 1024 * 1024 * 1024))  # 5GB

log_info "ファイルサイズ: ${FILE_SIZE_GB}GB"

if [ "$FILE_SIZE" -lt "$MIN_SIZE" ]; then
    log_warning "ファイルサイズが小さすぎる可能性があります (< 5GB)"
    add_result "WARN" "ファイルサイズ: ${FILE_SIZE_GB}GB (警告: 5GB未満)"
else
    log_success "ファイルサイズは正常範囲内です (${FILE_SIZE_GB}GB)"
    add_result "PASS" "ファイルサイズ: ${FILE_SIZE_GB}GB"
fi

echo "ファイルサイズ: ${FILE_SIZE_GB}GB" >> "$REPORT_FILE"

################################################################################
# 3. ファイルタイプ確認
################################################################################
echo ""
log_info "[3/7] ファイルタイプ確認"

FILE_TYPE=$(file "$ISO_FILE")
log_info "ファイルタイプ: $FILE_TYPE"

if echo "$FILE_TYPE" | grep -q "ISO 9660"; then
    log_success "正しいISO 9660フォーマットです"
    add_result "PASS" "ファイルタイプ: ISO 9660"
else
    log_error "ISO 9660フォーマットではありません"
    add_result "FAIL" "ファイルタイプ: 不正なフォーマット"
fi

echo "ファイルタイプ: $FILE_TYPE" >> "$REPORT_FILE"

################################################################################
# 4. チェックサム計算（SHA256）
################################################################################
echo ""
log_info "[4/7] SHA256チェックサム計算中... (数分かかる場合があります)"

SHA256_HASH=$(sha256sum "$ISO_FILE" | awk '{print $1}')
log_success "SHA256: $SHA256_HASH"
add_result "INFO" "SHA256チェックサム算出完了"

{
    echo ""
    echo "SHA256チェックサム:"
    echo "$SHA256_HASH"
} >> "$REPORT_FILE"

# チェックサムファイルが存在する場合は検証
CHECKSUM_FILE="${ISO_FILE}.sha256"
if [ -f "$CHECKSUM_FILE" ]; then
    log_info "チェックサムファイルが見つかりました。検証中..."
    EXPECTED_HASH=$(cat "$CHECKSUM_FILE" | awk '{print $1}')

    if [ "$SHA256_HASH" == "$EXPECTED_HASH" ]; then
        log_success "チェックサム一致: ISOファイルは改ざんされていません"
        add_result "PASS" "SHA256チェックサム検証"
    else
        log_error "チェックサム不一致: ISOファイルが破損または改ざんされている可能性があります"
        add_result "FAIL" "SHA256チェックサム検証"
    fi
else
    log_warning "チェックサムファイルが見つかりません (${CHECKSUM_FILE})"
    log_info "上記SHA256ハッシュを保存することをお勧めします:"
    log_info "  echo '$SHA256_HASH' > ${CHECKSUM_FILE}"
    add_result "INFO" "チェックサムファイル未存在"
fi

################################################################################
# 5. ISOマウントテスト
################################################################################
echo ""
log_info "[5/7] ISOマウントテスト"

# マウントポイント作成
mkdir -p "$MOUNT_POINT"

# マウント実行（sudo必要な場合あり）
if mount -o loop,ro "$ISO_FILE" "$MOUNT_POINT" 2>/dev/null || sudo mount -o loop,ro "$ISO_FILE" "$MOUNT_POINT" 2>/dev/null; then
    log_success "ISOマウント成功: $MOUNT_POINT"
    add_result "PASS" "ISOマウント"

    # マウント内容確認
    log_info "マウント内容:"
    ls -lh "$MOUNT_POINT" | head -20

    ################################################################################
    # 6. Windows 11バージョン情報抽出
    ################################################################################
    echo ""
    log_info "[6/7] Windows 11バージョン情報抽出"

    # sources/install.wimまたはinstall.esdの存在確認
    if [ -f "$MOUNT_POINT/sources/install.wim" ]; then
        WIM_FILE="$MOUNT_POINT/sources/install.wim"
        log_info "install.wimファイルが見つかりました"
        add_result "PASS" "install.wim存在確認"

        # wimlib-imagexがインストールされている場合、詳細情報を抽出
        if command -v wiminfo &> /dev/null; then
            log_info "WIMイメージ情報を抽出中..."
            WIM_INFO=$(wiminfo "$WIM_FILE" 1 2>/dev/null | grep -E "Display Name|Display Description|Architecture|Build" || echo "情報抽出失敗")
            echo "$WIM_INFO"
            echo "" >> "$REPORT_FILE"
            echo "Windows 11バージョン情報:" >> "$REPORT_FILE"
            echo "$WIM_INFO" >> "$REPORT_FILE"
        else
            log_warning "wimlib-imagexがインストールされていません"
            log_info "詳細情報を取得するには: sudo apt install wimtools"
            add_result "INFO" "wimlib-imagex未インストール"
        fi

    elif [ -f "$MOUNT_POINT/sources/install.esd" ]; then
        ESD_FILE="$MOUNT_POINT/sources/install.esd"
        log_info "install.esdファイルが見つかりました（圧縮版）"
        add_result "PASS" "install.esd存在確認"
    else
        log_error "install.wimまたはinstall.esdが見つかりません"
        add_result "FAIL" "インストールイメージ存在確認"
    fi

    # boot.wimの確認
    if [ -f "$MOUNT_POINT/sources/boot.wim" ]; then
        log_success "boot.wimファイルが存在します"
        add_result "PASS" "boot.wim存在確認"
    else
        log_warning "boot.wimファイルが見つかりません"
        add_result "WARN" "boot.wim存在確認"
    fi

    ################################################################################
    # 7. 必須ファイル・フォルダ確認
    ################################################################################
    echo ""
    log_info "[7/7] 必須ファイル・フォルダ確認"

    REQUIRED_ITEMS=(
        "sources"
        "boot"
        "efi"
        "bootmgr"
        "setup.exe"
    )

    for item in "${REQUIRED_ITEMS[@]}"; do
        if [ -e "$MOUNT_POINT/$item" ]; then
            log_success "✓ $item"
            add_result "PASS" "必須項目: $item"
        else
            log_warning "✗ $item (見つかりません)"
            add_result "WARN" "必須項目: $item (未検出)"
        fi
    done

    # アンマウント
    echo ""
    log_info "ISOをアンマウント中..."
    sudo umount "$MOUNT_POINT" 2>/dev/null || umount "$MOUNT_POINT" 2>/dev/null
    rmdir "$MOUNT_POINT"
    log_success "アンマウント完了"

else
    log_error "ISOマウント失敗"
    add_result "FAIL" "ISOマウント"
    rmdir "$MOUNT_POINT"
fi

################################################################################
# 検証結果サマリー出力
################################################################################
echo ""
print_separator
log_info "検証結果サマリー"
print_separator

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
INFO_COUNT=0

{
    echo ""
    echo "検証結果サマリー:"
    echo "----------------"
} >> "$REPORT_FILE"

for result in "${RESULTS[@]}"; do
    STATUS=$(echo "$result" | cut -d'|' -f1)
    MESSAGE=$(echo "$result" | cut -d'|' -f2)

    case $STATUS in
        PASS)
            echo -e "${GREEN}[PASS]${NC} $MESSAGE"
            echo "[PASS] $MESSAGE" >> "$REPORT_FILE"
            ((PASS_COUNT++))
            ;;
        FAIL)
            echo -e "${RED}[FAIL]${NC} $MESSAGE"
            echo "[FAIL] $MESSAGE" >> "$REPORT_FILE"
            ((FAIL_COUNT++))
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} $MESSAGE"
            echo "[WARN] $MESSAGE" >> "$REPORT_FILE"
            ((WARN_COUNT++))
            ;;
        INFO)
            echo -e "${BLUE}[INFO]${NC} $MESSAGE"
            echo "[INFO] $MESSAGE" >> "$REPORT_FILE"
            ((INFO_COUNT++))
            ;;
    esac
done

echo ""
print_separator
log_info "統計: PASS=${PASS_COUNT}, FAIL=${FAIL_COUNT}, WARN=${WARN_COUNT}, INFO=${INFO_COUNT}"
print_separator

{
    echo ""
    echo "統計: PASS=${PASS_COUNT}, FAIL=${FAIL_COUNT}, WARN=${WARN_COUNT}, INFO=${INFO_COUNT}"
    print_separator
} >> "$REPORT_FILE"

# 最終判定
echo ""
if [ $FAIL_COUNT -eq 0 ]; then
    log_success "検証完了: ISOファイルは正常です"
    echo "総合判定: 合格" >> "$REPORT_FILE"
    EXIT_CODE=0
else
    log_error "検証完了: ${FAIL_COUNT}件のエラーが検出されました"
    echo "総合判定: 不合格 (${FAIL_COUNT}件のエラー)" >> "$REPORT_FILE"
    EXIT_CODE=1
fi

log_info "詳細レポート: $REPORT_FILE"
echo ""

exit $EXIT_CODE
