#!/usr/bin/env bash
set -euo pipefail

PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY_HOME="${URGS_DEPLOY_HOME:-}"
ROOT_DIR="$PACKAGE_DIR"

if [ -n "$DEPLOY_HOME" ]; then
    mkdir -p "$DEPLOY_HOME"
    ROOT_DIR="$(cd "$DEPLOY_HOME" && pwd)"
fi

ENV_FILE="${ENV_FILE:-${ROOT_DIR}/config/deploy.env}"
ACTIVE_SERVICES_FILE="${ROOT_DIR}/config/services.list"
PACKAGE_SERVICES_FILE="${URGS_PACKAGE_SERVICES_FILE:-${ROOT_DIR}/config/package-services.list}"
SERVICES_FILE="${URGS_SELECTED_SERVICES_FILE:-${ACTIVE_SERVICES_FILE}}"
LOG_DIR="${ROOT_DIR}/logs"
PID_DIR="${ROOT_DIR}/pids"

if [ -n "$DEPLOY_HOME" ] && [ "$PACKAGE_DIR" != "$ROOT_DIR" ]; then
    mkdir -p "${ROOT_DIR}/config"
    if [ ! -f "$ENV_FILE" ]; then
        cp "${PACKAGE_DIR}/config/deploy.env" "$ENV_FILE"
    fi
fi

load_env() {
    if [ -f "$ENV_FILE" ]; then
        # shellcheck disable=SC1090
        source "$ENV_FILE"
    fi
}

apply_runtime_defaults() {
    JAVA_BIN="${JAVA_BIN:-java}"
    PYTHON_BIN="${PYTHON_BIN:-python3}"
    PIP_INSTALL="${PIP_INSTALL:-1}"
    TZ="${TZ:-Asia/Shanghai}"
    API_PORT="${API_PORT:-8080}"
    EXECUTOR_PORT="${EXECUTOR_PORT:-8082}"
    RAG_PORT="${RAG_PORT:-8001}"
    AGENT_PORT="${AGENT_PORT:-8002}"
    WEB_LISTEN_PORT="${WEB_LISTEN_PORT:-18080}"
    WEB_SERVER_NAME="${WEB_SERVER_NAME:-_}"
    API_TARGET="${API_TARGET:-http://127.0.0.1:${API_PORT}}"
    API_UPSTREAM_SERVERS="${API_UPSTREAM_SERVERS:-}"
    API_UPSTREAM_STICKY="${API_UPSTREAM_STICKY:-ip_hash}"
    RAG_TARGET="${RAG_TARGET:-http://127.0.0.1:${RAG_PORT}}"
    IM_API_TARGET="${IM_API_TARGET:-${API_TARGET}}"
    NGINX_ENABLED="${NGINX_ENABLED:-1}"
    NGINX_USE_SYSTEM="${NGINX_USE_SYSTEM:-0}"
    NGINX_CONF_DIR="${NGINX_CONF_DIR:-/etc/nginx/conf.d}"
    NGINX_LOCAL_CONF="${NGINX_LOCAL_CONF:-${ROOT_DIR}/config/nginx.local.conf}"
    START_WEB_STATIC="${START_WEB_STATIC:-0}"
    WEB_STATIC_PORT="${WEB_STATIC_PORT:-3000}"
    REDIS_PORT="${REDIS_PORT:-6379}"
    REDIS_BIND="${REDIS_BIND:-127.0.0.1}"
    ONLYOFFICE_PORT="${ONLYOFFICE_PORT:-8088}"
    ONLYOFFICE_JWT_SECRET="${ONLYOFFICE_JWT_SECRET:-}"
    ONLYOFFICE_DB_PASSWORD="${ONLYOFFICE_DB_PASSWORD:-onlyoffice}"
    ONLYOFFICE_DB_NAME="${ONLYOFFICE_DB_NAME:-onlyoffice}"
    ONLYOFFICE_DB_USER="${ONLYOFFICE_DB_USER:-onlyoffice}"
    DATA_ROOT="${DATA_ROOT:-/data/urgs}"
    REDIS_DATA_DIR="${REDIS_DATA_DIR:-${DATA_ROOT}/redis}"
    NGINX_LOG_DIR="${NGINX_LOG_DIR:-${ROOT_DIR}/logs/nginx}"
    NGINX_ERROR_LOG="${NGINX_ERROR_LOG:-${NGINX_LOG_DIR}/error.log}"
    NGINX_ACCESS_LOG="${NGINX_ACCESS_LOG:-${NGINX_LOG_DIR}/access.log}"
    STOP_CONFLICTING_PORTS="${STOP_CONFLICTING_PORTS:-1}"
    BACKUP_BEFORE_DEPLOY="${BACKUP_BEFORE_DEPLOY:-1}"
    BACKUP_ROOT="${BACKUP_ROOT:-${ROOT_DIR}/backups}"
    BACKUP_NAME="${BACKUP_NAME:-$(date +%Y%m%d%H%M%S)}"
    MYSQL_JDBC_PARAMS="${MYSQL_JDBC_PARAMS:-useSSL=false&serverTimezone=%2B08:00&connectionTimeZone=%2B08:00&forceConnectionTimeZoneToSession=true&characterEncoding=utf8&allowPublicKeyRetrieval=true}"
    MYSQL_EXECUTOR_JDBC_PARAMS="${MYSQL_EXECUTOR_JDBC_PARAMS:-useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=%2B08:00&connectionTimeZone=%2B08:00&forceConnectionTimeZoneToSession=true}"

    export TZ
}

load_env
apply_runtime_defaults

log() {
    printf '[urgs-deploy] %s\n' "$*"
}

die() {
    printf '[urgs-deploy][error] %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage:
  bin/deploy.sh install          Prepare runtime directories, Python venvs, and nginx config.
  bin/deploy.sh start            Start selected services.
  bin/deploy.sh up               Stop, install, and start selected services.
  bin/deploy.sh stop             Stop selected services.
  bin/deploy.sh restart          Restart selected services.
  bin/deploy.sh status           Show selected service status.
  bin/deploy.sh restart api      Restart one service: api, executor, rag, redis, nginx, web-static.
  bin/deploy.sh nginx-config     Render nginx config to stdout.

Before running, edit config/deploy.env only when the package was not generated with production values.

Set URGS_DEPLOY_HOME=/home/appuser/urgs-app to install packages into one stable runtime
directory. In this mode, the extracted package is only an installation source;
only services included in this package are restarted, while other running
services in URGS_DEPLOY_HOME are preserved.
EOF
}

merge_services_list() {
    local source_file="$1"
    local target_file="$2"
    local tmp_file="${target_file}.tmp"
    mkdir -p "$(dirname "$target_file")"
    {
        [ -f "$target_file" ] && cat "$target_file"
        [ -f "$source_file" ] && cat "$source_file"
    } | awk 'NF && !seen[$0]++ { print }' > "$tmp_file"
    mv "$tmp_file" "$target_file"
}

copy_dir_replace() {
    local src="$1"
    local dst="$2"
    [ -d "$src" ] || return 0
    rm -rf "$dst"
    mkdir -p "$(dirname "$dst")"
    cp -R "$src" "$dst"
}

backup_existing_path() {
    local path="$1"
    local backup_dir="$2"
    local relative_path="$3"
    [ "$BACKUP_BEFORE_DEPLOY" = "1" ] || return 0
    [ -e "$path" ] || return 0
    mkdir -p "${backup_dir}/$(dirname "$relative_path")"
    cp -a "$path" "${backup_dir}/${relative_path}"
    log "Backed up ${relative_path} to ${backup_dir}/${relative_path}."
}

copy_dir_replace_with_backup() {
    local src="$1"
    local dst="$2"
    local backup_dir="$3"
    local relative_path="$4"
    [ -d "$src" ] || return 0
    backup_existing_path "$dst" "$backup_dir" "$relative_path"
    copy_dir_replace "$src" "$dst"
}

install_package_to_deploy_home() {
    [ -n "$DEPLOY_HOME" ] || return 0
    [ "$PACKAGE_DIR" != "$ROOT_DIR" ] || return 0
    [ -f "${PACKAGE_DIR}/config/services.list" ] || die "Missing package config/services.list"

    log "Installing package into stable deploy home: ${ROOT_DIR}."
    mkdir -p "${ROOT_DIR}/bin" "${ROOT_DIR}/config" "${ROOT_DIR}/logs" "${ROOT_DIR}/pids" \
        "${ROOT_DIR}/services" "${ROOT_DIR}/components"

    local backup_dir="${BACKUP_ROOT}/${BACKUP_NAME}"
    if [ "$BACKUP_BEFORE_DEPLOY" = "1" ]; then
        mkdir -p "$backup_dir"
        cp "${PACKAGE_DIR}/config/services.list" "${backup_dir}/package-services.list"
        [ -f "${PACKAGE_DIR}/MANIFEST" ] && cp "${PACKAGE_DIR}/MANIFEST" "${backup_dir}/package.MANIFEST"
        log "Backup directory for this deploy: ${backup_dir}."
    fi

    cp "${PACKAGE_DIR}/bin/deploy.sh" "${ROOT_DIR}/bin/deploy.sh"
    chmod +x "${ROOT_DIR}/bin/deploy.sh"

    local deploy_env_keep="${URGS_DEPLOY_ENV_KEEP:-0}"
    if [ "${URGS_DEPLOY_ENV_OVERWRITE:-}" = "1" ]; then
        deploy_env_keep=0
    fi

    if [ "$deploy_env_keep" = "1" ] && [ -f "${ROOT_DIR}/config/deploy.env" ]; then
        cp "${PACKAGE_DIR}/config/deploy.env" "${ROOT_DIR}/config/deploy.env.package"
    else
        backup_existing_path "${ROOT_DIR}/config/deploy.env" "$backup_dir" "config/deploy.env"
        cp "${PACKAGE_DIR}/config/deploy.env" "${ROOT_DIR}/config/deploy.env"
    fi

    backup_existing_path "${ROOT_DIR}/config/nginx.conf.template" "$backup_dir" "config/nginx.conf.template"
    cp "${PACKAGE_DIR}/config/nginx.conf.template" "${ROOT_DIR}/config/nginx.conf.template"
    cp "${PACKAGE_DIR}/config/services.list" "$PACKAGE_SERVICES_FILE"
    merge_services_list "$PACKAGE_SERVICES_FILE" "$ACTIVE_SERVICES_FILE"

    local service
    while IFS= read -r service || [ -n "$service" ]; do
        [ -n "$service" ] || continue
        case "$service" in
            api | web | executor | rag | lineage)
                copy_dir_replace_with_backup "${PACKAGE_DIR}/services/${service}" "${ROOT_DIR}/services/${service}" "$backup_dir" "services/${service}"
                ;;
            nginx | redis | onlyoffice)
                copy_dir_replace_with_backup "${PACKAGE_DIR}/components/${service}" "${ROOT_DIR}/components/${service}" "$backup_dir" "components/${service}"
                rm -rf "${ROOT_DIR}/components/${service}/runtime"
                ;;
        esac
    done < "${PACKAGE_DIR}/config/services.list"
}

service_enabled() {
    local service="$1"
    [ -f "$SERVICES_FILE" ] || return 1
    grep -qx "$service" "$SERVICES_FILE"
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

extract_component_tarballs() {
    local component="$1"
    local dir="${ROOT_DIR}/components/${component}"
    local runtime="${dir}/runtime"
    [ -d "$dir" ] || return 0
    mkdir -p "$runtime"
    local tarball
    for tarball in "$dir"/*.tar.gz "$dir"/*.tgz "$dir"/*.tar; do
        [ -f "$tarball" ] || continue
        if [ ! -f "${runtime}/.extracted" ]; then
            log "Extracting ${component} component: $(basename "$tarball")."
            tar -xf "$tarball" -C "$runtime"
            touch "${runtime}/.extracted"
        fi
        return 0
    done
}

find_component_binary() {
    local component="$1"
    local binary="$2"
    local found=""
    if [ -d "${ROOT_DIR}/components/${component}/runtime" ]; then
        found="$(find "${ROOT_DIR}/components/${component}/runtime" -type f -name "$binary" -perm -111 | head -1)"
    fi
    if [ -n "$found" ]; then
        printf '%s\n' "$found"
        return 0
    fi
    command -v "$binary" 2>/dev/null || true
}

run_as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        die "Root privileges are required: $*"
    fi
}

onlyoffice_package_file() {
    find "${ROOT_DIR}/components/onlyoffice" -maxdepth 1 -type f -name 'onlyoffice-documentserver_*_arm64.deb' 2>/dev/null | sort -V | tail -1
}

install_onlyoffice() {
    service_enabled onlyoffice || return 0

    [ "$(uname -s)" = "Linux" ] || die "ONLYOFFICE system package can only be installed on Linux."
    case "$(uname -m)" in
        aarch64 | arm64) ;;
        *) die "The packaged ONLYOFFICE component targets Linux ARM64; current architecture: $(uname -m)." ;;
    esac
    command -v apt-get >/dev/null 2>&1 || die "ONLYOFFICE ARM64 DEB deployment requires Debian or Ubuntu with apt-get."

    local package_file
    package_file="$(onlyoffice_package_file)"
    [ -n "$package_file" ] || {
        if dpkg-query -W onlyoffice-documentserver >/dev/null 2>&1; then
            log "Using ONLYOFFICE Document Server already installed on the target host."
            return 0
        fi
        die "Missing components/onlyoffice/onlyoffice-documentserver_*_arm64.deb"
    }

    log "Preparing ONLYOFFICE PostgreSQL and RabbitMQ dependencies."
    run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql postgresql-client rabbitmq-server
    if command -v systemctl >/dev/null 2>&1; then
        run_as_root systemctl enable --now postgresql rabbitmq-server
    else
        run_as_root service postgresql start
        run_as_root service rabbitmq-server start
    fi
    prepare_onlyoffice_database

    log "Installing ONLYOFFICE Document Server from $(basename "$package_file")."
    printf '%s\n' \
        "onlyoffice-documentserver onlyoffice/ds-port select ${ONLYOFFICE_PORT}" \
        "onlyoffice-documentserver onlyoffice/jwt-enabled boolean true" \
        "onlyoffice-documentserver onlyoffice/jwt-secret string ${ONLYOFFICE_JWT_SECRET}" \
        "onlyoffice-documentserver onlyoffice/jwt-header string Authorization" \
        | run_as_root debconf-set-selections
    run_as_root env \
        DEBIAN_FRONTEND=noninteractive \
        DB_TYPE=postgres \
        DB_HOST=localhost \
        DB_PORT=5432 \
        DB_NAME="$ONLYOFFICE_DB_NAME" \
        DB_USER="$ONLYOFFICE_DB_USER" \
        DB_PWD="$ONLYOFFICE_DB_PASSWORD" \
        RABBITMQ_PROTO=amqp \
        RABBITMQ_HOST=localhost \
        RABBITMQ_USER=guest \
        RABBITMQ_PWD=guest \
        REDIS_HOST=localhost \
        apt-get install -y "$package_file"
    configure_onlyoffice_jwt
}

prepare_onlyoffice_database() {
    local escaped_password
    [[ "$ONLYOFFICE_DB_NAME" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || die "Invalid ONLYOFFICE_DB_NAME: ${ONLYOFFICE_DB_NAME}"
    [[ "$ONLYOFFICE_DB_USER" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || die "Invalid ONLYOFFICE_DB_USER: ${ONLYOFFICE_DB_USER}"
    escaped_password="$(printf '%s' "$ONLYOFFICE_DB_PASSWORD" | sed "s/'/''/g")"
    local role_sql="DO \\$\\$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${ONLYOFFICE_DB_USER}') THEN CREATE ROLE ${ONLYOFFICE_DB_USER} LOGIN PASSWORD '${escaped_password}'; ELSE ALTER ROLE ${ONLYOFFICE_DB_USER} WITH LOGIN PASSWORD '${escaped_password}'; END IF; END \\$\\$;"

    if [ "$(id -u)" -eq 0 ]; then
        runuser -u postgres -- psql -v ON_ERROR_STOP=1 -c "$role_sql"
        if ! runuser -u postgres -- psql -tAc "SELECT 1 FROM pg_database WHERE datname='${ONLYOFFICE_DB_NAME}'" | grep -q 1; then
            runuser -u postgres -- createdb -O "$ONLYOFFICE_DB_USER" "$ONLYOFFICE_DB_NAME"
        fi
    else
        sudo -u postgres psql -v ON_ERROR_STOP=1 -c "$role_sql"
        if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='${ONLYOFFICE_DB_NAME}'" | grep -q 1; then
            sudo -u postgres createdb -O "$ONLYOFFICE_DB_USER" "$ONLYOFFICE_DB_NAME"
        fi
    fi
}

configure_onlyoffice_jwt() {
    [ -n "$ONLYOFFICE_JWT_SECRET" ] || {
        log "ONLYOFFICE_JWT_SECRET is empty; keeping the Document Server package JWT configuration."
        return 0
    }

    local config_file="/etc/onlyoffice/documentserver/local.json"
    [ -f "$config_file" ] || die "ONLYOFFICE configuration not found: ${config_file}"
    command -v jq >/dev/null 2>&1 || run_as_root apt-get install -y jq

    local temp_file
    temp_file="$(mktemp)"
    jq --arg secret "$ONLYOFFICE_JWT_SECRET" '
        .services.CoAuthoring.secret.inbox.string = $secret |
        .services.CoAuthoring.secret.outbox.string = $secret |
        .services.CoAuthoring.secret.session.string = $secret |
        .services.CoAuthoring.secret.browser.string = $secret |
        .services.CoAuthoring.token.enable.browser = true |
        .services.CoAuthoring.token.enable.request.inbox = true |
        .services.CoAuthoring.token.enable.request.outbox = true
    ' "$config_file" > "$temp_file"
    run_as_root cp "$temp_file" "$config_file"
    rm -f "$temp_file"
}

start_onlyoffice() {
    service_enabled onlyoffice || return 0
    install_onlyoffice
    if command -v systemctl >/dev/null 2>&1; then
        run_as_root systemctl enable --now ds-docservice ds-converter ds-metrics nginx
        run_as_root systemctl restart ds-docservice ds-converter ds-metrics nginx
    else
        run_as_root service ds-docservice restart
        run_as_root service ds-converter restart
        run_as_root service ds-metrics restart
        run_as_root service nginx restart
    fi
    log "ONLYOFFICE Document Server is available on port ${ONLYOFFICE_PORT}."
}

stop_onlyoffice() {
    service_enabled onlyoffice || return 0
    if command -v systemctl >/dev/null 2>&1; then
        run_as_root systemctl stop ds-docservice ds-converter ds-metrics || true
    else
        run_as_root service ds-docservice stop || true
        run_as_root service ds-converter stop || true
        run_as_root service ds-metrics stop || true
    fi
}

status_onlyoffice() {
    if curl -fsS "http://127.0.0.1:${ONLYOFFICE_PORT}/healthcheck" 2>/dev/null | grep -qi true; then
        printf '%-12s RUNNING port=%s\n' "onlyoffice" "$ONLYOFFICE_PORT"
    else
        printf '%-12s STOPPED\n' "onlyoffice"
    fi
}

pid_file() {
    printf '%s/%s.pid' "$PID_DIR" "$1"
}

is_running() {
    local service="$1"
    local file
    file="$(pid_file "$service")"
    [ -f "$file" ] || return 1
    kill -0 "$(cat "$file")" >/dev/null 2>&1
}

port_listener_pids() {
    local port="$1"
    if command -v lsof >/dev/null 2>&1; then
        lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null | sort -u
    elif command -v fuser >/dev/null 2>&1; then
        fuser "${port}/tcp" 2>/dev/null | tr ' ' '\n' | sed '/^$/d' | sort -u
    fi
}

stop_conflicting_port() {
    local service="$1"
    local port="$2"
    [ "$STOP_CONFLICTING_PORTS" = "1" ] || return 0
    [ -n "$port" ] || return 0

    local current_pid=""
    if is_running "$service"; then
        current_pid="$(cat "$(pid_file "$service")")"
    fi

    local pid owner current_user command_line
    current_user="$(id -un)"
    for pid in $(port_listener_pids "$port"); do
        [ -n "$pid" ] || continue
        [ "$pid" = "$current_pid" ] && continue
        owner="$(ps -o user= -p "$pid" 2>/dev/null | awk '{print $1}')"
        command_line="$(ps -o command= -p "$pid" 2>/dev/null || true)"
        if [ "$owner" != "$current_user" ]; then
            die "${service} port ${port} is already used by pid ${pid} (${owner}). Stop it or change ${service} port."
        fi
        log "Stopping existing process on ${service} port ${port}: pid ${pid} ${command_line}"
        kill "$pid" >/dev/null 2>&1 || true
    done

    for _ in $(seq 1 20); do
        local remaining=""
        for pid in $(port_listener_pids "$port"); do
            [ "$pid" = "$current_pid" ] && continue
            remaining="${remaining} ${pid}"
        done
        [ -z "$remaining" ] && return 0
        sleep 1
    done

    for pid in $(port_listener_pids "$port"); do
        [ "$pid" = "$current_pid" ] && continue
        owner="$(ps -o user= -p "$pid" 2>/dev/null | awk '{print $1}')"
        [ "$owner" = "$current_user" ] && kill -9 "$pid" >/dev/null 2>&1 || true
    done
}

start_background() {
    local service="$1"
    shift
    if is_running "$service"; then
        log "${service} is already running with pid $(cat "$(pid_file "$service")")."
        return
    fi
    mkdir -p "$LOG_DIR" "$PID_DIR"
    log "Starting ${service}."
    nohup "$@" > "${LOG_DIR}/${service}.log" 2>&1 &
    printf '%s\n' "$!" > "$(pid_file "$service")"
}

stop_service() {
    local service="$1"
    local file
    file="$(pid_file "$service")"
    if ! is_running "$service"; then
        rm -f "$file"
        log "${service} is not running."
        return
    fi
    log "Stopping ${service}."
    kill "$(cat "$file")"
    local i
    for i in $(seq 1 20); do
        if ! kill -0 "$(cat "$file")" >/dev/null 2>&1; then
            rm -f "$file"
            return
        fi
        sleep 1
    done
    kill -9 "$(cat "$file")" >/dev/null 2>&1 || true
    rm -f "$file"
}

status_service() {
    local service="$1"
    if is_running "$service"; then
        printf '%-12s RUNNING pid=%s\n' "$service" "$(cat "$(pid_file "$service")")"
    else
        printf '%-12s STOPPED\n' "$service"
    fi
}

generate_internal_api_token() {
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -hex 32
    else
        od -An -N32 -tx1 /dev/urandom | tr -d ' \n'
    fi
}

ensure_internal_api_token() {
    if [ -n "${URGS_INTERNAL_API_TOKEN:-}" ]; then
        export URGS_INTERNAL_API_TOKEN
        return
    fi

    local token_file="${ROOT_DIR}/config/internal-api.token"
    mkdir -p "${ROOT_DIR}/config"
    if [ ! -s "$token_file" ]; then
        (umask 077 && generate_internal_api_token > "$token_file")
    fi
    chmod 600 "$token_file"
    URGS_INTERNAL_API_TOKEN="$(tr -d '\r\n' < "$token_file")"
    [ -n "$URGS_INTERNAL_API_TOKEN" ] || die "Internal API token file is empty: $token_file"
    export URGS_INTERNAL_API_TOKEN
}

export_common_env() {
    ensure_internal_api_token
    export DATA_ROOT="${DATA_ROOT:-/data/urgs}"
    export SPRING_PROFILES_ACTIVE="${SPRING_PROFILES_ACTIVE:-prod}"
    export SPRING_DATASOURCE_URL="${SPRING_DATASOURCE_URL:-jdbc:mysql://${DB_HOST:-127.0.0.1}:${DB_PORT:-3306}/${DB_NAME:-urgs}?${MYSQL_JDBC_PARAMS}}"
    export SPRING_DATASOURCE_USERNAME="${SPRING_DATASOURCE_USERNAME:-${DB_USER:-urgs}}"
    export SPRING_DATASOURCE_PASSWORD="${SPRING_DATASOURCE_PASSWORD:-${DB_PASSWORD:-}}"
    export SPRING_NEO4J_URI="${SPRING_NEO4J_URI:-bolt://${NEO4J_HOST:-127.0.0.1}:${NEO4J_PORT_BOLT:-7687}}"
    export SPRING_NEO4J_AUTHENTICATION_USERNAME="${SPRING_NEO4J_AUTHENTICATION_USERNAME:-${NEO4J_USER:-neo4j}}"
    export SPRING_NEO4J_AUTHENTICATION_PASSWORD="${SPRING_NEO4J_AUTHENTICATION_PASSWORD:-${NEO4J_PASSWORD:-}}"
    export URGS_INBOUND_SSO_RSA_PRIVATE_KEY="${URGS_INBOUND_SSO_RSA_PRIVATE_KEY:-}"
    export RAG_BASE_URL="${RAG_BASE_URL:-http://127.0.0.1:${RAG_PORT}/api/rag}"
    export EXECUTOR_BASE_URL="${EXECUTOR_BASE_URL:-http://127.0.0.1:${EXECUTOR_PORT}}"
    export URGS_API_BASE_URL="${URGS_API_BASE_URL:-}"
    export ONLYOFFICE_DOCUMENT_SERVER_URL="${ONLYOFFICE_DOCUMENT_SERVER_URL:-http://localhost:${ONLYOFFICE_PORT}}"
    export ONLYOFFICE_CALLBACK_SECRET="${ONLYOFFICE_CALLBACK_SECRET:-urgs-onlyoffice-callback-secret}"
    export ONLYOFFICE_JWT_SECRET="${ONLYOFFICE_JWT_SECRET:-}"
    export LINEAGE_ENGINE_WORKDIR="${LINEAGE_ENGINE_WORKDIR:-${ROOT_DIR}/services/lineage}"
    export URGS_PROFILE="${URGS_PROFILE:-${DATA_ROOT}/api/uploads}"
    export IM_UPLOAD_PATH="${IM_UPLOAD_PATH:-${DATA_ROOT}/api/im-uploads}"
    export RAG_DOC_STORE_PATH="${RAG_DOC_STORE_PATH:-${DATA_ROOT}/rag/doc_store}"
    export CHROMA_PERSIST_DIRECTORY="${CHROMA_PERSIST_DIRECTORY:-${DATA_ROOT}/rag/chroma_db}"
    export DOC_STORAGE_PATH="${DOC_STORAGE_PATH:-${DATA_ROOT}/rag/doc_store}"
    export PARENT_DOC_STORE_PATH="${PARENT_DOC_STORE_PATH:-${DATA_ROOT}/rag/parent_store}"
    export CLEAN_SAMPLE_DIR="${CLEAN_SAMPLE_DIR:-${DATA_ROOT}/rag/clean_samples}"
    export DEPLOY_TOOL_WORKDIR="${DEPLOY_TOOL_WORKDIR:-${DATA_ROOT}/db_deploy}"
    export LINEAGE_ENGINE_SHARED_DIR="${LINEAGE_ENGINE_SHARED_DIR:-${DATA_ROOT}/lineage/share}"
}

start_api() {
    service_enabled api || return 0
    [ -f "${ROOT_DIR}/services/api/app.jar" ] || die "Missing services/api/app.jar"
    stop_conflicting_port api "$API_PORT"
    export_common_env
    start_background api "$JAVA_BIN" ${API_JAVA_OPTS:-} -jar "${ROOT_DIR}/services/api/app.jar" --server.port="${API_PORT}"
}

start_executor() {
    service_enabled executor || return 0
    [ -f "${ROOT_DIR}/services/executor/app.jar" ] || die "Missing services/executor/app.jar"
    stop_conflicting_port executor "$EXECUTOR_PORT"
    export_common_env
    export URGS_EXECUTOR_PORT="$EXECUTOR_PORT"
    export URGS_EXECUTOR_DB_URL="${URGS_EXECUTOR_DB_URL:-jdbc:mysql://${DB_HOST:-127.0.0.1}:${DB_PORT:-3306}/${DB_NAME:-urgs}?${MYSQL_EXECUTOR_JDBC_PARAMS}}"
    export URGS_EXECUTOR_DB_USERNAME="${URGS_EXECUTOR_DB_USERNAME:-${DB_USER:-urgs}}"
    export URGS_EXECUTOR_DB_PASSWORD="${URGS_EXECUTOR_DB_PASSWORD:-${DB_PASSWORD:-}}"
    start_background executor "$JAVA_BIN" ${EXECUTOR_JAVA_OPTS:-} -jar "${ROOT_DIR}/services/executor/app.jar"
}

ensure_venv() {
    local service="$1"
    local dir="${ROOT_DIR}/services/${service}"
    [ -d "$dir" ] || die "Missing ${dir}"
    if [ ! -x "${dir}/.venv/bin/python" ]; then
        require_command "$PYTHON_BIN"
        log "Creating Python venv for ${service}."
        "$PYTHON_BIN" -m venv "${dir}/.venv"
    fi
    if [ "$PIP_INSTALL" = "1" ] && [ -f "${dir}/requirements.txt" ]; then
        log "Installing Python dependencies for ${service}."
        "${dir}/.venv/bin/python" -m pip install -r "${dir}/requirements.txt"
    elif [ "$PIP_INSTALL" = "1" ] && [ -f "${dir}/pyproject.toml" ]; then
        log "Installing locked Python project for ${service}."
        "${dir}/.venv/bin/python" -m pip install uv==0.8.17
        (cd "$dir" && VIRTUAL_ENV="${dir}/.venv" "${dir}/.venv/bin/uv" sync --frozen --no-dev --active)
    fi
}

start_rag() {
    service_enabled rag || return 0
    ensure_venv rag
    stop_conflicting_port rag "$RAG_PORT"
    export_common_env
    export LLM_API_BASE="${LLM_API_BASE:-}"
    export LLM_MODEL="${LLM_MODEL:-}"
    export LLM_API_KEY="${LLM_API_KEY:-}"
    export URGS_API_URL="${URGS_API_URL:-http://127.0.0.1:${API_PORT}}"
    (cd "${ROOT_DIR}/services/rag" && start_background rag .venv/bin/python -m uvicorn app.main:app --host "${RAG_HOST:-0.0.0.0}" --port "$RAG_PORT")
}

start_agent() {
    service_enabled agent || return 0
    ensure_venv agent
    stop_conflicting_port agent-api "$AGENT_PORT"
    export_common_env
    export AGENT_PORT AGENT_DATABASE_URL AGENT_CHECKPOINT_DATABASE_URL AGENT_REDIS_URL
    export AGENT_OPENAI_BASE_URL AGENT_OPENAI_API_KEY AGENT_OPENAI_MODEL
    export AGENT_URGS_API_URL AGENT_RAG_URL AGENT_LINEAGE_URL AGENT_API_KEY
    export AGENT_CALLBACK_HMAC_SECRET AGENT_ENVIRONMENT AGENT_LOG_LEVEL
    (cd "${ROOT_DIR}/services/agent" && .venv/bin/python -m alembic upgrade head)
    (cd "${ROOT_DIR}/services/agent" && \
        start_background agent-api .venv/bin/python -m uvicorn urgs_agent.main:app --host "${AGENT_HOST:-0.0.0.0}" --port "$AGENT_PORT")
    (cd "${ROOT_DIR}/services/agent" && \
        start_background agent-worker .venv/bin/python -m urgs_agent.worker)
}

start_web_static() {
    service_enabled web || return 0
    [ "$START_WEB_STATIC" = "1" ] || return 0
    [ -d "${ROOT_DIR}/services/web/dist" ] || die "Missing services/web/dist"
    stop_conflicting_port web-static "$WEB_STATIC_PORT"
    (cd "${ROOT_DIR}/services/web/dist" && start_background web-static "$PYTHON_BIN" -m http.server "$WEB_STATIC_PORT")
}

render_runtime_config() {
    service_enabled web || return 0
    [ -d "${ROOT_DIR}/services/web/dist" ] || return 0
    if [ -n "${WEB_WS_URL:-}" ]; then
        cat > "${ROOT_DIR}/services/web/dist/config.js" <<EOF
window.__RUNTIME_CONFIG__ = {
    VITE_WS_URL: "${WEB_WS_URL}"
};
EOF
    elif [ -n "${PUBLIC_HOST:-}" ]; then
        cat > "${ROOT_DIR}/services/web/dist/config.js" <<EOF
window.__RUNTIME_CONFIG__ = {
    VITE_WS_URL: "ws://${PUBLIC_HOST}/ws/im"
};
EOF
    else
        cat > "${ROOT_DIR}/services/web/dist/config.js" <<'EOF'
window.__RUNTIME_CONFIG__ = {
    VITE_WS_URL: (window.location.protocol === "https:" ? "wss://" : "ws://") + window.location.host + "/ws/im"
};
EOF
    fi
}

render_api_upstream_block() {
    [ -n "$API_UPSTREAM_SERVERS" ] || return 0
    printf 'upstream urgs_api_upstream {\n'
    if [ "$API_UPSTREAM_STICKY" = "ip_hash" ]; then
        printf '    ip_hash;\n'
    elif [ "$API_UPSTREAM_STICKY" != "off" ]; then
        die "API_UPSTREAM_STICKY only supports ip_hash or off."
    fi
    printf '%s' "$API_UPSTREAM_SERVERS" | tr ',' '\n' | while IFS= read -r server || [ -n "$server" ]; do
        server="$(printf '%s' "$server" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        [ -n "$server" ] || continue
        case "$server" in
            http://* | https://*) die "API_UPSTREAM_SERVERS only accepts host:port values, for example 10.0.0.11:8080,10.0.0.12:8080." ;;
        esac
        printf '    server %s;\n' "$server"
    done
    printf '}\n'
}

render_nginx_config() {
    local template="${ROOT_DIR}/config/nginx.conf.template"
    [ -f "$template" ] || die "Missing nginx config template."
    local api_proxy_target="$API_TARGET"
    local api_upstream_block=""
    local web_root="${ROOT_DIR}/services/web/dist"
    if [ -n "$API_UPSTREAM_SERVERS" ]; then
        api_proxy_target="http://urgs_api_upstream"
        api_upstream_block="$(render_api_upstream_block)"
    fi
    local line
    while IFS= read -r line || [ -n "$line" ]; do
        if [ "$line" = "__API_UPSTREAM_BLOCK__" ]; then
            [ -n "$api_upstream_block" ] && printf '%s\n' "$api_upstream_block"
            continue
        fi
        line="${line//__WEB_LISTEN_PORT__/$WEB_LISTEN_PORT}"
        line="${line//__WEB_SERVER_NAME__/$WEB_SERVER_NAME}"
        line="${line//__WEB_ROOT__/$web_root}"
        line="${line//__API_PROXY_TARGET__/$api_proxy_target}"
        line="${line//__RAG_TARGET__/$RAG_TARGET}"
        line="${line//__IM_API_TARGET__/$IM_API_TARGET}"
        printf '%s\n' "$line"
    done < "$template"
}

render_local_nginx_config() {
    mkdir -p "$(dirname "$NGINX_LOCAL_CONF")" "$NGINX_LOG_DIR" "$PID_DIR"
    cat > "$NGINX_LOCAL_CONF" <<EOF
worker_processes auto;
error_log ${NGINX_ERROR_LOG};
pid ${ROOT_DIR}/pids/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include       ${ROOT_DIR}/config/mime.types;
    default_type  application/octet-stream;
    sendfile      on;
    keepalive_timeout 65;
    access_log ${NGINX_ACCESS_LOG};

$(render_nginx_config)
}
EOF
    cat > "${ROOT_DIR}/config/mime.types" <<'EOF'
types {
    text/html                             html htm;
    text/css                              css;
    application/javascript                js;
    application/json                      json;
    image/png                             png;
    image/jpeg                            jpg jpeg;
    image/gif                             gif;
    image/svg+xml                         svg;
    image/x-icon                          ico;
    font/woff                             woff;
    font/woff2                            woff2;
    application/wasm                      wasm;
}
EOF
}

install_nginx_config() {
    service_enabled web || return 0
    [ "$NGINX_ENABLED" = "1" ] || return 0
    render_runtime_config
    if [ "$NGINX_USE_SYSTEM" = "1" ] && [ -d "$NGINX_CONF_DIR" ]; then
        render_nginx_config > "${NGINX_CONF_DIR}/urgs.conf"
        if command -v nginx >/dev/null 2>&1; then
            nginx -t
            if command -v systemctl >/dev/null 2>&1; then
                systemctl reload nginx || systemctl restart nginx || true
            else
                nginx -s reload || true
            fi
        fi
    elif service_enabled nginx; then
        render_local_nginx_config
        log "Rendered local nginx config: ${NGINX_LOCAL_CONF}."
    else
        log "Nginx component is not selected; skip nginx config install."
    fi
}

start_nginx() {
    service_enabled web || return 0
    service_enabled nginx || return 0
    [ "$NGINX_ENABLED" = "1" ] || return 0
    extract_component_tarballs nginx
    render_runtime_config
    local nginx_bin
    nginx_bin="$(find_component_binary nginx nginx)"
    [ -n "$nginx_bin" ] || die "nginx not found. Install Nginx on target host or package with NGINX_TARBALL=/path/to/nginx.tar.gz."
    if [ "$NGINX_USE_SYSTEM" = "1" ] && [ -d "$NGINX_CONF_DIR" ]; then
        install_nginx_config
    else
        render_local_nginx_config
        stop_conflicting_port nginx "$WEB_LISTEN_PORT"
        "$nginx_bin" -p "${ROOT_DIR}/" -e "$NGINX_ERROR_LOG" -c "$NGINX_LOCAL_CONF" -t
        start_background nginx "$nginx_bin" -p "${ROOT_DIR}/" -e "$NGINX_ERROR_LOG" -c "$NGINX_LOCAL_CONF" -g "daemon off;"
    fi
}

stop_nginx() {
    service_enabled nginx || return 0
    if is_running nginx; then
        local nginx_bin
        nginx_bin="$(find_component_binary nginx nginx)"
        if [ -n "$nginx_bin" ] && [ -f "$NGINX_LOCAL_CONF" ]; then
            "$nginx_bin" -p "${ROOT_DIR}/" -e "$NGINX_ERROR_LOG" -c "$NGINX_LOCAL_CONF" -s quit >/dev/null 2>&1 || true
            sleep 1
        else
            stop_service nginx
        fi
        rm -f "$(pid_file nginx)"
    elif [ -f "$(pid_file nginx)" ]; then
        rm -f "$(pid_file nginx)"
    fi
}

install_all() {
    export_common_env
    mkdir -p "$LOG_DIR" "$PID_DIR" "$DATA_ROOT" "$URGS_PROFILE" "$IM_UPLOAD_PATH" \
        "$RAG_DOC_STORE_PATH" "$CHROMA_PERSIST_DIRECTORY" "$PARENT_DOC_STORE_PATH" \
        "$CLEAN_SAMPLE_DIR" "$DEPLOY_TOOL_WORKDIR" "$LINEAGE_ENGINE_SHARED_DIR"
    service_enabled nginx && extract_component_tarballs nginx
    service_enabled redis && extract_component_tarballs redis
    service_enabled onlyoffice && install_onlyoffice
    service_enabled rag && ensure_venv rag
    service_enabled agent && ensure_venv agent
    service_enabled lineage && ensure_venv lineage
    install_nginx_config
    log "Install step completed."
}

render_redis_config() {
    mkdir -p "$REDIS_DATA_DIR"
    cat > "${ROOT_DIR}/config/redis.conf" <<EOF
bind ${REDIS_BIND}
port ${REDIS_PORT}
dir ${REDIS_DATA_DIR}
daemonize no
protected-mode yes
appendonly yes
logfile ""
EOF
}

start_redis() {
    service_enabled redis || return 0
    extract_component_tarballs redis
    render_redis_config
    local redis_bin
    redis_bin="$(find_component_binary redis redis-server)"
    [ -n "$redis_bin" ] || die "redis-server not found. Install Redis on target host or package with REDIS_TARBALL=/path/to/redis.tar.gz."
    stop_conflicting_port redis "$REDIS_PORT"
    start_background redis "$redis_bin" "${ROOT_DIR}/config/redis.conf"
}

start_all() {
    start_redis
    start_onlyoffice
    start_rag
    start_agent
    start_executor
    start_api
    render_runtime_config
    install_nginx_config
    start_nginx
    start_web_static
    true
}

start_one() {
    case "$1" in
        api) start_api ;;
        executor) start_executor ;;
        rag) start_rag ;;
        agent) start_agent ;;
        redis) start_redis ;;
        onlyoffice) start_onlyoffice ;;
        nginx) install_nginx_config; start_nginx ;;
        web-static) start_web_static ;;
        *) die "Unknown service: $1" ;;
    esac
}

stop_all() {
    service_enabled web && stop_service web-static
    stop_nginx
    service_enabled api && stop_service api
    service_enabled executor && stop_service executor
    service_enabled rag && stop_service rag
    service_enabled agent && stop_service agent-worker
    service_enabled agent && stop_service agent-api
    service_enabled redis && stop_service redis
    stop_onlyoffice
    true
}

stop_one() {
    case "$1" in
        api | executor | rag | redis | web-static) stop_service "$1" ;;
        onlyoffice) stop_onlyoffice ;;
        agent) stop_service agent-worker; stop_service agent-api ;;
        nginx) stop_nginx ;;
        *) die "Unknown service: $1" ;;
    esac
}

status_all() {
    service_enabled api && status_service api
    service_enabled executor && status_service executor
    service_enabled rag && status_service rag
    service_enabled agent && status_service agent-api
    service_enabled agent && status_service agent-worker
    service_enabled redis && status_service redis
    service_enabled onlyoffice && status_onlyoffice
    service_enabled nginx && status_service nginx
    service_enabled web && status_service web-static
    service_enabled lineage && printf '%-12s PACKAGED cli-only\n' "lineage"
    true
}

status_one() {
    case "$1" in
        api | executor | rag | redis | nginx | web-static) status_service "$1" ;;
        onlyoffice) status_onlyoffice ;;
        agent) status_service agent-api; status_service agent-worker ;;
        *) die "Unknown service: $1" ;;
    esac
}

if [ -n "$DEPLOY_HOME" ] && [ "$PACKAGE_DIR" != "$ROOT_DIR" ]; then
    case "${1:-}" in
        -h | --help | help | "") ;;
        *)
            install_package_to_deploy_home
            SERVICES_FILE="$PACKAGE_SERVICES_FILE"
            load_env
            apply_runtime_defaults
            ;;
    esac
fi

case "${1:-}" in
    install) install_all ;;
    start) if [ -n "${2:-}" ]; then start_one "$2"; else start_all; fi ;;
    up) stop_all; install_all; start_all ;;
    stop) if [ -n "${2:-}" ]; then stop_one "$2"; else stop_all; fi ;;
    restart) if [ -n "${2:-}" ]; then stop_one "$2"; start_one "$2"; else stop_all; start_all; fi ;;
    status) if [ -n "${2:-}" ]; then status_one "$2"; else status_all; fi ;;
    nginx-config) render_nginx_config ;;
    -h | --help | help | "") usage ;;
    *) die "Unknown command: $1" ;;
esac
