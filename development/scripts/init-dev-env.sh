#!/bin/bash

################################################################################
# init-dev-env.sh
#
# 開発環境初期化スクリプト
# Python仮想環境の作成、依存パッケージのインストール、開発用データベースの初期化を実行
#
# 使用例:
#   ./development/scripts/init-dev-env.sh           # 通常実行
#   ./development/scripts/init-dev-env.sh --reset   # 既存環境をリセットして再構築
#   ./development/scripts/init-dev-env.sh --test    # テストデータも投入
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
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# プロジェクトルート取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$DEV_ROOT")"

# ログファイル設定
LOG_DIR="${PROJECT_ROOT}/logs"
LOG_FILE="${LOG_DIR}/init-dev-$(date +%Y%m%d-%H%M%S).log"

# フラグ
RESET_ENV=0
LOAD_TEST_DATA=0

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
        SUCCESS)
            echo -e "${GREEN}[SUCCESS]${NC} ${timestamp} - ${message}" | tee -a "$LOG_FILE"
            ;;
    esac
}

# ヘルプメッセージ表示
show_help() {
    cat << EOF
使用方法: $0 [OPTIONS]

開発環境初期化スクリプト

OPTIONS:
    --reset         既存環境をリセットして再構築
    --test          テストデータも投入
    -h, --help      このヘルプメッセージを表示

例:
    $0                  # 通常実行
    $0 --reset          # 環境リセット
    $0 --test           # テストデータ投入

EOF
}

# 引数解析
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --reset)
                RESET_ENV=1
                shift
                ;;
            --test)
                LOAD_TEST_DATA=1
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

# バナー表示
show_banner() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  🖥️  PC Setup Automation - 開発環境初期化スクリプト${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# 初期化
initialize() {
    show_banner
    log INFO "=== 開発環境初期化開始 ==="
    log INFO "プロジェクトルート: ${PROJECT_ROOT}"
    log INFO "開発環境ルート: ${DEV_ROOT}"

    if [[ $RESET_ENV -eq 1 ]]; then
        log WARN "リセットモード: 既存環境を削除します"
    fi

    # ログディレクトリ作成
    mkdir -p "$LOG_DIR"

    log INFO "ログファイル: ${LOG_FILE}"
}

# 前提条件チェック
check_prerequisites() {
    log INFO "=== 前提条件チェック ==="

    local errors=0

    # Python3確認
    if command -v python3 &> /dev/null; then
        local python_version=$(python3 --version 2>&1 | awk '{print $2}')
        log INFO "Python: ${python_version}"

        # バージョン確認（3.10以上）
        local major=$(echo "$python_version" | cut -d. -f1)
        local minor=$(echo "$python_version" | cut -d. -f2)
        if [[ $major -lt 3 ]] || [[ $major -eq 3 && $minor -lt 10 ]]; then
            log ERROR "Python 3.10以上が必要です (現在: ${python_version})"
            ((errors++))
        fi
    else
        log ERROR "Python3がインストールされていません"
        ((errors++))
    fi

    # pip確認
    if command -v pip3 &> /dev/null; then
        log INFO "pip3: インストール済み"
    else
        log ERROR "pip3がインストールされていません"
        ((errors++))
    fi

    # venv確認
    if python3 -m venv --help &> /dev/null; then
        log INFO "venv: 利用可能"
    else
        log ERROR "python3-venvがインストールされていません"
        log INFO "インストールコマンド: sudo apt install python3-venv"
        ((errors++))
    fi

    # SQLite3確認
    if command -v sqlite3 &> /dev/null; then
        local sqlite_version=$(sqlite3 --version | awk '{print $1}')
        log INFO "SQLite3: ${sqlite_version}"
    else
        log WARN "SQLite3がインストールされていません（推奨）"
    fi

    # ディスク容量確認
    local available_gb=$(df -BG "$DEV_ROOT" | awk 'NR==2 {print $4}' | sed 's/G//')
    log INFO "利用可能ディスク容量: ${available_gb}GB"
    if [[ $available_gb -lt 5 ]]; then
        log WARN "ディスク容量が5GB未満です"
    fi

    if [[ $errors -gt 0 ]]; then
        log ERROR "前提条件チェック失敗: ${errors}個のエラー"
        exit 1
    fi

    log SUCCESS "前提条件チェック: すべて正常"
}

# 既存環境のクリーンアップ
cleanup_existing_env() {
    if [[ $RESET_ENV -eq 0 ]]; then
        return 0
    fi

    log INFO "=== 既存環境のクリーンアップ ==="

    # 仮想環境削除
    if [[ -d "${DEV_ROOT}/venv" ]]; then
        log INFO "既存の仮想環境を削除中..."
        rm -rf "${DEV_ROOT}/venv"
        log INFO "仮想環境削除完了"
    fi

    # データベース削除
    if [[ -f "${DEV_ROOT}/pc_setup.db" ]]; then
        log INFO "既存のデータベースを削除中..."
        rm -f "${DEV_ROOT}/pc_setup.db"
        log INFO "データベース削除完了"
    fi

    # __pycache__ 削除
    if [[ -d "${DEV_ROOT}/flask-app" ]]; then
        log INFO "キャッシュファイルを削除中..."
        find "${DEV_ROOT}/flask-app" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
        find "${DEV_ROOT}/flask-app" -type f -name "*.pyc" -delete 2>/dev/null || true
        log INFO "キャッシュ削除完了"
    fi

    log SUCCESS "クリーンアップ完了"
}

# ディレクトリ構造作成
create_directory_structure() {
    log INFO "=== ディレクトリ構造作成 ==="

    # 必要なディレクトリ作成
    mkdir -p "${DEV_ROOT}/flask-app"
    mkdir -p "${DEV_ROOT}/tests"
    mkdir -p "${DEV_ROOT}/logs"
    mkdir -p "${DEV_ROOT}/uploads"

    log INFO "ディレクトリ構造作成完了"
}

# Python仮想環境作成
create_virtual_environment() {
    log INFO "=== Python仮想環境作成 ==="

    if [[ -d "${DEV_ROOT}/venv" ]] && [[ $RESET_ENV -eq 0 ]]; then
        log WARN "仮想環境は既に存在します（スキップ）"
        return 0
    fi

    log INFO "仮想環境を作成中..."
    python3 -m venv "${DEV_ROOT}/venv"

    log INFO "仮想環境のアクティベート確認中..."
    source "${DEV_ROOT}/venv/bin/activate"

    # pip更新
    log INFO "pipを更新中..."
    pip install --upgrade pip --quiet

    log SUCCESS "仮想環境作成完了"
}

# 依存パッケージインストール
install_dependencies() {
    log INFO "=== 依存パッケージインストール ==="

    # 仮想環境をアクティベート
    source "${DEV_ROOT}/venv/bin/activate"

    # requirements.txt確認
    local requirements_file="${PROJECT_ROOT}/flask-app/requirements.txt"
    if [[ ! -f "$requirements_file" ]]; then
        log WARN "requirements.txtが見つかりません。基本パッケージのみインストールします"

        # 基本パッケージインストール
        log INFO "基本パッケージをインストール中..."
        pip install Flask Flask-SQLAlchemy Flask-Migrate python-dotenv pytest pytest-cov --quiet
    else
        log INFO "requirements.txtからパッケージをインストール中..."
        pip install -r "$requirements_file" --quiet
    fi

    # インストール済みパッケージ表示
    log INFO "インストール済みパッケージ:"
    pip list | grep -E "(Flask|pytest|SQLAlchemy)" | while read line; do
        log DEBUG "  $line"
    done

    log SUCCESS "依存パッケージインストール完了"
}

# 環境変数ファイル作成
create_env_file() {
    log INFO "=== 環境変数ファイル作成 ==="

    local env_file="${DEV_ROOT}/.env.dev"

    if [[ -f "$env_file" ]]; then
        log WARN ".env.devは既に存在します（スキップ）"
        return 0
    fi

    log INFO ".env.devを作成中..."

    cat > "$env_file" << 'EOF'
# 開発環境設定ファイル
# 作成日: $(date +%Y-%m-%d)

# Flask設定
FLASK_APP=app.py
FLASK_ENV=development
FLASK_DEBUG=1
SECRET_KEY=dev-secret-key-change-in-production

# データベース設定（開発環境ではSQLite使用）
DATABASE_URL=sqlite:///pc_setup.db

# サーバ設定
HOST=0.0.0.0
PORT=5000

# ログレベル
LOG_LEVEL=DEBUG

# その他の設定
TESTING=False
EOF

    log SUCCESS ".env.dev作成完了"
}

# データベース初期化
initialize_database() {
    log INFO "=== データベース初期化 ==="

    # 仮想環境をアクティベート
    source "${DEV_ROOT}/venv/bin/activate"

    # Flask-Migrateでマイグレーション実行
    local flask_app_dir="${PROJECT_ROOT}/flask-app"

    if [[ ! -d "$flask_app_dir" ]]; then
        log WARN "flask-appディレクトリが見つかりません。データベース初期化をスキップします"
        return 0
    fi

    cd "$flask_app_dir"

    # データベースファイル作成位置
    export DATABASE_URL="sqlite:///${DEV_ROOT}/pc_setup.db"

    # Flask初期化確認
    if [[ -f "app.py" ]]; then
        log INFO "データベースを初期化中..."

        # Flaskコマンドでデータベース作成
        python3 << 'PYTHON_SCRIPT'
import sys
sys.path.insert(0, '.')

try:
    from app import app, db
    with app.app_context():
        db.create_all()
        print("データベーステーブル作成完了")
except Exception as e:
    print(f"エラー: {e}")
PYTHON_SCRIPT

        log SUCCESS "データベース初期化完了"
    else
        log WARN "app.pyが見つかりません。手動でデータベースを初期化してください"
    fi

    cd "$DEV_ROOT"
}

# テストデータ投入
load_test_data() {
    if [[ $LOAD_TEST_DATA -eq 0 ]]; then
        return 0
    fi

    log INFO "=== テストデータ投入 ==="

    # 仮想環境をアクティベート
    source "${DEV_ROOT}/venv/bin/activate"

    export DATABASE_URL="sqlite:///${DEV_ROOT}/pc_setup.db"

    # テストデータスクリプト実行
    python3 << 'PYTHON_SCRIPT'
import sys
import os
from datetime import datetime

sys.path.insert(0, './flask-app')

try:
    from app import app, db
    from models.pc_master import PCMaster
    from models.setup_log import SetupLog

    with app.app_context():
        # テストPC登録
        test_pcs = [
            {"serial": "TEST001", "pcname": "20251117M", "odj_path": "/odj/20251117M.txt"},
            {"serial": "TEST002", "pcname": "20251118M", "odj_path": "/odj/20251118M.txt"},
            {"serial": "TEST003", "pcname": "20251119M", "odj_path": "/odj/20251119M.txt"},
        ]

        for pc_data in test_pcs:
            pc = PCMaster(**pc_data)
            db.session.add(pc)

        # テストログ登録
        test_log = SetupLog(
            serial="TEST001",
            pcname="20251117M",
            status="completed",
            logs="テストセットアップ完了"
        )
        db.session.add(test_log)

        db.session.commit()
        print(f"テストデータ投入完了: {len(test_pcs)}台のPC情報")

except Exception as e:
    print(f"エラー: {e}")
PYTHON_SCRIPT

    log SUCCESS "テストデータ投入完了"
}

# 開発サーバ起動確認
verify_flask_server() {
    log INFO "=== Flask開発サーバ起動確認 ==="

    # 仮想環境をアクティベート
    source "${DEV_ROOT}/venv/bin/activate"

    local flask_app_dir="${PROJECT_ROOT}/flask-app"

    if [[ ! -f "${flask_app_dir}/app.py" ]]; then
        log WARN "app.pyが見つかりません。起動確認をスキップします"
        return 0
    fi

    cd "$flask_app_dir"
    export FLASK_APP=app.py
    export FLASK_ENV=development

    log INFO "Flask設定確認中..."
    if flask --version &> /dev/null; then
        log SUCCESS "Flask: 正常"
    else
        log ERROR "Flaskが正しくインストールされていません"
        return 1
    fi

    cd "$DEV_ROOT"
}

# 完了メッセージ
show_completion_message() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✅ 開発環境初期化が完了しました！${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}次のステップ:${NC}"
    echo ""
    echo -e "  1. 仮想環境をアクティベート:"
    echo -e "     ${BLUE}cd ${DEV_ROOT}${NC}"
    echo -e "     ${BLUE}source venv/bin/activate${NC}"
    echo ""
    echo -e "  2. Flask開発サーバを起動:"
    echo -e "     ${BLUE}cd flask-app${NC}"
    echo -e "     ${BLUE}flask run --host=0.0.0.0 --port=5000${NC}"
    echo ""
    echo -e "  3. ブラウザでアクセス:"
    echo -e "     ${BLUE}http://localhost:5000${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log INFO "ログファイル: ${LOG_FILE}"
}

# メイン処理
main() {
    parse_args "$@"
    initialize
    check_prerequisites
    cleanup_existing_env
    create_directory_structure
    create_virtual_environment
    install_dependencies
    create_env_file
    initialize_database
    load_test_data
    verify_flask_server
    show_completion_message

    log INFO "=== 開発環境初期化完了 ==="
}

# スクリプト実行
main "$@"
