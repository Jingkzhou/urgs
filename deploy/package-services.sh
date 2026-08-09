#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${OUT_DIR:-${ROOT_DIR}/dist-packages}"
COMPONENT_CACHE_DIR="${COMPONENT_CACHE_DIR:-${ROOT_DIR}/deploy/components-cache}"
DEPLOY_ENV="${DEPLOY_ENV:-${TARGET_ENV:-}}"
DEPLOY_ENV_TEMPLATE="${DEPLOY_ENV_TEMPLATE:-}"
STAMP="$(date +%Y%m%d%H%M%S)"
PACKAGE_BASENAME="${PACKAGE_NAME:-}"
WORK_DIR=""
SERVICES=()
CLEAN_WORK_DIR_ON_EXIT=0

usage() {
    cat <<'EOF'
Usage:
  deploy/package-services.sh [--env local|sit|pre|prod] <service-or-component...>

Environment config:
  --env local  Package deploy/templates/deploy.local.env as config/deploy.env.
  --env sit     Package deploy/templates/deploy.sit.env as config/deploy.env.
  --env pre     Package deploy/templates/deploy.pre.env as config/deploy.env.
  --env prod    Package deploy/templates/deploy.prod.env as config/deploy.env.
  DEPLOY_ENV can also be set to local, sit, pre, or prod.
  DEPLOY_ENV_TEMPLATE can point to an explicit env file.

Services:
  api          Build and package urgs-api Spring Boot service.
  web          Build and package urgs-web static frontend.
  executor     Build and package urgs-executor Spring Boot service.
  agent        Package urgs-agent LangGraph runtime source and lock file.
  lineage      Package sql-lineage-engine source and requirements.
  desktop      Package signed Windows updater artifacts from a local source or GitHub for Nginx.

Components:
  nginx        Package nginx deployment config and NGINX_TARBALL, or latest cached ARM64 package.
  redis        Package redis config and REDIS_TARBALL, or latest cached ARM64 package.
  onlyoffice   Package official ARM64 ONLYOFFICE Document Server DEB.

Groups:
  app-all      api web executor agent lineage
  deps-all     nginx redis onlyoffice
  full         app-all deps-all

Examples:
  DEPLOY_ENV=prod deploy/package-services.sh full
  DEPLOY_ENV=local deploy/package-services.sh api web executor nginx desktop
  DEPLOY_ENV=local DESKTOP_UPDATER_SOURCE_DIR=/tmp/urgs-windows deploy/package-services.sh api web executor nginx desktop
  deploy/package-services.sh --env pre full
  deploy/package-services.sh --env sit api web nginx redis
  deploy/package-services.sh api web
  DEPLOY_ENV=sit deploy/package-services.sh api web executor nginx desktop
  DEPLOY_ENV=sit DESKTOP_UPDATER_SOURCE_DIR=/tmp/urgs-windows deploy/package-services.sh api web executor nginx desktop
  deploy/package-services.sh full
  REDIS_TARBALL=/tmp/redis.tar.gz deploy/package-services.sh api web redis
  NGINX_TARBALL=/tmp/nginx.tar.gz REDIS_TARBALL=/tmp/redis.tar.gz deploy/package-services.sh full
  deploy/build-arm64-components.sh
  deploy/package-services.sh api web executor nginx redis
  ALLOW_HOST_COMPONENTS=1 deploy/package-services.sh api web nginx
  REUSE_BUILD_ARTIFACTS=1 deploy/package-services.sh api web executor nginx redis
  WEB_REUSE_DIST_IF_NO_NODE_MODULES=0 deploy/package-services.sh web
  OUT_DIR=/tmp/urgs-packages deploy/package-services.sh api executor

Output:
  dist-packages/urgs-<env>-<timestamp>.tar.gz, unless PACKAGE_NAME is set.
  Set KEEP_WORK_DIR=1 to keep the expanded staging directory.
EOF
}

log() {
    printf '[deploy-package] %s\n' "$*"
}

die() {
    printf '[deploy-package][error] %s\n' "$*" >&2
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
        agent | urgs-agent) echo "agent" ;;
        lineage | sql-lineage-engine) echo "lineage" ;;
        desktop | desktop-updater | windows-app) echo "desktop" ;;
        nginx) echo "nginx" ;;
        redis) echo "redis" ;;
        onlyoffice | onlyoffice-docs | documentserver) echo "onlyoffice" ;;
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
        onlyoffice) echo "ONLYOFFICE_PACKAGE" ;;
        *) die "Unknown component: $1" ;;
    esac
}

latest_cached_component_tarball() {
    local component="$1"
    if [ "$component" = "onlyoffice" ]; then
        find "$COMPONENT_CACHE_DIR" -maxdepth 1 -type f -name 'onlyoffice-documentserver_*_arm64.deb' 2>/dev/null | sort -V | tail -1
        return
    fi
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

normalize_deploy_env() {
    local env_name
    env_name="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
    case "$env_name" in
        local) echo "local" ;;
        sit | test) echo "sit" ;;
        pre | preprod | pre-production | pre_production | uat) echo "pre" ;;
        prod | production) echo "prod" ;;
        *) return 1 ;;
    esac
}

resolve_deploy_env_template() {
    local env_name
    if [ -n "$DEPLOY_ENV_TEMPLATE" ]; then
        [ -f "$DEPLOY_ENV_TEMPLATE" ] || die "DEPLOY_ENV_TEMPLATE does not exist: ${DEPLOY_ENV_TEMPLATE}"
        printf '%s\n' "$DEPLOY_ENV_TEMPLATE"
        return 0
    fi

    if [ -z "$DEPLOY_ENV" ]; then
        printf '%s\n' "${ROOT_DIR}/deploy/templates/deploy.env"
        return 0
    fi

    env_name="$(normalize_deploy_env "$DEPLOY_ENV")" || die "Unknown DEPLOY_ENV: ${DEPLOY_ENV}. Expected local, sit, pre, or prod."
    printf '%s\n' "${ROOT_DIR}/deploy/templates/deploy.${env_name}.env"
}

package_env_label() {
    if [ -n "$DEPLOY_ENV" ]; then
        normalize_deploy_env "$DEPLOY_ENV" || die "Unknown DEPLOY_ENV: ${DEPLOY_ENV}. Expected local, sit, pre, or prod."
        return 0
    fi

    if [ -n "$DEPLOY_ENV_TEMPLATE" ]; then
        printf 'custom\n'
        return 0
    fi

    printf 'default\n'
}

configure_package_name() {
    local env_label
    env_label="$(package_env_label)"
    PACKAGE_BASENAME="${PACKAGE_BASENAME:-urgs-${env_label}-${STAMP}}"
    WORK_DIR="${OUT_DIR}/${PACKAGE_BASENAME}"
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
        if "$candidate" --version >/dev/null 2>&1; then
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
    if [ -n "${NPM_REGISTRY:-}" ]; then
        export npm_config_registry="$NPM_REGISTRY"
    fi
    if [ -f "${ROOT_DIR}/urgs-web/pnpm-lock.yaml" ]; then
        if command -v pnpm >/dev/null 2>&1; then
            (cd "${ROOT_DIR}/urgs-web" && PATH="${node_bin_dir}:$PATH" pnpm install --frozen-lockfile)
        elif command -v corepack >/dev/null 2>&1; then
            (cd "${ROOT_DIR}/urgs-web" && PATH="${node_bin_dir}:$PATH" corepack pnpm install --frozen-lockfile)
        else
            die "urgs-web uses pnpm-lock.yaml, but pnpm/corepack is not available. Install Node.js with Corepack enabled."
        fi
    elif [ -f "${ROOT_DIR}/urgs-web/package-lock.json" ]; then
        require_command npm
        (cd "${ROOT_DIR}/urgs-web" && PATH="${node_bin_dir}:$PATH" npm ci --prefer-offline --no-audit --progress=false)
    else
        require_command npm
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

package_agent() {
    log "Packaging urgs-agent source."
    [ -f "${ROOT_DIR}/urgs-agent/pyproject.toml" ] || die "urgs-agent/pyproject.toml does not exist."
    [ -f "${ROOT_DIR}/urgs-agent/uv.lock" ] || die "urgs-agent/uv.lock does not exist. Run uv sync first."
    mkdir -p "${WORK_DIR}/services/agent"
    copy_with_rsync "${ROOT_DIR}/urgs-agent/" "${WORK_DIR}/services/agent/"
}

package_lineage() {
    log "Packaging sql-lineage-engine source."
    [ -f "${ROOT_DIR}/sql-lineage-engine/requirements.txt" ] || die "sql-lineage-engine/requirements.txt does not exist."
    mkdir -p "${WORK_DIR}/services/lineage"
    copy_with_rsync "${ROOT_DIR}/sql-lineage-engine/" "${WORK_DIR}/services/lineage/"
    chmod +x "${WORK_DIR}/services/lineage/run.sh" 2>/dev/null || true
}

deploy_env_value() {
    local env_file="$1"
    local key="$2"
    sed -n -E "s/^[[:space:]]*${key}[[:space:]]*=[[:space:]]*//p" "$env_file" | tail -1
}

desktop_version() {
    node -e 'const fs = require("fs"); console.log(JSON.parse(fs.readFileSync("urgs-desktop/src-tauri/tauri.conf.json", "utf8")).version);'
}

github_api_request() {
    local method="$1"
    local endpoint="$2"
    local token="$3"
    local data="${4:-}"
    local max_attempts=1
    local attempt
    if [ "$method" = "GET" ]; then
        max_attempts="${GITHUB_API_GET_RETRIES:-4}"
    fi
    if command -v gh >/dev/null 2>&1 && gh auth status --hostname github.com >/dev/null 2>&1; then
        for attempt in $(seq 1 "$max_attempts"); do
            if [ -n "$data" ]; then
                if printf '%s' "$data" | gh api --method "$method" "$endpoint" --input -; then
                    return 0
                fi
            elif gh api --method "$method" "$endpoint"; then
                return 0
            fi
            [ "$attempt" -lt "$max_attempts" ] || return 1
            sleep "${GITHUB_API_RETRY_DELAY_SECONDS:-2}"
        done
    fi

    local args=(
        --fail --silent --show-error --location --retry 4 --retry-all-errors
        --request "$method"
        --header "Accept: application/vnd.github+json"
        --header "Authorization: Bearer ${token}"
        --header "X-GitHub-Api-Version: 2022-11-28"
    )
    [ -n "$data" ] && args+=(--header "Content-Type: application/json" --data "$data")
    curl "${args[@]}" "https://api.github.com${endpoint}"
}

github_repository() {
    local remote_url
    local repository="${DESKTOP_UPDATER_GITHUB_REPOSITORY:-}"
    if [ -n "$repository" ]; then
        printf '%s\n' "${repository%.git}"
        return 0
    fi
    remote_url="$(git -C "$ROOT_DIR" remote get-url origin 2>/dev/null || true)"
    case "$remote_url" in
        git@github.com:*) repository="${remote_url#git@github.com:}" ;;
        https://github.com/*) repository="${remote_url#https://github.com/}" ;;
        ssh://git@github.com/*) repository="${remote_url#ssh://git@github.com/}" ;;
        *) die "Cannot determine the GitHub repository from origin. Set DESKTOP_UPDATER_GITHUB_REPOSITORY=owner/repository." ;;
    esac
    printf '%s\n' "${repository%.git}"
}

ensure_github_ref_is_pushed() {
    local ref="${DESKTOP_UPDATER_GITHUB_REF:-}"
    local local_commit
    local remote_commit
    if [ -z "$ref" ]; then
        ref="$(git -C "$ROOT_DIR" branch --show-current)"
    fi
    [ -n "$ref" ] || die "Cannot build the desktop updater from a detached HEAD. Set DESKTOP_UPDATER_GITHUB_REF to a pushed branch."
    git -C "$ROOT_DIR" diff --quiet || die "Desktop updater GitHub build only sees pushed code. Commit and push tracked changes first, then rerun this command."
    git -C "$ROOT_DIR" diff --cached --quiet || die "Desktop updater GitHub build only sees pushed code. Commit and push staged changes first, then rerun this command."
    local_commit="$(git -C "$ROOT_DIR" rev-parse "$ref")"
    remote_commit="$(git -C "$ROOT_DIR" ls-remote --heads origin "refs/heads/${ref}" | awk 'NR == 1 { print $1 }')"
    [ -n "$remote_commit" ] || die "The branch ${ref} does not exist on origin. Push it before requesting the GitHub updater build."
    [ "$local_commit" = "$remote_commit" ] || die "Local ${ref} is not fully pushed to origin. Push it before requesting the GitHub updater build."
    DESKTOP_UPDATER_GITHUB_REF_RESOLVED="$ref"
}

json_value() {
    local expression="$1"
    shift
    node -e "$expression" "$@"
}

fetch_desktop_updater_from_github() {
    local environment="$1"
    local token="${DESKTOP_UPDATER_GITHUB_TOKEN:-${GITHUB_TOKEN:-}}"
    local repository
    local request_id
    local workflow_file="urgs-desktop-release.yml"
    local payload
    local runs_json
    local run_id=""
    local run_json
    local run_status
    local run_conclusion
    local artifacts_json
    local artifact_url
    local artifact_size_bytes
    local artifact_dir
    local artifact_zip
    local attempt

    if [ -z "$token" ] && command -v gh >/dev/null 2>&1; then
        token="$(gh auth token 2>/dev/null || true)"
    fi
    [ -n "$token" ] || die "desktop was selected without DESKTOP_UPDATER_SOURCE_DIR. Set DESKTOP_UPDATER_GITHUB_TOKEN (or GITHUB_TOKEN), or run gh auth login once so the script can trigger and download GitHub Actions artifacts."
    require_command curl
    require_command unzip
    require_command node
    ensure_github_ref_is_pushed
    repository="$(github_repository)"
    request_id="urgs-${environment}-$(date +%Y%m%d%H%M%S)-$$"
    payload="$(node -e 'console.log(JSON.stringify({ref: process.argv[1], inputs: {deploy_env: process.argv[2], request_id: process.argv[3]}}))' "$DESKTOP_UPDATER_GITHUB_REF_RESOLVED" "$environment" "$request_id")"

    log "Requesting GitHub Actions signed Windows updater build (${environment}, ${DESKTOP_UPDATER_GITHUB_REF_RESOLVED})."
    github_api_request POST "/repos/${repository}/actions/workflows/${workflow_file}/dispatches" "$token" "$payload" >/dev/null

    for attempt in $(seq 1 24); do
        sleep 5
        runs_json="$(github_api_request GET "/repos/${repository}/actions/workflows/${workflow_file}/runs?event=workflow_dispatch&branch=${DESKTOP_UPDATER_GITHUB_REF_RESOLVED}&per_page=20" "$token")"
        run_id="$(printf '%s' "$runs_json" | json_value 'const fs = require("fs"); const requestId = process.argv[1]; const data = JSON.parse(fs.readFileSync(0, "utf8")); const run = (data.workflow_runs || []).find((item) => item.display_title && item.display_title.includes(requestId)); if (run) process.stdout.write(String(run.id));' "$request_id")"
        [ -n "$run_id" ] && break
        if [ $((attempt % 4)) -eq 0 ]; then
            log "Still waiting for GitHub Actions run creation (${attempt}/24 checks)."
        fi
    done
    [ -n "$run_id" ] || die "GitHub Actions did not create the updater build within two minutes. Check the Actions page and retry."

    log "Waiting for GitHub Actions run ${run_id}."
    for attempt in $(seq 1 240); do
        run_json="$(github_api_request GET "/repos/${repository}/actions/runs/${run_id}" "$token")"
        run_status="$(printf '%s' "$run_json" | json_value 'const fs = require("fs"); process.stdout.write(JSON.parse(fs.readFileSync(0, "utf8")).status || "");')"
        if [ "$run_status" = "completed" ]; then
            run_conclusion="$(printf '%s' "$run_json" | json_value 'const fs = require("fs"); process.stdout.write(JSON.parse(fs.readFileSync(0, "utf8")).conclusion || "");')"
            [ "$run_conclusion" = "success" ] || die "GitHub Actions updater build ${run_id} ended with ${run_conclusion}."
            break
        fi
        if [ $((attempt % 4)) -eq 0 ]; then
            log "GitHub Actions run ${run_id} status=${run_status} (${attempt}/240 checks)."
        fi
        sleep 15
    done
    [ "${run_status:-}" = "completed" ] || die "GitHub Actions updater build ${run_id} timed out after one hour."

    artifacts_json="$(github_api_request GET "/repos/${repository}/actions/runs/${run_id}/artifacts" "$token")"
    artifact_url="$(printf '%s' "$artifacts_json" | json_value 'const fs = require("fs"); const name = process.argv[1]; const data = JSON.parse(fs.readFileSync(0, "utf8")); const artifact = (data.artifacts || []).find((item) => item.name === name && !item.expired); if (artifact) process.stdout.write(artifact.archive_download_url);' "urgs-windows-updater-${environment}-${request_id}")"
    [ -n "$artifact_url" ] || die "GitHub Actions succeeded but the signed updater artifact was not found."
    artifact_size_bytes="$(printf '%s' "$artifacts_json" | json_value 'const fs = require("fs"); const name = process.argv[1]; const data = JSON.parse(fs.readFileSync(0, "utf8")); const artifact = (data.artifacts || []).find((item) => item.name === name && !item.expired); if (artifact && artifact.size_in_bytes) process.stdout.write(String(artifact.size_in_bytes));' "urgs-windows-updater-${environment}-${request_id}")"

    artifact_dir="${DESKTOP_UPDATER_ARTIFACT_DIR:-${ROOT_DIR}/deploy/artifacts/windows-updater/${environment}/${request_id}}"
    artifact_zip="${artifact_dir}/github-actions-artifact.zip"
    mkdir -p "$artifact_dir"
    if [ -n "$artifact_size_bytes" ]; then
        log "Downloading signed Windows updater artifact to ${artifact_dir} (${artifact_size_bytes} bytes)."
    else
        log "Downloading signed Windows updater artifact to ${artifact_dir}."
    fi
    curl --progress-bar --continue-at - --config - --output "$artifact_zip" "$artifact_url" <<EOF
fail
show-error
location
retry = 4
retry-all-errors
header = "Accept: application/vnd.github+json"
header = "Authorization: Bearer ${token}"
header = "X-GitHub-Api-Version: 2022-11-28"
EOF
    unzip -q -o "$artifact_zip" -d "$artifact_dir"
    DESKTOP_UPDATER_DOWNLOADED_SOURCE_DIR="$artifact_dir"
}

package_desktop() {
    local source_dir="${DESKTOP_UPDATER_SOURCE_DIR:-}"
    local deploy_env_file
    local environment
    local updater_base_url
    local version

    require_command node
    environment="$(normalize_deploy_env "$DEPLOY_ENV")" || die "desktop requires DEPLOY_ENV=local, sit, or prod."
    case "$environment" in
        local | sit | prod) ;;
        *) die "desktop only supports DEPLOY_ENV=local, sit, or DEPLOY_ENV=prod." ;;
    esac
    if [ -z "$source_dir" ]; then
        fetch_desktop_updater_from_github "$environment"
        source_dir="$DESKTOP_UPDATER_DOWNLOADED_SOURCE_DIR"
    fi
    [ -d "$source_dir" ] || die "DESKTOP_UPDATER_SOURCE_DIR does not exist: ${source_dir}"
    deploy_env_file="$(resolve_deploy_env_template)"
    updater_base_url="$(deploy_env_value "$deploy_env_file" "DESKTOP_UPDATER_BASE_URL")"
    [ -n "$updater_base_url" ] || die "desktop was selected but DESKTOP_UPDATER_BASE_URL is missing from ${deploy_env_file}"
    version="$(cd "$ROOT_DIR" && desktop_version)"

    log "Packaging signed Windows updater artifacts for ${updater_base_url}."
    node "${ROOT_DIR}/deploy/prepare-desktop-updater.mjs" \
        --source "$source_dir" \
        --output "${WORK_DIR}/services/desktop-updater" \
        --base-url "$updater_base_url" \
        --version "$version"
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

If a component package was supplied during packaging, it is stored in this directory.
If no package is present, bin/deploy.sh will use the target host installation
when possible and report a clear error for missing runtime commands.
EOF
}

validate_component_tarballs() {
    local component tarball_var tarball
    for component in "${SERVICES[@]}"; do
        case "$component" in
            nginx | redis | onlyoffice) tarball_var="$(component_tarball_var "$component")" ;;
            *) continue ;;
        esac
        tarball="$(resolve_component_tarball "$component")"
        if [ -n "$tarball" ]; then
            [ -f "$tarball" ] || die "${tarball_var} does not exist: ${tarball}"
        elif [ "${ALLOW_HOST_COMPONENTS:-0}" != "1" ]; then
            die "${component} was selected but no package was found. Run deploy/build-arm64-components.sh first, provide ${tarball_var}, or set ALLOW_HOST_COMPONENTS=1 to rely on the target host installation."
        fi
    done
}

write_manifest() {
    {
        printf 'package_name=%s\n' "$PACKAGE_BASENAME"
        printf 'created_at=%s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
        printf 'services=%s\n' "${SERVICES[*]}"
        if [ -n "$DEPLOY_ENV" ]; then
            printf 'deploy_env=%s\n' "$(normalize_deploy_env "$DEPLOY_ENV")"
        fi
        printf 'deploy_env_template=%s\n' "$(resolve_deploy_env_template)"
        if command -v git >/dev/null 2>&1 && git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            printf 'git_commit=%s\n' "$(git -C "$ROOT_DIR" rev-parse HEAD)"
        fi
    } > "${WORK_DIR}/MANIFEST"
}

prepare_work_dir() {
    local deploy_env_file
    deploy_env_file="$(resolve_deploy_env_template)"
    [ -f "$deploy_env_file" ] || die "Deploy env template does not exist: ${deploy_env_file}"

    rm -rf "$WORK_DIR"
    mkdir -p "${WORK_DIR}/bin" "${WORK_DIR}/config" "${WORK_DIR}/logs" "${WORK_DIR}/pids" "$OUT_DIR"
    cp "${ROOT_DIR}/deploy/runtime/deploy.sh" "${WORK_DIR}/bin/deploy.sh"
    cp "$deploy_env_file" "${WORK_DIR}/config/deploy.env"
    cp "${ROOT_DIR}/deploy/templates/nginx.conf.template" "${WORK_DIR}/config/nginx.conf.template"
    cp "${ROOT_DIR}/deploy/README.md" "${WORK_DIR}/README.md"
    chmod +x "${WORK_DIR}/bin/deploy.sh"
    printf '%s\n' "${SERVICES[@]}" > "${WORK_DIR}/config/services.list"
}

create_archive() {
    log "Creating package archive."
    (
        cd "$OUT_DIR"
        COPYFILE_DISABLE=1 COPY_EXTENDED_ATTRIBUTES_DISABLE=1 tar --no-xattrs \
            --exclude '._*' \
            --exclude '__MACOSX' \
            -czf "${PACKAGE_BASENAME}.tar.gz" "$PACKAGE_BASENAME"
    )
    if [ "${KEEP_WORK_DIR:-0}" != "1" ]; then
        rm -rf "$WORK_DIR"
    fi
    log "Package ready: ${OUT_DIR}/${PACKAGE_BASENAME}.tar.gz"
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
fi

ARGS=()
while [ "$#" -gt 0 ]; do
    case "$1" in
        --env)
            shift
            [ -n "${1:-}" ] || die "--env requires local, sit, pre, or prod."
            DEPLOY_ENV="$1"
            ;;
        --env=*)
            DEPLOY_ENV="${1#--env=}"
            ;;
        *)
            ARGS+=("$1")
            ;;
    esac
    shift
done

[ "${#ARGS[@]}" -gt 0 ] || {
    usage
    exit 1
}

configure_package_name

for raw_service in "${ARGS[@]}"; do
    case "$raw_service" in
        app-all)
            for service in api web executor agent lineage; do append_service "$service"; done
            ;;
        deps-all)
            for service in nginx redis onlyoffice; do append_service "$service"; done
            ;;
        full)
            for service in api web executor agent lineage nginx redis onlyoffice; do append_service "$service"; done
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
        agent) package_agent ;;
        lineage) package_lineage ;;
        desktop) package_desktop ;;
        nginx | redis | onlyoffice) package_component "$service" ;;
        *) die "Unhandled service: ${service}" ;;
    esac
done

write_manifest
create_archive
