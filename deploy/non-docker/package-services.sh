#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${OUT_DIR:-${ROOT_DIR}/dist-packages}"
COMPONENT_CACHE_DIR="${COMPONENT_CACHE_DIR:-${ROOT_DIR}/deploy/non-docker/components-cache}"
STAMP="$(date +%Y%m%d%H%M%S)"
PACKAGE_BASENAME="${PACKAGE_NAME:-urgs-nondocker-${STAMP}}"
WORK_DIR="${OUT_DIR}/${PACKAGE_BASENAME}"
SERVICES=()
CLEAN_WORK_DIR_ON_EXIT=0

usage() {
    cat <<'EOF'
Usage:
  deploy/non-docker/package-services.sh <service-or-component...>

Services:
  api          Build and package urgs-api Spring Boot service.
  web          Build and package urgs-web static frontend.
  executor     Build and package urgs-executor Spring Boot service.
  rag          Package urgs-rag Python service source and requirements.
  lineage      Package sql-lineage-engine source and requirements.

Components:
  nginx        Package nginx deployment config and NGINX_TARBALL, or latest cached ARM64 package.
  redis        Package redis config and REDIS_TARBALL, or latest cached ARM64 package.

Groups:
  app-all      api web executor rag lineage
  deps-all     nginx redis
  full         app-all deps-all

Examples:
  deploy/non-docker/package-services.sh api web
  deploy/non-docker/package-services.sh api web executor rag
  deploy/non-docker/package-services.sh full
  REDIS_TARBALL=/tmp/redis.tar.gz deploy/non-docker/package-services.sh api web redis
  NGINX_TARBALL=/tmp/nginx.tar.gz REDIS_TARBALL=/tmp/redis.tar.gz deploy/non-docker/package-services.sh full
  deploy/non-docker/build-arm64-components.sh
  deploy/non-docker/package-services.sh api web executor nginx redis
  ALLOW_HOST_COMPONENTS=1 deploy/non-docker/package-services.sh api web nginx
  REUSE_BUILD_ARTIFACTS=1 deploy/non-docker/package-services.sh api web executor nginx redis
  WEB_REUSE_DIST_IF_NO_NODE_MODULES=0 deploy/non-docker/package-services.sh web
  OUT_DIR=/tmp/urgs-packages deploy/non-docker/package-services.sh api executor

Output:
  dist-packages/<package>.tar.gz
  Set KEEP_WORK_DIR=1 to keep the expanded staging directory.
EOF
}

log() {
    printf '[nondocker-package] %s\n' "$*"
}

die() {
    printf '[nondocker-package][error] %s\n' "$*" >&2
    exit 1
}

cleanup_work_dir() {
    local status="$?"
    if [ "$status" -ne 0 ] && [ "$CLEAN_WORK_DIR_ON_EXIT" = "1" ] && [ "${KEEP_WORK_DIR:-0}" != "1" ]; then
        rm -rf "$WORK_DIR"
    fi
}

trap cleanup_work_dir EXIT

normalize_service() {
    case "$1" in
        api | urgs-api) echo "api" ;;
        web | urgs-web | frontend) echo "web" ;;
        executor | urgs-executor) echo "executor" ;;
        rag | urgs-rag) echo "rag" ;;
        lineage | sql-lineage-engine) echo "lineage" ;;
        nginx) echo "nginx" ;;
        redis) echo "redis" ;;
        *) return 1 ;;
    esac
}

has_service() {
    local expected="$1"
    local item
    [ "${#SERVICES[@]}" -gt 0 ] || return 1
    for item in "${SERVICES[@]}"; do
        [ "$item" = "$expected" ] && return 0
    done
    return 1
}

append_service() {
    local service="$1"
    if ! has_service "$service"; then
        SERVICES+=("$service")
    fi
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

component_tarball_var() {
    case "$1" in
        nginx) echo "NGINX_TARBALL" ;;
        redis) echo "REDIS_TARBALL" ;;
        *) die "Unknown component: $1" ;;
    esac
}

latest_cached_component_tarball() {
    local component="$1"
    find "$COMPONENT_CACHE_DIR" -maxdepth 1 -type f -name "${component}-linux-aarch64-*.tar.gz" 2>/dev/null | sort -V | tail -1
}

resolve_component_tarball() {
    local component="$1"
    local tarball_var
    local tarball
    tarball_var="$(component_tarball_var "$component")"
    tarball="${!tarball_var:-}"
    if [ -z "$tarball" ]; then
        tarball="$(latest_cached_component_tarball "$component")"
    fi
    printf '%s\n' "$tarball"
}

copy_with_rsync() {
    local src="$1"
    local dst="$2"
    require_command rsync
    rsync -a \
        --exclude '.git' \
        --exclude '.venv' \
        --exclude '__pycache__' \
        --exclude '.pytest_cache' \
        --exclude 'node_modules' \
        --exclude 'target' \
        --exclude 'dist' \
        --exclude 'logs' \
        "$src" "$dst"
}

latest_jar() {
    local dir="$1"
    find "$dir" -maxdepth 1 -type f -name '*.jar' ! -name '*sources.jar' ! -name '*javadoc.jar' | sort | tail -1
}

web_node_bin_dir() {
    local candidates=()
    local candidate
    if [ -n "${NODE_BIN:-}" ]; then
        candidates+=("$NODE_BIN")
    fi
    if command -v node >/dev/null 2>&1; then
        candidates+=("$(command -v node)")
    fi
    candidates+=(
        "/usr/local/bin/node"
        "/opt/homebrew/bin/node"
        "${HOME}/.nvm/versions/node/v20.14.0/bin/node"
        "${HOME}/.nvm/versions/node/v22.22.2/bin/node"
    )

    for candidate in "${candidates[@]}"; do
        [ -x "$candidate" ] || continue
        if ! node_modules_present || (cd "${ROOT_DIR}/urgs-web" && "$candidate" -e "require('rollup')" >/dev/null 2>&1); then
            dirname "$candidate"
            return 0
        fi
    done
    return 1
}

node_modules_ready() {
    local node_bin_dir
    node_bin_dir="$(web_node_bin_dir)" || return 1
    [ -d "${ROOT_DIR}/urgs-web/node_modules/.bin" ] \
        && [ -x "${ROOT_DIR}/urgs-web/node_modules/.bin/vite" ] \
        && (cd "${ROOT_DIR}/urgs-web" && PATH="${node_bin_dir}:$PATH" node -e "import('vite').then(() => require('rollup'))" >/dev/null 2>&1)
}

node_modules_present() {
    [ -d "${ROOT_DIR}/urgs-web/node_modules" ]
}

install_web_dependencies() {
    local node_bin_dir
    node_bin_dir="$(web_node_bin_dir)" || die "No usable node runtime found for urgs-web dependencies."
    require_command npm
    if [ -n "${NPM_REGISTRY:-}" ]; then
        export npm_config_registry="$NPM_REGISTRY"
    fi
    if [ -f "${ROOT_DIR}/urgs-web/package-lock.json" ]; then
        (cd "${ROOT_DIR}/urgs-web" && PATH="${node_bin_dir}:$PATH" npm ci --prefer-offline --no-audit --progress=false)
    else
        (cd "${ROOT_DIR}/urgs-web" && PATH="${node_bin_dir}:$PATH" npm install --prefer-offline --no-audit --progress=false)
    fi
}

build_web_dist() {
    local node_bin_dir
    node_bin_dir="$(web_node_bin_dir)" || die "No usable node runtime found for urgs-web build."
    (cd "${ROOT_DIR}/urgs-web" && PATH="${node_bin_dir}:$PATH" npm run build)
}

build_api() {
    if [ "${REUSE_BUILD_ARTIFACTS:-0}" = "1" ]; then
        log "Reusing existing urgs-api build artifact."
    else
        log "Building urgs-api."
        (cd "${ROOT_DIR}/urgs-api" && ./mvnw clean package -DskipTests)
    fi
    local jar
    jar="$(latest_jar "${ROOT_DIR}/urgs-api/target")"
    [ -n "$jar" ] || die "urgs-api jar was not generated."
    mkdir -p "${WORK_DIR}/services/api"
    cp "$jar" "${WORK_DIR}/services/api/app.jar"
}

build_executor() {
    if [ "${REUSE_BUILD_ARTIFACTS:-0}" = "1" ]; then
        log "Reusing existing urgs-executor build artifact."
    else
        log "Building urgs-executor."
        (cd "${ROOT_DIR}/urgs-executor" && ./mvnw clean package -DskipTests)
    fi
    local jar
    jar="$(latest_jar "${ROOT_DIR}/urgs-executor/target")"
    [ -n "$jar" ] || die "urgs-executor jar was not generated."
    mkdir -p "${WORK_DIR}/services/executor"
    cp "$jar" "${WORK_DIR}/services/executor/app.jar"
}

build_web() {
    if [ "${REUSE_BUILD_ARTIFACTS:-0}" = "1" ]; then
        log "Reusing existing urgs-web dist."
    elif node_modules_ready; then
        log "Building urgs-web with existing node_modules."
        build_web_dist
    elif node_modules_present; then
        log "urgs-web node_modules exists but the Vite/Rollup toolchain is not usable; reinstalling dependencies."
        install_web_dependencies
        build_web_dist
    elif [ "${WEB_REUSE_DIST_IF_NO_NODE_MODULES:-1}" = "1" ] && [ -d "${ROOT_DIR}/urgs-web/dist" ]; then
        log "urgs-web node_modules is missing; reusing existing dist. Set WEB_REUSE_DIST_IF_NO_NODE_MODULES=0 to force npm install and rebuild."
    else
        log "Building urgs-web."
        install_web_dependencies
        build_web_dist
    fi
    [ -d "${ROOT_DIR}/urgs-web/dist" ] || die "urgs-web dist was not generated."
    mkdir -p "${WORK_DIR}/services/web"
    cp -R "${ROOT_DIR}/urgs-web/dist" "${WORK_DIR}/services/web/dist"
}

package_rag() {
    log "Packaging urgs-rag source."
    [ -f "${ROOT_DIR}/urgs-rag/requirements.txt" ] || die "urgs-rag/requirements.txt does not exist."
    mkdir -p "${WORK_DIR}/services/rag"
    copy_with_rsync "${ROOT_DIR}/urgs-rag/" "${WORK_DIR}/services/rag/"
}

package_lineage() {
    log "Packaging sql-lineage-engine source."
    [ -f "${ROOT_DIR}/sql-lineage-engine/requirements.txt" ] || die "sql-lineage-engine/requirements.txt does not exist."
    mkdir -p "${WORK_DIR}/services/lineage"
    copy_with_rsync "${ROOT_DIR}/sql-lineage-engine/" "${WORK_DIR}/services/lineage/"
    chmod +x "${WORK_DIR}/services/lineage/run.sh" 2>/dev/null || true
}

package_component() {
    local component="$1"
    local tarball_var
    local tarball=""
    log "Packaging ${component} component descriptor."
    mkdir -p "${WORK_DIR}/components/${component}"
    tarball_var="$(component_tarball_var "$component")"
    tarball="$(resolve_component_tarball "$component")"
    if [ -n "$tarball" ]; then
        [ -f "$tarball" ] || die "${tarball_var} does not exist: ${tarball}"
        cp "$tarball" "${WORK_DIR}/components/${component}/"
    elif [ "${ALLOW_HOST_COMPONENTS:-0}" != "1" ]; then
        die "${component} was selected but ${tarball_var} was not provided. Provide ${tarball_var} for a self-contained production package, or set ALLOW_HOST_COMPONENTS=1 to rely on the target host installation."
    fi
    cat > "${WORK_DIR}/components/${component}/README.txt" <<EOF
${component} component selected.

If a tarball was supplied during packaging, it is stored in this directory.
If no tarball is present, bin/deploy.sh will use the target host installation
when possible and report a clear error for missing runtime commands.
EOF
}

validate_component_tarballs() {
    local component tarball_var tarball
    for component in "${SERVICES[@]}"; do
        case "$component" in
            nginx | redis) tarball_var="$(component_tarball_var "$component")" ;;
            *) continue ;;
        esac
        tarball="$(resolve_component_tarball "$component")"
        if [ -n "$tarball" ]; then
            [ -f "$tarball" ] || die "${tarball_var} does not exist: ${tarball}"
        elif [ "${ALLOW_HOST_COMPONENTS:-0}" != "1" ]; then
            die "${component} was selected but no package was found. Run deploy/non-docker/build-arm64-components.sh first, provide ${tarball_var}, or set ALLOW_HOST_COMPONENTS=1 to rely on the target host installation."
        fi
    done
}

write_manifest() {
    {
        printf 'package_name=%s\n' "$PACKAGE_BASENAME"
        printf 'created_at=%s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
        printf 'services=%s\n' "${SERVICES[*]}"
        if command -v git >/dev/null 2>&1 && git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            printf 'git_commit=%s\n' "$(git -C "$ROOT_DIR" rev-parse HEAD)"
        fi
    } > "${WORK_DIR}/MANIFEST"
}

prepare_work_dir() {
    rm -rf "$WORK_DIR"
    mkdir -p "${WORK_DIR}/bin" "${WORK_DIR}/config" "${WORK_DIR}/logs" "${WORK_DIR}/pids" "$OUT_DIR"
    cp "${ROOT_DIR}/deploy/non-docker/runtime/deploy.sh" "${WORK_DIR}/bin/deploy.sh"
    cp "${ROOT_DIR}/deploy/non-docker/templates/deploy.env" "${WORK_DIR}/config/deploy.env"
    cp "${ROOT_DIR}/deploy/non-docker/templates/nginx.conf.template" "${WORK_DIR}/config/nginx.conf.template"
    cp "${ROOT_DIR}/deploy/non-docker/README.md" "${WORK_DIR}/README.md"
    chmod +x "${WORK_DIR}/bin/deploy.sh"
    printf '%s\n' "${SERVICES[@]}" > "${WORK_DIR}/config/services.list"
}

create_archive() {
    log "Creating package archive."
    (cd "$OUT_DIR" && tar -czf "${PACKAGE_BASENAME}.tar.gz" "$PACKAGE_BASENAME")
    if [ "${KEEP_WORK_DIR:-0}" != "1" ]; then
        rm -rf "$WORK_DIR"
    fi
    log "Package ready: ${OUT_DIR}/${PACKAGE_BASENAME}.tar.gz"
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
fi

[ "$#" -gt 0 ] || {
    usage
    exit 1
}

for raw_service in "$@"; do
    case "$raw_service" in
        app-all)
            for service in api web executor rag lineage; do append_service "$service"; done
            ;;
        deps-all)
            for service in nginx redis; do append_service "$service"; done
            ;;
        full)
            for service in api web executor rag lineage nginx redis; do append_service "$service"; done
            ;;
        *)
            service="$(normalize_service "$raw_service")" || die "Unknown service: ${raw_service}"
            append_service "$service"
            ;;
    esac
done

if has_service api || has_service executor; then
    require_command java
fi

validate_component_tarballs
prepare_work_dir
CLEAN_WORK_DIR_ON_EXIT=1

for service in "${SERVICES[@]}"; do
    case "$service" in
        api) build_api ;;
        web) build_web ;;
        executor) build_executor ;;
        rag) package_rag ;;
        lineage) package_lineage ;;
        nginx | redis) package_component "$service" ;;
        *) die "Unhandled service: ${service}" ;;
    esac
done

write_manifest
create_archive
