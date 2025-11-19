#!/bin/bash

################################################################################
# init-prod-env.sh
#
# 本番環境初期化スクリプト
# Python仮想環境の作成、本番用パッケージのインストール、
# systemdサービスの登録、Nginx設定の適用を実行
#
# 使用例:
#   sudo ./production/scripts/init-prod-env.sh              # 通常実行
#   sudo ./production/scripts/init-prod-env.sh --reset      # 既存環境をリセット
#   sudo ./production/scripts/init-prod-env.sh --no-start   # サービス起動をスキップ
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
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# プロジェクトルート取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROD_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$PROD_ROOT")"

# ログファイル設定
LOG_DIR="${PROJECT_ROOT}/logs"
LOG_FILE="${LOG_DIR}/init-prod-$(date +%Y%m%d-%H%M%S).log"

# フラグ
RESET_ENV=0
NO_START=0

# システムサービス名
SERVICE_NAME="pcsetup-flask"

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
        SECURITY)
            echo -e "${MAGENTA}[SECURITY]${NC} ${timestamp} - ${message}" | tee -a "$LOG_FILE"
            ;;
    esac
}

# ヘルプメッセージ表示
show_help() {
    cat << EOF
使用方法: sudo $0 [OPTIONS]

本番環境初期化スクリプト（root権限が必要）

OPTIONS:
    --reset         既存環境をリセットして再構築
    --no-start      サービス起動をスキップ
    -h, --help      このヘルプメッセージを表示

例:
    sudo $0                 # 通常実行
    sudo $0 --reset         # 環境リセット
    sudo $0 --no-start      # サービス起動なし

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
            --no-start)
                NO_START=1
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
    echo -e "${CYAN}  🚀 PC Setup Automation - 本番環境初期化スクリプト${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# 初期化
initialize() {
    show_banner
    log INFO "=== 本番環境初期化開始 ==="

    # root権限チェック
    if [[ $EUID -ne 0 ]]; then
        log ERROR "このスクリプトはroot権限で実行する必要があります"
        log ERROR "実行コマンド: sudo $0"
        exit 1
    fi

    log INFO "プロジェクトルート: ${PROJECT_ROOT}"
    log INFO "本番環境ルート: ${PROD_ROOT}"

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
    else
        log ERROR "Python3がインストールされていません"
        ((errors++))
    fi

    # Nginx確認
    if command -v nginx &> /dev/null; then
        local nginx_version=$(nginx -v 2>&1 | awk '{print $3}')
        log INFO "Nginx: ${nginx_version}"
    else
        log WARN "Nginxがインストールされていません"
        log INFO "インストールコマンド: sudo apt install nginx"
    fi

    # systemd確認
    if command -v systemctl &> /dev/null; then
        log INFO "systemd: 利用可能"
    else
        log ERROR "systemdが利用できません"
        ((errors++))
    fi

    # PostgreSQL確認（オプション）
    if command -v psql &> /dev/null; then
        local pg_version=$(psql --version | awk '{print $3}')
        log INFO "PostgreSQL: ${pg_version} (利用可能)"
    else
        log WARN "PostgreSQLがインストールされていません（SQLiteを使用）"
    fi

    # ファイアウォール確認
    if command -v ufw &> /dev/null; then
        local ufw_status=$(ufw status | head -1)
        log INFO "ファイアウォール (ufw): ${ufw_status}"
    fi

    if [[ $errors -gt 0 ]]; then
        log ERROR "前提条件チェック失敗: ${errors}個のエラー"
        exit 1
    fi

    log SUCCESS "前提条件チェック: すべて正常"
}

# ディレクトリ構造作成
create_directory_structure() {
    log INFO "=== ディレクトリ構造作成 ==="

    # 必要なディレクトリ作成
    mkdir -p "${PROD_ROOT}/flask-app"
    mkdir -p "${PROD_ROOT}/logs"
    mkdir -p "${PROD_ROOT}/uploads"
    mkdir -p "${PROD_ROOT}/backups"
    mkdir -p "${PROD_ROOT}/odj-files"

    # 権限設定
    chown -R www-data:www-data "${PROD_ROOT}/uploads" 2>/dev/null || true
    chown -R www-data:www-data "${PROD_ROOT}/logs" 2>/dev/null || true
    chmod 755 "${PROD_ROOT}/odj-files"

    log INFO "ディレクトリ構造作成完了"
}

# Python仮想環境作成
create_virtual_environment() {
    log INFO "=== Python仮想環境作成 ==="

    if [[ -d "${PROD_ROOT}/venv" ]] && [[ $RESET_ENV -eq 0 ]]; then
        log WARN "仮想環境は既に存在します（スキップ）"
        return 0
    fi

    # 既存の仮想環境削除（リセット時）
    if [[ -d "${PROD_ROOT}/venv" ]] && [[ $RESET_ENV -eq 1 ]]; then
        log INFO "既存の仮想環境を削除中..."
        rm -rf "${PROD_ROOT}/venv"
    fi

    log INFO "仮想環境を作成中..."
    python3 -m venv "${PROD_ROOT}/venv"

    # pip更新
    log INFO "pipを更新中..."
    "${PROD_ROOT}/venv/bin/pip" install --upgrade pip --quiet

    log SUCCESS "仮想環境作成完了"
}

# 本番用依存パッケージインストール
install_production_dependencies() {
    log INFO "=== 本番用依存パッケージインストール ==="

    # requirements.txt確認
    local requirements_file="${PROJECT_ROOT}/flask-app/requirements.txt"

    if [[ ! -f "$requirements_file" ]]; then
        log WARN "requirements.txtが見つかりません。基本パッケージのみインストールします"

        # 本番用基本パッケージインストール
        log INFO "本番用パッケージをインストール中..."
        "${PROD_ROOT}/venv/bin/pip" install Flask Flask-SQLAlchemy Flask-Migrate \
            python-dotenv gunicorn psycopg2-binary --quiet
    else
        log INFO "requirements.txtからパッケージをインストール中..."
        "${PROD_ROOT}/venv/bin/pip" install -r "$requirements_file" --quiet

        # Gunicornを追加（WSGIサーバ）
        log INFO "Gunicornをインストール中..."
        "${PROD_ROOT}/venv/bin/pip" install gunicorn --quiet
    fi

    # インストール済みパッケージ確認
    log INFO "主要パッケージバージョン:"
    "${PROD_ROOT}/venv/bin/pip" list | grep -E "(Flask|gunicorn|SQLAlchemy)" | while read line; do
        log DEBUG "  $line"
    done

    log SUCCESS "依存パッケージインストール完了"
}

# 本番環境変数ファイル作成
create_production_env_file() {
    log INFO "=== 本番環境変数ファイル作成 ==="

    local env_file="${PROD_ROOT}/.env.prod"

    if [[ -f "$env_file" ]]; then
        log WARN ".env.prodは既に存在します（スキップ）"
        return 0
    fi

    log INFO ".env.prodを作成中..."

    # ランダムなSECRET_KEY生成
    local secret_key=$(python3 -c "import secrets; print(secrets.token_hex(32))")

    cat > "$env_file" << EOF
# 本番環境設定ファイル
# 作成日: $(date +%Y-%m-%d)
# 警告: このファイルには機密情報が含まれます。厳重に管理してください。

# Flask設定
FLASK_APP=app.py
FLASK_ENV=production
FLASK_DEBUG=0
SECRET_KEY=${secret_key}

# データベース設定
# SQLite使用の場合:
DATABASE_URL=sqlite:///pc_setup.db
# PostgreSQL使用の場合（コメント解除して使用）:
# DATABASE_URL=postgresql://username:password@localhost/pcsetup_db

# サーバ設定
HOST=127.0.0.1
PORT=8000

# Gunicorn設定
WORKERS=4
WORKER_CLASS=sync
TIMEOUT=120

# ログレベル
LOG_LEVEL=INFO

# セキュリティ設定
SESSION_COOKIE_SECURE=True
SESSION_COOKIE_HTTPONLY=True
SESSION_COOKIE_SAMESITE=Lax

# その他の設定
TESTING=False
EOF

    # 権限設定（本番環境では機密情報保護）
    chmod 600 "$env_file"

    log SECURITY "SECRET_KEYを自動生成しました"
    log SECURITY ".env.prodの権限を600に設定しました"
    log SUCCESS ".env.prod作成完了"
}

# 本番データベース初期化
initialize_production_database() {
    log INFO "=== 本番データベース初期化 ==="

    local flask_app_dir="${PROJECT_ROOT}/flask-app"

    if [[ ! -d "$flask_app_dir" ]]; then
        log WARN "flask-appディレクトリが見つかりません"
        return 0
    fi

    cd "$flask_app_dir"

    # データベースファイル作成位置
    export DATABASE_URL="sqlite:///${PROD_ROOT}/pc_setup.db"

    if [[ -f "app.py" ]]; then
        log INFO "本番データベースを初期化中..."

        "${PROD_ROOT}/venv/bin/python3" << 'PYTHON_SCRIPT'
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

        # データベースファイルの権限設定
        if [[ -f "${PROD_ROOT}/pc_setup.db" ]]; then
            chmod 644 "${PROD_ROOT}/pc_setup.db"
            chown www-data:www-data "${PROD_ROOT}/pc_setup.db" 2>/dev/null || true
        fi

        log SUCCESS "本番データベース初期化完了"
    else
        log WARN "app.pyが見つかりません"
    fi

    cd "$PROD_ROOT"
}

# systemdサービスファイル作成
create_systemd_service() {
    log INFO "=== systemdサービスファイル作成 ==="

    local service_file="${PROD_ROOT}/systemd/${SERVICE_NAME}.service"
    local system_service_file="/etc/systemd/system/${SERVICE_NAME}.service"

    # サービスファイル作成
    log INFO "サービスファイルを作成中..."

    cat > "$service_file" << EOF
[Unit]
Description=PC Setup Automation Flask Application
After=network.target

[Service]
Type=notify
User=www-data
Group=www-data
WorkingDirectory=${PROJECT_ROOT}/flask-app
Environment="PATH=${PROD_ROOT}/venv/bin"
EnvironmentFile=${PROD_ROOT}/.env.prod
ExecStart=${PROD_ROOT}/venv/bin/gunicorn \\
    --workers 4 \\
    --bind 127.0.0.1:8000 \\
    --timeout 120 \\
    --access-logfile ${PROD_ROOT}/logs/gunicorn-access.log \\
    --error-logfile ${PROD_ROOT}/logs/gunicorn-error.log \\
    app:app

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # システムディレクトリにコピー
    log INFO "サービスファイルをシステムにインストール中..."
    cp "$service_file" "$system_service_file"
    chmod 644 "$system_service_file"

    # systemd reload
    log INFO "systemdをリロード中..."
    systemctl daemon-reload

    log SUCCESS "systemdサービスファイル作成完了"
}

# Nginx設定ファイル作成
create_nginx_config() {
    log INFO "=== Nginx設定ファイル作成 ==="

    local nginx_config="${PROD_ROOT}/nginx/pcsetup.conf"
    local nginx_available="/etc/nginx/sites-available/pcsetup"
    local nginx_enabled="/etc/nginx/sites-enabled/pcsetup"

    # Nginx設定ファイル作成
    log INFO "Nginx設定ファイルを作成中..."

    cat > "$nginx_config" << 'EOF'
# PC Setup Automation - Nginx設定ファイル

upstream pcsetup_app {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    server_name _;

    # ログ設定
    access_log /var/log/nginx/pcsetup-access.log;
    error_log /var/log/nginx/pcsetup-error.log;

    # クライアントボディサイズ制限（ODJファイルアップロード用）
    client_max_body_size 10M;

    # 静的ファイル
    location /static {
        alias /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app/static;
        expires 30d;
    }

    # アップロードファイル（ODJファイル等）
    location /odj {
        alias /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/production/odj-files;
        internal;
    }

    # アプリケーション
    location / {
        proxy_pass http://pcsetup_app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # タイムアウト設定
        proxy_connect_timeout 120s;
        proxy_send_timeout 120s;
        proxy_read_timeout 120s;
    }

    # ヘルスチェック
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
}
EOF

    # パス置換（プロジェクトルート）
    sed -i "s|/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project|${PROJECT_ROOT}|g" "$nginx_config"

    # sites-availableにコピー
    if command -v nginx &> /dev/null; then
        log INFO "Nginx設定をインストール中..."
        cp "$nginx_config" "$nginx_available"

        # sites-enabledにシンボリックリンク作成
        if [[ ! -L "$nginx_enabled" ]]; then
            ln -s "$nginx_available" "$nginx_enabled"
            log INFO "Nginx設定を有効化しました"
        fi

        # デフォルト設定を無効化
        if [[ -L "/etc/nginx/sites-enabled/default" ]]; then
            rm -f "/etc/nginx/sites-enabled/default"
            log INFO "デフォルト設定を無効化しました"
        fi

        # Nginx設定テスト
        log INFO "Nginx設定をテスト中..."
        if nginx -t 2>&1 | tee -a "$LOG_FILE"; then
            log SUCCESS "Nginx設定テスト: 正常"
        else
            log ERROR "Nginx設定テスト: 失敗"
        fi
    else
        log WARN "Nginxがインストールされていません"
    fi

    log SUCCESS "Nginx設定ファイル作成完了"
}

# ファイアウォール設定
configure_firewall() {
    log INFO "=== ファイアウォール設定 ==="

    if ! command -v ufw &> /dev/null; then
        log WARN "ufwがインストールされていません（スキップ）"
        return 0
    fi

    log INFO "ファイアウォールルールを設定中..."

    # HTTP許可
    ufw allow 80/tcp comment 'PC Setup Web Interface' 2>&1 | tee -a "$LOG_FILE"

    # HTTPS許可（将来の証明書導入用）
    ufw allow 443/tcp comment 'PC Setup Web Interface (HTTPS)' 2>&1 | tee -a "$LOG_FILE"

    log SECURITY "ファイアウォールルール設定完了"
    log INFO "有効化コマンド: sudo ufw enable"
}

# セキュリティチェック
security_check() {
    log INFO "=== セキュリティチェック ==="

    local warnings=0

    # .env.prod権限確認
    local env_file="${PROD_ROOT}/.env.prod"
    if [[ -f "$env_file" ]]; then
        local perms=$(stat -c "%a" "$env_file")
        if [[ "$perms" != "600" ]]; then
            log WARN ".env.prodの権限が600ではありません (現在: ${perms})"
            ((warnings++))
        else
            log SECURITY ".env.prod権限: OK"
        fi
    fi

    # DEBUG設定確認
    if grep -q "FLASK_DEBUG=1" "$env_file" 2>/dev/null; then
        log WARN "本番環境でDEBUGモードが有効です"
        ((warnings++))
    else
        log SECURITY "DEBUGモード: 無効（正常）"
    fi

    # SECRET_KEY確認
    if grep -q "SECRET_KEY=dev-" "$env_file" 2>/dev/null; then
        log ERROR "本番環境で開発用SECRET_KEYが使用されています"
        ((warnings++))
    else
        log SECURITY "SECRET_KEY: 本番用に設定済み"
    fi

    if [[ $warnings -gt 0 ]]; then
        log WARN "セキュリティチェック: ${warnings}個の警告"
    else
        log SUCCESS "セキュリティチェック: すべて正常"
    fi
}

# サービス起動
start_services() {
    if [[ $NO_START -eq 1 ]]; then
        log INFO "サービス起動をスキップします（--no-startオプション）"
        return 0
    fi

    log INFO "=== サービス起動 ==="

    # Flaskサービス起動
    log INFO "Flaskサービスを起動中..."
    if systemctl start "${SERVICE_NAME}"; then
        log SUCCESS "Flaskサービス起動完了"

        # 自動起動設定
        systemctl enable "${SERVICE_NAME}"
        log INFO "Flaskサービス自動起動: 有効"
    else
        log ERROR "Flaskサービスの起動に失敗しました"
        systemctl status "${SERVICE_NAME}" --no-pager | tee -a "$LOG_FILE"
    fi

    # Nginx起動
    if command -v nginx &> /dev/null; then
        log INFO "Nginxを再起動中..."
        if systemctl restart nginx; then
            log SUCCESS "Nginx再起動完了"
            systemctl enable nginx
            log INFO "Nginx自動起動: 有効"
        else
            log ERROR "Nginxの再起動に失敗しました"
            systemctl status nginx --no-pager | tee -a "$LOG_FILE"
        fi
    fi
}

# 完了メッセージ
show_completion_message() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✅ 本番環境初期化が完了しました！${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}サービス情報:${NC}"
    echo ""
    echo -e "  Flaskサービス: ${SERVICE_NAME}"
    echo -e "  Webサーバ: Nginx"
    echo -e "  アクセスURL: ${BLUE}http://localhost/${NC}"
    echo ""
    echo -e "${YELLOW}管理コマンド:${NC}"
    echo ""
    echo -e "  サービス状態確認:"
    echo -e "    ${BLUE}sudo systemctl status ${SERVICE_NAME}${NC}"
    echo -e "    ${BLUE}sudo systemctl status nginx${NC}"
    echo ""
    echo -e "  サービス再起動:"
    echo -e "    ${BLUE}sudo systemctl restart ${SERVICE_NAME}${NC}"
    echo -e "    ${BLUE}sudo systemctl restart nginx${NC}"
    echo ""
    echo -e "  ログ確認:"
    echo -e "    ${BLUE}sudo journalctl -u ${SERVICE_NAME} -f${NC}"
    echo -e "    ${BLUE}tail -f ${PROD_ROOT}/logs/gunicorn-error.log${NC}"
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
    create_directory_structure
    create_virtual_environment
    install_production_dependencies
    create_production_env_file
    initialize_production_database
    create_systemd_service
    create_nginx_config
    configure_firewall
    security_check
    start_services
    show_completion_message

    log INFO "=== 本番環境初期化完了 ==="
}

# スクリプト実行
main "$@"
