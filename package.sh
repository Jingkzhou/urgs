#!/usr/bin/env bash
set -euo pipefail

# URGS offline package builder.
# Run this script on an internet-connected build machine. The generated
# distribution directory can be copied to an intranet Linux server and installed
# without external network access.

BUILD_ARCH="${BUILD_ARCH:-linux/arm64}"
if [ -z "${TARGET_ARCH:-}" ]; then
    case "$BUILD_ARCH" in
        linux/arm64) TARGET_ARCH="aarch64" ;;
        linux/amd64) TARGET_ARCH="x86_64" ;;
        *) TARGET_ARCH="${BUILD_ARCH#linux/}" ;;
    esac
fi
DIST_DIR="${DIST_DIR:-urgs-dist}"
PACKAGE_NAME="${PACKAGE_NAME:-urgs-offline-${TARGET_ARCH}-$(date +%Y%m%d%H%M%S)}"
BUILDX_BUILDER_NAME="${BUILDX_BUILDER:-}"
INCLUDE_DOCKER_BINARIES="${INCLUDE_DOCKER_BINARIES:-1}"
DOCKER_VERSION="${DOCKER_VERSION:-29.0.4}"
COMPOSE_VERSION="${COMPOSE_VERSION:-v2.40.3}"
DOCKER_STATIC_URL="${DOCKER_STATIC_URL:-https://download.docker.com/linux/static/stable/${TARGET_ARCH}/docker-${DOCKER_VERSION}.tgz}"
COMPOSE_URL="${COMPOSE_URL:-https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${TARGET_ARCH}}"

usage() {
    cat <<'EOF'
Usage:
  ./package.sh [module...]

Examples:
  ./package.sh                         # Package default URGS services for ARM64.
  ./package.sh api web executor        # Package selected services.
  BUILD_ARCH=linux/arm64 ./package.sh  # Explicit ARM64 build.
  BUILD_ARCH=linux/amd64 ./package.sh  # Previous x86_64/amd64 build.

Environment:
  INCLUDE_DOCKER_BINARIES=1            Include Docker Engine and Compose binaries.
  DOCKER_VERSION=29.0.4                Docker static binary version to download.
  COMPOSE_VERSION=v2.40.3              Docker Compose plugin version to download.
  DIST_DIR=urgs-dist                   Output directory.

Modules:
  mysql, api, web, executor, rag, lineage, neo4j, presentation,
  dify-api, dify-web, dify-worker, dify-db, dify-redis, dify-nginx, dify-weaviate
EOF
}

log() {
    printf '[package] %s\n' "$*"
}

die() {
    printf '[package][error] %s\n' "$*" >&2
    exit 1
}

append_unique() {
    local value="$1"
    local existing
    for existing in "${IMAGES_TO_SAVE[@]}"; do
        [ "$existing" = "$value" ] && return
    done
    IMAGES_TO_SAVE+=("$value")
}

get_image() {
    case "$1" in
        api) echo "urgs-api:latest" ;;
        mysql) echo "mysql:8.4" ;;
        web) echo "urgs-web:latest" ;;
        executor) echo "urgs-executor:latest" ;;
        rag) echo "urgs-rag:latest" ;;
        lineage) echo "sql-lineage-engine:latest" ;;
        neo4j) echo "neo4j:5.15.0" ;;
        presentation) echo "urgs-presentation:latest" ;;
        dify-api | dify-worker) echo "urgs-dify-api:latest" ;;
        dify-web) echo "urgs-dify-web:latest" ;;
        dify-db) echo "postgres:15-alpine" ;;
        dify-redis) echo "redis:6-alpine" ;;
        dify-nginx) echo "nginx:latest" ;;
        dify-weaviate) echo "semitechnologies/weaviate:1.19.0" ;;
        *) echo "" ;;
    esac
}

get_service_name() {
    case "$1" in
        api) echo "urgs-api" ;;
        mysql) echo "urgs-mysql" ;;
        web) echo "urgs-web" ;;
        executor) echo "urgs-executor" ;;
        rag) echo "urgs-rag" ;;
        lineage) echo "sql-lineage-engine" ;;
        neo4j) echo "neo4j" ;;
        presentation) echo "urgs-presentation" ;;
        dify-api) echo "urgs-dify-api" ;;
        dify-web) echo "urgs-dify-web" ;;
        dify-worker) echo "urgs-dify-worker" ;;
        dify-db) echo "urgs-dify-db" ;;
        dify-redis) echo "urgs-dify-redis" ;;
        dify-nginx) echo "urgs-dify-nginx" ;;
        dify-weaviate) echo "urgs-dify-weaviate" ;;
        *) echo "" ;;
    esac
}

get_build_context() {
    case "$1" in
        api) echo "urgs-api" ;;
        web) echo "urgs-web" ;;
        executor) echo "urgs-executor" ;;
        rag) echo "urgs-rag" ;;
        lineage) echo "sql-lineage-engine" ;;
        presentation) echo "urgs+-presentation-platform" ;;
        dify-api | dify-worker) echo "urgs-dify/api" ;;
        dify-web) echo "urgs-dify/web" ;;
        *) echo "" ;;
    esac
}

requires_dify_files() {
    case "$1" in
        dify-api | dify-web | dify-worker | dify-nginx) return 0 ;;
        *) return 1 ;;
    esac
}

register_qemu() {
    log "Checking Docker buildx builder for ${BUILD_ARCH}."
    if [ -n "$BUILDX_BUILDER_NAME" ]; then
        docker buildx use "$BUILDX_BUILDER_NAME"
        return
    fi

    if docker buildx inspect desktop-linux >/dev/null 2>&1 &&
        docker buildx inspect desktop-linux | grep -q "Driver: docker"; then
        BUILDX_BUILDER_NAME="desktop-linux"
        docker buildx use "$BUILDX_BUILDER_NAME"
        return
    fi

    BUILDX_BUILDER_NAME="urgs_offline_builder"
    if ! docker buildx inspect "$BUILDX_BUILDER_NAME" >/dev/null 2>&1; then
        docker buildx create --use --name "$BUILDX_BUILDER_NAME" --platform "$BUILD_ARCH" >/dev/null
    fi
    docker buildx use "$BUILDX_BUILDER_NAME"
}

validate_prerequisites() {
    command -v docker >/dev/null 2>&1 || die "Docker is required on the build machine."
    docker compose version >/dev/null 2>&1 || die "Docker Compose plugin is required on the build machine."
    docker buildx version >/dev/null 2>&1 || die "Docker buildx is required on the build machine."

    local module context
    for module in "${SELECTED_MODULES[@]}"; do
        context="$(get_build_context "$module")"
        if [ -n "$context" ] && [ ! -d "$context" ]; then
            die "Module '${module}' requires build context '${context}', but it does not exist. Initialize that dependency first or remove the module."
        fi
        if requires_dify_files "$module" && [ ! -d "urgs-dify" ]; then
            die "Module '${module}' requires 'urgs-dify', but this working tree does not contain it."
        fi
    done
}

build_selected_images() {
    log "Building project images for ${BUILD_ARCH}."
    export DOCKER_BUILDKIT=1
    export DOCKER_DEFAULT_PLATFORM="$BUILD_ARCH"

    local module service context
    for module in "${SELECTED_MODULES[@]}"; do
        context="$(get_build_context "$module")"
        [ -z "$context" ] && continue
        service="$(get_service_name "$module")"
        log "Building ${service}."
        docker compose build "$service"
    done
}

pull_external_images() {
    log "Pulling third-party dependency images for ${BUILD_ARCH}."
    local module image
    for module in "${SELECTED_MODULES[@]}"; do
        [ -n "$(get_build_context "$module")" ] && continue
        image="$(get_image "$module")"
        [ -z "$image" ] && continue
        log "Pulling ${image}."
        docker pull --platform "$BUILD_ARCH" "$image"
    done
}

prepare_dist() {
    rm -rf "$DIST_DIR"
    mkdir -p "$DIST_DIR/images" "$DIST_DIR/runtime" "$DIST_DIR/docker"

    cp docker-compose.yml "$DIST_DIR/docker-compose.yml"
    if [ -f .env.prod ]; then
        cp .env.prod "$DIST_DIR/.env"
    elif [ -f .env.example ]; then
        cp .env.example "$DIST_DIR/.env"
    else
        : > "$DIST_DIR/.env"
    fi

    if printf '%s\n' "${SELECTED_MODULES[@]}" | grep -qx "mysql"; then
        if grep -q '^DB_HOST=' "$DIST_DIR/.env"; then
            sed -i.bak 's/^DB_HOST=.*/DB_HOST=urgs-mysql/' "$DIST_DIR/.env"
            rm -f "$DIST_DIR/.env.bak"
        else
            echo "DB_HOST=urgs-mysql" >> "$DIST_DIR/.env"
        fi
        if ! grep -q '^MYSQL_ROOT_PASSWORD=' "$DIST_DIR/.env"; then
            printf '\nMYSQL_ROOT_PASSWORD=%s\n' "$(grep '^DB_PASSWORD=' "$DIST_DIR/.env" | cut -d= -f2-)" >> "$DIST_DIR/.env"
        fi
    fi

    if [ -d "urgs-dify/docker/nginx" ]; then
        mkdir -p "$DIST_DIR/urgs-dify/docker"
        cp -R "urgs-dify/docker/nginx" "$DIST_DIR/urgs-dify/docker/"
    fi
    if [ -d "urgs-dify/api/storage" ]; then
        mkdir -p "$DIST_DIR/urgs-dify/api"
        cp -R "urgs-dify/api/storage" "$DIST_DIR/urgs-dify/api/"
    fi
}

save_images() {
    IMAGES_TO_SAVE=()

    local module image
    for module in "${SELECTED_MODULES[@]}"; do
        image="$(get_image "$module")"
        [ -n "$image" ] && append_unique "$image"
    done

    [ "${#IMAGES_TO_SAVE[@]}" -gt 0 ] || die "No images selected."

    log "Saving images to ${DIST_DIR}/images/urgs-images.tar."
    docker save -o "$DIST_DIR/images/urgs-images.tar" "${IMAGES_TO_SAVE[@]}"
}

download_docker_binaries() {
    [ "$INCLUDE_DOCKER_BINARIES" = "1" ] || return
    command -v curl >/dev/null 2>&1 || die "curl is required when INCLUDE_DOCKER_BINARIES=1."

    log "Downloading Docker Engine static binary: ${DOCKER_STATIC_URL}"
    curl -fL --retry 3 -o "$DIST_DIR/docker/docker-${DOCKER_VERSION}.tgz" "$DOCKER_STATIC_URL"

    log "Downloading Docker Compose plugin: ${COMPOSE_URL}"
    curl -fL --retry 3 -o "$DIST_DIR/docker/docker-compose-linux-${TARGET_ARCH}" "$COMPOSE_URL"
    chmod +x "$DIST_DIR/docker/docker-compose-linux-${TARGET_ARCH}"
}

write_installer() {
    local services_text
    services_text=""
    local module service
    for module in "${SELECTED_MODULES[@]}"; do
        service="$(get_service_name "$module")"
        [ -n "$service" ] && services_text="${services_text} ${service}"
    done

    cat > "$DIST_DIR/install.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

SERVICES="${services_text# }"
PACKAGE_TARGET_ARCH="${TARGET_ARCH}"
ROOT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="\${ROOT_DIR}/docker-compose.yml"
ENV_FILE="\${ROOT_DIR}/.env"
IMAGE_TAR="\${ROOT_DIR}/images/urgs-images.tar"
DOCKER_TGZ="\$(find "\${ROOT_DIR}/docker" -maxdepth 1 -name 'docker-*.tgz' | head -n 1 || true)"
COMPOSE_BIN="\$(find "\${ROOT_DIR}/docker" -maxdepth 1 -name 'docker-compose-linux-*' | head -n 1 || true)"

log() {
    printf '[install] %s\n' "\$*"
}

die() {
    printf '[install][error] %s\n' "\$*" >&2
    exit 1
}

require_target_linux() {
    local os arch
    os="\$(uname -s)"
    arch="\$(uname -m)"
    [ "\$os" = "Linux" ] || die "This offline installer targets Linux servers. Current OS: \$os."

    case "\$PACKAGE_TARGET_ARCH:\$arch" in
        aarch64:aarch64 | aarch64:arm64 | x86_64:x86_64 | x86_64:amd64) ;;
        *) die "This offline package targets \$PACKAGE_TARGET_ARCH. Current arch: \$arch." ;;
    esac
}

install_docker_engine() {
    if command -v docker >/dev/null 2>&1; then
        log "Docker already exists: \$(docker --version)"
        return
    fi

    [ -n "\$DOCKER_TGZ" ] || die "Docker is not installed and no docker static package was found under ./docker."
    [ "\$(id -u)" -eq 0 ] || die "Docker is not installed. Re-run this installer with root privileges."

    log "Installing Docker Engine from \$DOCKER_TGZ."
    tar -xzf "\$DOCKER_TGZ" -C /tmp
    install -m 0755 /tmp/docker/* /usr/local/bin/
    rm -rf /tmp/docker

    if command -v systemctl >/dev/null 2>&1; then
        cat > /etc/systemd/system/docker.service <<'UNIT'
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service containerd.service
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/local/bin/dockerd
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutStartSec=0
RestartSec=2
Restart=always
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
UNIT
        systemctl daemon-reload
        systemctl enable --now docker
    else
        nohup /usr/local/bin/dockerd >/var/log/dockerd.log 2>&1 &
        sleep 3
    fi
}

install_compose_plugin() {
    if docker compose version >/dev/null 2>&1; then
        log "Docker Compose already exists: \$(docker compose version)"
        return
    fi

    [ -n "\$COMPOSE_BIN" ] || die "Docker Compose plugin was not found under ./docker."
    [ "\$(id -u)" -eq 0 ] || die "Docker Compose is not installed. Re-run this installer with root privileges."

    log "Installing Docker Compose plugin from \$COMPOSE_BIN."
    mkdir -p /usr/local/lib/docker/cli-plugins
    install -m 0755 "\$COMPOSE_BIN" /usr/local/lib/docker/cli-plugins/docker-compose
}

load_images() {
    [ -f "\$IMAGE_TAR" ] || die "Image package not found: \$IMAGE_TAR"
    log "Loading Docker images."
    docker load -i "\$IMAGE_TAR"
}

start_services() {
    mkdir -p "\${ROOT_DIR}/urgs-api/uploads" /tmp/lineage-share

    if printf '%s\n' \$SERVICES | grep -qx "urgs-mysql"; then
        log "Starting MySQL first and waiting for readiness."
        docker compose --env-file "\$ENV_FILE" -f "\$COMPOSE_FILE" up -d urgs-mysql
        for i in \$(seq 1 60); do
            status="\$(docker inspect -f '{{.State.Health.Status}}' "\$(docker compose --env-file "\$ENV_FILE" -f "\$COMPOSE_FILE" ps -q urgs-mysql)" 2>/dev/null || true)"
            [ "\$status" = "healthy" ] && break
            sleep 2
        done
    fi

    log "Starting services: \$SERVICES"
    docker compose --env-file "\$ENV_FILE" -f "\$COMPOSE_FILE" up -d \$SERVICES
    docker compose --env-file "\$ENV_FILE" -f "\$COMPOSE_FILE" ps
}

require_target_linux
install_docker_engine
install_compose_plugin
docker info >/dev/null
load_images
start_services

log "URGS offline installation completed."
EOF

    cat > "$DIST_DIR/uninstall.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker compose --env-file "${ROOT_DIR}/.env" -f "${ROOT_DIR}/docker-compose.yml" down
EOF

    chmod +x "$DIST_DIR/install.sh" "$DIST_DIR/uninstall.sh"
}

write_manifest() {
    {
        echo "package=${PACKAGE_NAME}"
        echo "created_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "build_arch=${BUILD_ARCH}"
        echo "target_arch=${TARGET_ARCH}"
        echo "include_docker_binaries=${INCLUDE_DOCKER_BINARIES}"
        echo "docker_version=${DOCKER_VERSION}"
        echo "compose_version=${COMPOSE_VERSION}"
        echo "modules=${SELECTED_MODULES[*]}"
        echo "services=${SELECTED_SERVICES[*]}"
        echo "images=${IMAGES_TO_SAVE[*]}"
    } > "$DIST_DIR/manifest.txt"
}

write_readme() {
    cat > "$DIST_DIR/README_OFFLINE.md" <<'EOF'
# URGS ${TARGET_ARCH} 离线安装包

此目录用于在内网 ${TARGET_ARCH} Linux 服务器上离线部署 URGS。

## 安装前检查

- 服务器架构必须匹配本包的 `manifest.txt` 中 `target_arch`。
- 首次安装 Docker/Compose 时需要 root 权限。
- 部署前按内网实际地址修改 `.env`，重点是数据库、端口、Neo4j 密码、LLM 地址。

## 一键安装

```bash
chmod +x install.sh
sudo ./install.sh
```

如果服务器已经安装 Docker 和 Docker Compose，也可以用普通有 Docker 权限的用户执行：

```bash
./install.sh
```

## 查看状态

```bash
docker compose --env-file .env -f docker-compose.yml ps
docker compose --env-file .env -f docker-compose.yml logs -f urgs-api
```

## 停止服务

```bash
./uninstall.sh
```

## 目录内容

- `images/urgs-images.tar`: 项目服务和第三方依赖镜像。
- `docker/`: Docker Engine 与 Docker Compose ARM 离线安装介质。
- `docker-compose.yml`: 服务编排文件。
- `.env`: 部署环境配置。
- `install.sh`: 离线安装和启动脚本。
- `manifest.txt`: 本次打包清单。
EOF
}

make_archive() {
    log "Creating archive ${PACKAGE_NAME}.tar.gz."
    tar -czf "${PACKAGE_NAME}.tar.gz" "$DIST_DIR"
}

ALL_MODULES=("mysql" "api" "web" "executor" "rag" "lineage" "neo4j" "presentation")
ALL_DIFY_MODULES=("dify-api" "dify-web" "dify-worker" "dify-db" "dify-redis" "dify-nginx" "dify-weaviate")

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
fi

SELECTED_MODULES=()
if [ "$#" -eq 0 ]; then
    SELECTED_MODULES=("${ALL_MODULES[@]}")
    if [ -d "urgs-dify" ]; then
        SELECTED_MODULES+=("${ALL_DIFY_MODULES[@]}")
    else
        log "urgs-dify directory is absent; Dify services will not be packaged."
    fi
else
    for arg in "$@"; do
        image="$(get_image "$arg")"
        [ -n "$image" ] || die "Unknown module '${arg}'. Run ./package.sh --help for supported modules."
        SELECTED_MODULES+=("$arg")
    done
fi

SELECTED_SERVICES=()
for module in "${SELECTED_MODULES[@]}"; do
    SELECTED_SERVICES+=("$(get_service_name "$module")")
done

validate_prerequisites
register_qemu
build_selected_images
pull_external_images
prepare_dist
save_images
download_docker_binaries
write_installer
write_manifest
write_readme
make_archive

log "Packaging complete: ${DIST_DIR}/ and ${PACKAGE_NAME}.tar.gz"
log "Copy the archive to the ${TARGET_ARCH} intranet server, extract it, edit .env, then run sudo ./install.sh."
