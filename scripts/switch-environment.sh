#!/bin/bash

################################################################################
# switch-environment.sh
#
# 開発環境と本番環境を切り替えるスクリプト
# 環境変数の切り替え、サービスの再起動などを自動実行します
#
# 使用例:
#   ./scripts/switch-environment.sh development  # 開発環境に切り替え
#   ./scripts/switch-environment.sh production   # 本番環境に切り替え
#   ./scripts/switch-environment.sh status       # 現在の環境を表示
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
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# ログファイル設定
LOG_DIR="${PROJECT_ROOT}/logs"
LOG_FILE="${LOG_DIR}/switch-env-$(date +%Y%m%d-%H%M%S).log"

# 環境設定ファイル
ENV_STATUS_FILE="${PROJECT_ROOT}/.current_environment"

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
使用方法: $0 [ENVIRONMENT]

環境切り替えスクリプト

ENVIRONMENT:
    development     開発環境に切り替え
    production      本番環境に切り替え
    status          現在の環境を表示
    -h, --help      このヘルプメッセージを表示

例:
    $0 development      # 開発環境に切り替え
    $0 production       # 本番環境に切り替え
    $0 status           # 現在の環境を表示

EOF
}

# 初期化
initialize() {
    log INFO "=== 環境切り替えスクリプト開始 ==="
    log INFO "プロジェクトルート: ${PROJECT_ROOT}"

    # ログディレクトリ作成
    mkdir -p "$LOG_DIR"

    log INFO "ログファイル: ${LOG_FILE}"
}

# 現在の環境を取得
get_current_environment() {
    if [[ -f "$ENV_STATUS_FILE" ]]; then
        cat "$ENV_STATUS_FILE"
    else
        echo "unknown"
    fi
}

# 現在の環境を表示
show_current_environment() {
    local current_env=$(get_current_environment)

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  現在の環境情報${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    case $current_env in
        development)
            echo -e "  環境: ${GREEN}開発環境 (development)${NC}"
            echo -e "  ディレクトリ: ${PROJECT_ROOT}/development/"
            echo -e "  設定ファイル: .env.dev"
            echo -e "  データベース: development/pc_setup.db"
            echo -e "  ポート: 5000"
            ;;
        production)
            echo -e "  環境: ${BLUE}本番環境 (production)${NC}"
            echo -e "  ディレクトリ: ${PROJECT_ROOT}/production/"
            echo -e "  設定ファイル: .env.prod"
            echo -e "  データベース: production/pc_setup.db"
            echo -e "  ポート: 8000"
            echo -e "  Webサーバ: Nginx (80/443)"
            ;;
        *)
            echo -e "  環境: ${YELLOW}未設定${NC}"
            echo -e "  メッセージ: 環境が設定されていません"
            ;;
    esac

    echo ""

    # Flaskサービス状態確認
    if systemctl is-active --quiet pcsetup-flask 2>/dev/null; then
        echo -e "  Flaskサービス: ${GREEN}稼働中${NC}"
    else
        echo -e "  Flaskサービス: ${YELLOW}停止中${NC}"
    fi

    # Nginxサービス状態確認
    if systemctl is-active --quiet nginx 2>/dev/null; then
        echo -e "  Nginxサービス: ${GREEN}稼働中${NC}"
    else
        echo -e "  Nginxサービス: ${YELLOW}停止中${NC}"
    fi

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# 開発環境に切り替え
switch_to_development() {
    log INFO "=== 開発環境への切り替え開始 ==="

    # 現在の環境確認
    local current_env=$(get_current_environment)
    if [[ "$current_env" == "development" ]]; then
        log WARN "既に開発環境です"
        return 0
    fi

    # 本番サービス停止
    if [[ "$current_env" == "production" ]]; then
        log INFO "本番サービスを停止中..."
        if systemctl is-active --quiet pcsetup-flask 2>/dev/null; then
            sudo systemctl stop pcsetup-flask || log WARN "Flaskサービスの停止に失敗"
        fi
        if systemctl is-active --quiet nginx 2>/dev/null; then
            sudo systemctl stop nginx || log WARN "Nginxの停止に失敗"
        fi
    fi

    # 環境変数切り替え（シンボリックリンク）
    log INFO "環境変数を切り替え中..."
    if [[ -f "${PROJECT_ROOT}/.env" ]]; then
        rm -f "${PROJECT_ROOT}/.env"
    fi
    if [[ -f "${PROJECT_ROOT}/development/.env.dev" ]]; then
        ln -s "${PROJECT_ROOT}/development/.env.dev" "${PROJECT_ROOT}/.env"
        log INFO "環境変数: .env.dev にリンク"
    else
        log WARN ".env.dev が見つかりません"
    fi

    # 環境状態ファイル更新
    echo "development" > "$ENV_STATUS_FILE"
    log INFO "環境状態を更新: development"

    # 開発サーバ情報表示
    log INFO "開発環境に切り替わりました"
    log INFO "開発サーバ起動コマンド:"
    log INFO "  cd ${PROJECT_ROOT}/development/flask-app"
    log INFO "  source venv/bin/activate"
    log INFO "  flask run --host=0.0.0.0 --port=5000"

    log INFO "=== 開発環境への切り替え完了 ==="
}

# 本番環境に切り替え
switch_to_production() {
    log INFO "=== 本番環境への切り替え開始 ==="

    # 現在の環境確認
    local current_env=$(get_current_environment)
    if [[ "$current_env" == "production" ]]; then
        log WARN "既に本番環境です"
        return 0
    fi

    # 確認プロンプト
    echo -e "${YELLOW}警告: 本番環境に切り替えます。よろしいですか？ (yes/no)${NC}"
    read -r confirmation
    if [[ "$confirmation" != "yes" ]]; then
        log WARN "本番環境への切り替えをキャンセルしました"
        exit 0
    fi

    # 環境変数切り替え
    log INFO "環境変数を切り替え中..."
    if [[ -f "${PROJECT_ROOT}/.env" ]]; then
        rm -f "${PROJECT_ROOT}/.env"
    fi
    if [[ -f "${PROJECT_ROOT}/production/.env.prod" ]]; then
        ln -s "${PROJECT_ROOT}/production/.env.prod" "${PROJECT_ROOT}/.env"
        log INFO "環境変数: .env.prod にリンク"
    else
        log ERROR ".env.prod が見つかりません"
        exit 1
    fi

    # 環境状態ファイル更新
    echo "production" > "$ENV_STATUS_FILE"
    log INFO "環境状態を更新: production"

    # Flaskサービス起動
    log INFO "Flaskサービスを起動中..."
    if systemctl list-unit-files | grep -q pcsetup-flask; then
        sudo systemctl start pcsetup-flask || log ERROR "Flaskサービスの起動に失敗"
        sudo systemctl enable pcsetup-flask || log WARN "Flaskサービスの自動起動設定に失敗"
        log INFO "Flaskサービス: 起動完了"
    else
        log WARN "pcsetup-flask.service が見つかりません"
        log INFO "サービスファイルをインストールしてください:"
        log INFO "  sudo cp ${PROJECT_ROOT}/production/systemd/pcsetup-flask.service /etc/systemd/system/"
        log INFO "  sudo systemctl daemon-reload"
    fi

    # Nginx起動
    log INFO "Nginxを起動中..."
    if command -v nginx &> /dev/null; then
        sudo systemctl start nginx || log ERROR "Nginxの起動に失敗"
        sudo systemctl enable nginx || log WARN "Nginxの自動起動設定に失敗"
        log INFO "Nginx: 起動完了"
    else
        log WARN "Nginxがインストールされていません"
    fi

    log INFO "本番環境に切り替わりました"
    log INFO "アクセスURL: http://localhost/ (Nginx経由)"

    log INFO "=== 本番環境への切り替え完了 ==="
}

# メイン処理
main() {
    if [[ $# -eq 0 ]]; then
        log ERROR "引数が必要です"
        show_help
        exit 1
    fi

    local target_env="$1"

    case $target_env in
        development|dev)
            initialize
            switch_to_development
            echo ""
            show_current_environment
            ;;
        production|prod)
            initialize
            switch_to_production
            echo ""
            show_current_environment
            ;;
        status)
            initialize
            show_current_environment
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log ERROR "不明な環境: $target_env"
            show_help
            exit 1
            ;;
    esac

    log INFO "ログファイル: ${LOG_FILE}"
}

# スクリプト実行
main "$@"
