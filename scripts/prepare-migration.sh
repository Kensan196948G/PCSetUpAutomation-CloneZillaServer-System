#!/bin/bash

################################################################################
# prepare-migration.sh
#
# 環境移行準備スクリプト
# 現在のファイル構造をバックアップし、development/production環境への移行を準備します
#
# 使用例:
#   ./scripts/prepare-migration.sh             # 通常実行
#   ./scripts/prepare-migration.sh --dry-run   # dry-runモード（実際には移動しない）
#   ./scripts/prepare-migration.sh --backup    # バックアップのみ実行
#
# 作成者: PC Setup Automation Team
# 最終更新: 2025-11-17
################################################################################

set -e  # エラー時に終了
set -u  # 未定義変数使用時に終了

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# プロジェクトルート取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# ログファイル設定
LOG_DIR="${PROJECT_ROOT}/logs"
LOG_FILE="${LOG_DIR}/migration-$(date +%Y%m%d-%H%M%S).log"

# バックアップディレクトリ
BACKUP_DIR="${PROJECT_ROOT}/backups/migration-$(date +%Y%m%d-%H%M%S)"

# フラグ
DRY_RUN=0
BACKUP_ONLY=0

################################################################################
# 関数定義
################################################################################

# ログ出力関数
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    case $level in
        INFO)
            echo -e "${GREEN}[INFO]${NC} ${timestamp} - ${message}" | tee -a "$LOG_FILE"
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} ${timestamp} - ${message}" | tee -a "$LOG_FILE"
            ;;
        ERROR)
            echo -e "${RED}[ERROR]${NC} ${timestamp} - ${message}" | tee -a "$LOG_FILE"
            ;;
        DEBUG)
            echo -e "${BLUE}[DEBUG]${NC} ${timestamp} - ${message}" | tee -a "$LOG_FILE"
            ;;
    esac
}

# ヘルプメッセージ表示
show_help() {
    cat << EOF
使用方法: $0 [OPTIONS]

環境移行準備スクリプト

OPTIONS:
    --dry-run       実際には移動せず、移行計画のみ表示
    --backup        バックアップのみ実行（移行は行わない）
    -h, --help      このヘルプメッセージを表示

例:
    $0                      # 通常実行
    $0 --dry-run            # dry-runモード
    $0 --backup             # バックアップのみ

EOF
}

# 引数解析
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --backup)
                BACKUP_ONLY=1
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log ERROR "不明なオプション: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 初期化
initialize() {
    log INFO "=== 移行準備スクリプト開始 ==="
    log INFO "プロジェクトルート: ${PROJECT_ROOT}"

    if [[ $DRY_RUN -eq 1 ]]; then
        log WARN "DRY-RUNモード: 実際の変更は行いません"
    fi

    # ログディレクトリ作成
    mkdir -p "$LOG_DIR"

    # バックアップディレクトリ作成
    mkdir -p "$BACKUP_DIR"

    log INFO "ログファイル: ${LOG_FILE}"
    log INFO "バックアップディレクトリ: ${BACKUP_DIR}"
}

# 移行前チェック
pre_migration_check() {
    log INFO "=== 移行前チェック実行 ==="

    local errors=0

    # Flask動作確認
    log INFO "Flaskインストール確認中..."
    if python3 -c "import flask" 2>/dev/null; then
        log INFO "Flask: OK"
    else
        log WARN "Flask: 未インストール（pip install flask が必要）"
        ((errors++))
    fi

    # データベース整合性確認
    log INFO "データベース確認中..."
    if [[ -f "${PROJECT_ROOT}/pc_setup.db" ]]; then
        log INFO "データベースファイル: 存在"

        # SQLite3でテーブル確認
        if command -v sqlite3 &> /dev/null; then
            local tables=$(sqlite3 "${PROJECT_ROOT}/pc_setup.db" ".tables" 2>/dev/null || echo "")
            if [[ -n "$tables" ]]; then
                log INFO "データベーステーブル: ${tables}"
            else
                log WARN "データベーステーブルが見つかりません"
            fi
        fi
    else
        log WARN "データベースファイルが見つかりません"
    fi

    # 設定ファイル存在確認
    log INFO "設定ファイル確認中..."
    if [[ -f "${PROJECT_ROOT}/.env.example" ]]; then
        log INFO ".env.example: 存在"
    else
        log WARN ".env.example: 見つかりません"
        ((errors++))
    fi

    # 必須ディレクトリ確認
    log INFO "必須ディレクトリ確認中..."
    local required_dirs=("flask-app" "powershell-scripts" "drbl-server" "tests")
    for dir in "${required_dirs[@]}"; do
        if [[ -d "${PROJECT_ROOT}/${dir}" ]]; then
            log INFO "${dir}: 存在"
        else
            log ERROR "${dir}: 見つかりません"
            ((errors++))
        fi
    done

    # ディスク容量確認
    log INFO "ディスク容量確認中..."
    local available_space=$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $4}')
    log INFO "利用可能容量: ${available_space}"

    # チェック結果
    if [[ $errors -eq 0 ]]; then
        log INFO "移行前チェック: すべて正常"
        return 0
    else
        log WARN "移行前チェック: ${errors}個の警告/エラーがあります"
        return 1
    fi
}

# バックアップ実行
create_backup() {
    log INFO "=== バックアップ作成開始 ==="

    # 重要ファイルのバックアップ
    local files_to_backup=(
        "flask-app"
        "powershell-scripts"
        "drbl-server"
        "tests"
        "docs"
        "migrations"
        "odj-files"
        ".env.example"
        "README.md"
        "CLAUDE.md"
        "pc_setup.db"
    )

    for item in "${files_to_backup[@]}"; do
        local source="${PROJECT_ROOT}/${item}"
        if [[ -e "$source" ]]; then
            log INFO "バックアップ中: ${item}"
            if [[ $DRY_RUN -eq 0 ]]; then
                cp -r "$source" "$BACKUP_DIR/" 2>&1 | tee -a "$LOG_FILE"
            else
                log DEBUG "DRY-RUN: cp -r ${source} ${BACKUP_DIR}/"
            fi
        else
            log WARN "スキップ（存在しない）: ${item}"
        fi
    done

    # バックアップ完了メッセージ
    if [[ $DRY_RUN -eq 0 ]]; then
        local backup_size=$(du -sh "$BACKUP_DIR" | cut -f1)
        log INFO "バックアップ完了: ${BACKUP_DIR} (サイズ: ${backup_size})"
    else
        log DEBUG "DRY-RUN: バックアップスキップ"
    fi
}

# 移行計画出力
show_migration_plan() {
    log INFO "=== 移行計画 ==="

    cat << EOF | tee -a "$LOG_FILE"

【移行対象ファイル構成】

1. 開発環境 (development/)
   - flask-app/ → development/flask-app/
   - tests/ → development/tests/
   - .env.example → development/.env.dev
   - pc_setup.db → development/pc_setup.db (開発用DB)

2. 本番環境 (production/)
   - flask-app/ → production/flask-app/
   - migrations/ → production/migrations/
   - odj-files/ → production/odj-files/
   - .env.example → production/.env.prod (編集必要)

3. 共通リソース（移動しない）
   - powershell-scripts/ (そのまま)
   - drbl-server/ (そのまま)
   - docs/ (そのまま)
   - media/ (そのまま)
   - .claude/ (そのまま)

4. 新規作成ディレクトリ
   - development/scripts/
   - production/scripts/
   - production/nginx/
   - production/systemd/

【実行手順】
1. バックアップ完了確認
2. development/, production/ ディレクトリ作成
3. ファイル移動実行
4. 環境別設定ファイル作成
5. 各環境の初期化スクリプト実行

EOF
}

# 移行実行
execute_migration() {
    if [[ $BACKUP_ONLY -eq 1 ]]; then
        log INFO "バックアップのみモード: 移行はスキップします"
        return 0
    fi

    log INFO "=== 移行実行 ==="

    # development/, production/ ディレクトリ作成
    log INFO "環境ディレクトリ作成中..."
    if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "${PROJECT_ROOT}/development"/{scripts,tests}
        mkdir -p "${PROJECT_ROOT}/production"/{scripts,nginx,systemd}
        log INFO "ディレクトリ作成完了"
    else
        log DEBUG "DRY-RUN: mkdir -p development/, production/"
    fi

    log WARN "実際のファイル移動は、各環境の初期化スクリプト実行時に行われます"
    log INFO "次のステップ:"
    log INFO "  1. ./development/scripts/init-dev-env.sh を実行"
    log INFO "  2. ./production/scripts/init-prod-env.sh を実行"
}

# クリーンアップ
cleanup() {
    log INFO "=== クリーンアップ ==="

    # 一時ファイル削除など（必要に応じて）
    log INFO "クリーンアップ完了"
}

# メイン処理
main() {
    parse_args "$@"
    initialize

    # 移行前チェック
    if ! pre_migration_check; then
        log WARN "チェックで警告がありましたが、続行します"
    fi

    # バックアップ作成
    create_backup

    # 移行計画表示
    show_migration_plan

    # 移行実行
    execute_migration

    # クリーンアップ
    cleanup

    log INFO "=== 移行準備スクリプト完了 ==="

    if [[ $DRY_RUN -eq 1 ]]; then
        log WARN "DRY-RUNモードで実行されました。実際の変更は行われていません。"
    fi

    log INFO "ログファイル: ${LOG_FILE}"
    log INFO "バックアップ: ${BACKUP_DIR}"
}

# スクリプト実行
main "$@"
