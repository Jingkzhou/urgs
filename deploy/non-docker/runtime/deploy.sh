#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/config/deploy.env}"
SERVICES_FILE="${ROOT_DIR}/config/services.list"
LOG_DIR="${ROOT_DIR}/logs"
PID_DIR="${ROOT_DIR}/pids"

if [ -f "$ENV_FILE" ]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
fi

JAVA_BIN="${JAVA_BIN:-java}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
PIP_INSTALL="${PIP_INSTALL:-1}"
API_PORT="${API_PORT:-8080}"
EXECUTOR_PORT="${EXECUTOR_PORT:-8082}"
RAG_PORT="${RAG_PORT:-8001}"
WEB_LISTEN_PORT="${WEB_LISTEN_PORT:-80}"
WEB_SERVER_NAME="${WEB_SERVER_NAME:-_}"
NGINX_ENABLED="${NGINX_ENABLED:-1}"
NGINX_USE_SYSTEM="${NGINX_USE_SYSTEM:-0}"
NGINX_CONF_DIR="${NGINX_CONF_DIR:-/etc/nginx/conf.d}"
NGINX_LOCAL_CONF="${NGINX_LOCAL_CONF:-${ROOT_DIR}/config/nginx.local.conf}"
START_WEB_STATIC="${START_WEB_STATIC:-0}"
WEB_STATIC_PORT="${WEB_STATIC_PORT:-3000}"
REDIS_PORT="${REDIS_PORT:-6379}"
REDIS_BIND="${REDIS_BIND:-127.0.0.1}"
REDIS_DATA_DIR="${REDIS_DATA_DIR:-${ROOT_DIR}/data/redis}"
NGINX_LOG_DIR="${NGINX_LOG_DIR:-${ROOT_DIR}/logs/nginx}"
NGINX_ERROR_LOG="${NGINX_ERROR_LOG:-${NGINX_LOG_DIR}/error.log}"
NGINX_ACCESS_LOG="${NGINX_ACCESS_LOG:-${NGINX_LOG_DIR}/access.log}"

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
  bin/deploy.sh up               Install and start selected services.
  bin/deploy.sh stop             Stop selected services.
  bin/deploy.sh restart          Restart selected services.
  bin/deploy.sh status           Show selected service status.
  bin/deploy.sh nginx-config     Render nginx config to stdout.

Before running, edit config/deploy.env only when the package was not generated with production values.
EOF
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

export_common_env() {
    export SPRING_PROFILES_ACTIVE="${SPRING_PROFILES_ACTIVE:-prod}"
    export SPRING_DATASOURCE_URL="${SPRING_DATASOURCE_URL:-jdbc:mysql://${DB_HOST:-127.0.0.1}:${DB_PORT:-3306}/${DB_NAME:-urgs}?useSSL=false&serverTimezone=Asia/Shanghai&characterEncoding=utf8&allowPublicKeyRetrieval=true}"
    export SPRING_DATASOURCE_USERNAME="${SPRING_DATASOURCE_USERNAME:-${DB_USER:-urgs}}"
    export SPRING_DATASOURCE_PASSWORD="${SPRING_DATASOURCE_PASSWORD:-${DB_PASSWORD:-}}"
    export SPRING_NEO4J_URI="${SPRING_NEO4J_URI:-bolt://${NEO4J_HOST:-127.0.0.1}:${NEO4J_PORT_BOLT:-7687}}"
    export SPRING_NEO4J_AUTHENTICATION_USERNAME="${SPRING_NEO4J_AUTHENTICATION_USERNAME:-${NEO4J_USER:-neo4j}}"
    export SPRING_NEO4J_AUTHENTICATION_PASSWORD="${SPRING_NEO4J_AUTHENTICATION_PASSWORD:-${NEO4J_PASSWORD:-}}"
    export RAG_BASE_URL="${RAG_BASE_URL:-http://127.0.0.1:${RAG_PORT}/api/rag}"
    export EXECUTOR_BASE_URL="${EXECUTOR_BASE_URL:-http://127.0.0.1:${EXECUTOR_PORT}}"
    export LINEAGE_ENGINE_WORKDIR="${LINEAGE_ENGINE_WORKDIR:-${ROOT_DIR}/services/lineage}"
    export DEPLOY_TOOL_WORKDIR="${DEPLOY_TOOL_WORKDIR:-classpath:db_deploy}"
}

start_api() {
    service_enabled api || return 0
    [ -f "${ROOT_DIR}/services/api/app.jar" ] || die "Missing services/api/app.jar"
    export_common_env
    start_background api "$JAVA_BIN" ${API_JAVA_OPTS:-} -jar "${ROOT_DIR}/services/api/app.jar" --server.port="${API_PORT}"
}

start_executor() {
    service_enabled executor || return 0
    [ -f "${ROOT_DIR}/services/executor/app.jar" ] || die "Missing services/executor/app.jar"
    export URGS_EXECUTOR_PORT="$EXECUTOR_PORT"
    export URGS_EXECUTOR_DB_URL="${URGS_EXECUTOR_DB_URL:-jdbc:mysql://${DB_HOST:-127.0.0.1}:${DB_PORT:-3306}/${DB_NAME:-urgs}?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai}"
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
    fi
}

start_rag() {
    service_enabled rag || return 0
    ensure_venv rag
    export LLM_API_BASE="${LLM_API_BASE:-}"
    export LLM_MODEL="${LLM_MODEL:-}"
    export LLM_API_KEY="${LLM_API_KEY:-}"
    export URGS_API_URL="${URGS_API_URL:-http://127.0.0.1:${API_PORT}}"
    (cd "${ROOT_DIR}/services/rag" && start_background rag .venv/bin/python -m uvicorn app.main:app --host "${RAG_HOST:-0.0.0.0}" --port "$RAG_PORT")
}

start_web_static() {
    service_enabled web || return 0
    [ "$START_WEB_STATIC" = "1" ] || return 0
    [ -d "${ROOT_DIR}/services/web/dist" ] || die "Missing services/web/dist"
    (cd "${ROOT_DIR}/services/web/dist" && start_background web-static "$PYTHON_BIN" -m http.server "$WEB_STATIC_PORT")
}

render_runtime_config() {
    service_enabled web || return 0
    [ -d "${ROOT_DIR}/services/web/dist" ] || return 0
    local ws_host="${PUBLIC_HOST:-127.0.0.1}"
    cat > "${ROOT_DIR}/services/web/dist/config.js" <<EOF
window.__RUNTIME_CONFIG__ = {
    VITE_WS_URL: "${WEB_WS_URL:-ws://${ws_host}/ws/im}"
};
EOF
}

render_nginx_config() {
    local template="${ROOT_DIR}/config/nginx.conf.template"
    [ -f "$template" ] || die "Missing nginx config template."
    sed \
        -e "s#__WEB_LISTEN_PORT__#${WEB_LISTEN_PORT}#g" \
        -e "s#__WEB_SERVER_NAME__#${WEB_SERVER_NAME}#g" \
        -e "s#__WEB_ROOT__#${ROOT_DIR}/services/web/dist#g" \
        -e "s#__API_TARGET__#http://127.0.0.1:${API_PORT}#g" \
        -e "s#__RAG_TARGET__#http://127.0.0.1:${RAG_PORT}#g" \
        "$template"
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
    mkdir -p "$LOG_DIR" "$PID_DIR" "${ROOT_DIR}/data"
    service_enabled nginx && extract_component_tarballs nginx
    service_enabled redis && extract_component_tarballs redis
    service_enabled rag && ensure_venv rag
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
    start_background redis "$redis_bin" "${ROOT_DIR}/config/redis.conf"
}

start_all() {
    start_redis
    start_rag
    start_executor
    start_api
    render_runtime_config
    install_nginx_config
    start_nginx
    start_web_static
    true
}

stop_all() {
    service_enabled web && stop_service web-static
    stop_nginx
    service_enabled api && stop_service api
    service_enabled executor && stop_service executor
    service_enabled rag && stop_service rag
    service_enabled redis && stop_service redis
    true
}

status_all() {
    service_enabled api && status_service api
    service_enabled executor && status_service executor
    service_enabled rag && status_service rag
    service_enabled redis && status_service redis
    service_enabled nginx && status_service nginx
    service_enabled web && status_service web-static
    service_enabled lineage && printf '%-12s PACKAGED cli-only\n' "lineage"
    true
}

case "${1:-}" in
    install) install_all ;;
    start) start_all ;;
    up) install_all; start_all ;;
    stop) stop_all ;;
    restart) stop_all; start_all ;;
    status) status_all ;;
    nginx-config) render_nginx_config ;;
    -h | --help | help | "") usage ;;
    *) die "Unknown command: $1" ;;
esac
