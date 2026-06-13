#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${OUT_DIR:-${ROOT_DIR}/deploy/components-cache}"
VERSION="${ONLYOFFICE_VERSION:-${1:-latest}}"
REPOSITORY="ONLYOFFICE/DocumentServer"

require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        printf '[onlyoffice-download][error] Missing required command: %s\n' "$1" >&2
        exit 1
    }
}

require_command curl
require_command jq

if [ "$VERSION" = "latest" ]; then
    release_url="https://api.github.com/repos/${REPOSITORY}/releases/latest"
else
    version_tag="$VERSION"
    case "$version_tag" in
        v*) ;;
        *) version_tag="v${version_tag}" ;;
    esac
    release_url="https://api.github.com/repos/${REPOSITORY}/releases/tags/${version_tag}"
fi

release_json="$(curl -fsSL "$release_url")"
tag="$(printf '%s' "$release_json" | jq -r '.tag_name')"
download_url="$(printf '%s' "$release_json" | jq -r '.assets[] | select(.name == "onlyoffice-documentserver_arm64.deb") | .browser_download_url' | head -1)"

[ -n "$download_url" ] && [ "$download_url" != "null" ] || {
    printf '[onlyoffice-download][error] ARM64 DEB not found in release %s\n' "$tag" >&2
    exit 1
}

normalized_version="${tag#v}"
target="${OUT_DIR}/onlyoffice-documentserver_${normalized_version}_arm64.deb"
mkdir -p "$OUT_DIR"

printf '[onlyoffice-download] Downloading %s to %s\n' "$tag" "$target"
curl -fL --retry 3 --retry-delay 3 --progress-bar "$download_url" -o "${target}.part"
mv "${target}.part" "$target"

if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$target"
elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$target"
fi

printf '[onlyoffice-download] Package ready: %s\n' "$target"
