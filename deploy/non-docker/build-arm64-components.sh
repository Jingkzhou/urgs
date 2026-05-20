#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${OUT_DIR:-${ROOT_DIR}/deploy/non-docker/components-cache}"
NGINX_VERSION="${NGINX_VERSION:-1.30.1}"
REDIS_VERSION="${REDIS_VERSION:-stable}"
PLATFORM="${PLATFORM:-linux/arm64}"
IMAGE_TAG="urgs-nondocker-components:arm64"
BASE_IMAGE="${BASE_IMAGE:-debian:bullseye-slim}"

log() {
    printf '[component-build] %s\n' "$*"
}

die() {
    printf '[component-build][error] %s\n' "$*" >&2
    exit 1
}

command -v docker >/dev/null 2>&1 || die "Missing required command: docker"
mkdir -p "$OUT_DIR"

BUILD_DIR="$(mktemp -d /tmp/urgs-component-build.XXXXXX)"
trap 'rm -rf "$BUILD_DIR"' EXIT

cat > "${BUILD_DIR}/Dockerfile" <<'EOF'
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG NGINX_VERSION
ARG REDIS_VERSION

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        libssl-dev \
        make \
        procps \
        tar \
        zlib1g-dev \
        libpcre2-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN curl -fsSL "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -o nginx.tar.gz \
    && tar -xzf nginx.tar.gz \
    && cd "nginx-${NGINX_VERSION}" \
    && ./configure \
        --prefix=/opt/urgs-nginx \
        --sbin-path=/opt/urgs-nginx/sbin/nginx.real \
        --conf-path=/opt/urgs-nginx/conf/nginx.conf \
        --pid-path=/opt/urgs-nginx/logs/nginx.pid \
        --error-log-path=/opt/urgs-nginx/logs/error.log \
        --http-log-path=/opt/urgs-nginx/logs/access.log \
        --with-http_ssl_module \
        --with-http_v2_module \
        --with-http_gzip_static_module \
        --with-threads \
    && make -j"$(nproc)" \
    && make install \
    && mkdir -p /opt/urgs-nginx/bin /opt/urgs-nginx/lib \
    && ldd /opt/urgs-nginx/sbin/nginx.real \
        | awk '/=>/ {print $3} /^\// {print $1}' \
        | while read -r lib; do [ -f "$lib" ] && cp -L "$lib" /opt/urgs-nginx/lib/; done \
    && rm -f /opt/urgs-nginx/lib/libc.so* /opt/urgs-nginx/lib/ld-linux*.so* \
        /opt/urgs-nginx/lib/libpthread.so* /opt/urgs-nginx/lib/librt.so* \
        /opt/urgs-nginx/lib/libdl.so* /opt/urgs-nginx/lib/libm.so* \
        /opt/urgs-nginx/lib/libresolv.so* /opt/urgs-nginx/lib/libnsl.so* \
        /opt/urgs-nginx/lib/libutil.so* \
    && printf '%s\n' \
        '#!/usr/bin/env sh' \
        'DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"' \
        'export LD_LIBRARY_PATH="$DIR/lib:${LD_LIBRARY_PATH:-}"' \
        'exec "$DIR/sbin/nginx.real" "$@"' \
        > /opt/urgs-nginx/bin/nginx
RUN chmod +x /opt/urgs-nginx/bin/nginx

RUN if [ "${REDIS_VERSION}" = "stable" ]; then \
        curl -fsSL "https://download.redis.io/redis-stable.tar.gz" -o redis.tar.gz; \
    else \
        curl -fsSL "https://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz" -o redis.tar.gz; \
    fi \
    && tar -xzf redis.tar.gz \
    && redis_dir="$(find /build -maxdepth 1 -type d -name 'redis-*' | head -1)" \
    && cd "$redis_dir" \
    && make -j"$(nproc)" BUILD_TLS=no \
    && mkdir -p /opt/urgs-redis/bin /opt/urgs-redis/lib \
    && cp src/redis-server /opt/urgs-redis/bin/redis-server.real \
    && cp src/redis-cli /opt/urgs-redis/bin/redis-cli.real \
    && for bin in /opt/urgs-redis/bin/redis-server.real /opt/urgs-redis/bin/redis-cli.real; do \
        ldd "$bin" | awk '/=>/ {print $3} /^\// {print $1}' \
            | while read -r lib; do [ -f "$lib" ] && cp -L "$lib" /opt/urgs-redis/lib/; done; \
    done \
    && rm -f /opt/urgs-redis/lib/libc.so* /opt/urgs-redis/lib/ld-linux*.so* \
        /opt/urgs-redis/lib/libpthread.so* /opt/urgs-redis/lib/librt.so* \
        /opt/urgs-redis/lib/libdl.so* /opt/urgs-redis/lib/libm.so* \
        /opt/urgs-redis/lib/libresolv.so* /opt/urgs-redis/lib/libnsl.so* \
        /opt/urgs-redis/lib/libutil.so* \
    && printf '%s\n' \
        '#!/usr/bin/env sh' \
        'DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"' \
        'export LD_LIBRARY_PATH="$DIR/lib:${LD_LIBRARY_PATH:-}"' \
        'exec "$DIR/bin/redis-server.real" "$@"' \
        > /opt/urgs-redis/bin/redis-server
RUN printf '%s\n' \
        '#!/usr/bin/env sh' \
        'DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"' \
        'export LD_LIBRARY_PATH="$DIR/lib:${LD_LIBRARY_PATH:-}"' \
        'exec "$DIR/bin/redis-cli.real" "$@"' \
        > /opt/urgs-redis/bin/redis-cli
RUN chmod +x /opt/urgs-redis/bin/redis-server /opt/urgs-redis/bin/redis-cli /opt/urgs-redis/bin/redis-server.real /opt/urgs-redis/bin/redis-cli.real

RUN mkdir -p /out \
    && tar -C /opt -czf "/out/nginx-linux-aarch64-${NGINX_VERSION}.tar.gz" urgs-nginx \
    && redis_version="$(/opt/urgs-redis/bin/redis-server --version | awk '{print $3}' | cut -d= -f2)" \
    && tar -C /opt -czf "/out/redis-linux-aarch64-${redis_version}.tar.gz" urgs-redis
EOF

log "Building ARM64 nginx/redis component image."
docker build --platform "$PLATFORM" \
    --build-arg "BASE_IMAGE=${BASE_IMAGE}" \
    --build-arg "NGINX_VERSION=${NGINX_VERSION}" \
    --build-arg "REDIS_VERSION=${REDIS_VERSION}" \
    -t "$IMAGE_TAG" "$BUILD_DIR"

container_id="$(docker create "$IMAGE_TAG")"
trap 'docker rm -f "$container_id" >/dev/null 2>&1 || true; rm -rf "$BUILD_DIR"' EXIT
docker cp "${container_id}:/out/." "$OUT_DIR/"
docker rm "$container_id" >/dev/null

log "Component packages ready:"
find "$OUT_DIR" -maxdepth 1 -type f \( -name 'nginx-linux-aarch64-*.tar.gz' -o -name 'redis-linux-aarch64-*.tar.gz' \) -print | sort
