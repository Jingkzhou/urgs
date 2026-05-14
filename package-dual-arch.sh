#!/usr/bin/env bash
set -euo pipefail

# Build two offline distributions:
# - linux/arm64 for ARM servers
# - linux/amd64 for the previous x86_64 server architecture

STAMP="${PACKAGE_STAMP:-$(date +%Y%m%d%H%M%S)}"
MODULES=("$@")

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    cat <<'EOF'
Usage:
  ./package-dual-arch.sh [module...]

Builds two offline packages with the same selected modules:
  - linux/arm64  -> urgs-offline-aarch64-*.tar.gz
  - linux/amd64  -> urgs-offline-x86_64-*.tar.gz

Examples:
  ./package-dual-arch.sh
  ./package-dual-arch.sh mysql api web executor rag lineage neo4j

Optional per-arch download URL overrides:
  DOCKER_STATIC_URL_aarch64=...
  COMPOSE_URL_aarch64=...
  DOCKER_STATIC_URL_x86_64=...
  COMPOSE_URL_x86_64=...
EOF
    exit 0
fi

run_package() {
    local build_arch="$1"
    local target_arch="$2"
    local dist_dir="$3"
    local package_name="$4"
    local docker_url_var="DOCKER_STATIC_URL_${target_arch}"
    local compose_url_var="COMPOSE_URL_${target_arch}"
    local docker_url="${!docker_url_var:-${DOCKER_STATIC_URL:-}}"
    local compose_url="${!compose_url_var:-${COMPOSE_URL:-}}"

    printf '[dual-package] building %s package: %s\n' "$build_arch" "$package_name"
    BUILD_ARCH="$build_arch" \
    TARGET_ARCH="$target_arch" \
    DIST_DIR="$dist_dir" \
    PACKAGE_NAME="$package_name" \
    DOCKER_STATIC_URL="$docker_url" \
    COMPOSE_URL="$compose_url" \
    ./package.sh "${MODULES[@]}"
}

run_package "linux/arm64" "aarch64" "urgs-dist-aarch64" "urgs-offline-aarch64-${STAMP}"
run_package "linux/amd64" "x86_64" "urgs-dist-x86_64" "urgs-offline-x86_64-${STAMP}"

printf '[dual-package] done:\n'
printf '  %s\n' "urgs-offline-aarch64-${STAMP}.tar.gz"
printf '  %s\n' "urgs-offline-x86_64-${STAMP}.tar.gz"
