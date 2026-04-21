#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export PYTHONPATH="$SCRIPT_DIR"

if [ -f "$SCRIPT_DIR/../.env" ]; then
  set -a
  # shellcheck disable=SC1091
  . "$SCRIPT_DIR/../.env"
  set +a
fi

if [ -z "${NEO4J_USERNAME:-}" ] && [ -n "${NEO4J_USER:-}" ]; then
  export NEO4J_USERNAME="$NEO4J_USER"
fi

if [ -z "${NEO4J_URI:-}" ] && [ -n "${NEO4J_HOST:-}" ]; then
  export NEO4J_URI="bolt://${NEO4J_HOST}:${NEO4J_PORT_BOLT:-7687}"
fi

if [ -z "${JAVA_HOME:-}" ] && [ -d "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home" ]; then
  export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
fi

if [ -x "$SCRIPT_DIR/.venv/bin/python" ]; then
  exec "$SCRIPT_DIR/.venv/bin/python" "$SCRIPT_DIR/bin/lineage-cli" "$@"
fi

exec python3 "$SCRIPT_DIR/bin/lineage-cli" "$@"
