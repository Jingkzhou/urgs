#!/usr/bin/env bash
set -euo pipefail

# Prefer Java 17 when available; otherwise fall back to the current system JDK.
if command -v /usr/libexec/java_home >/dev/null 2>&1; then
  if JAVA17_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null); then
    export JAVA_HOME="$JAVA17_HOME"
  else
    export JAVA_HOME="$(/usr/libexec/java_home)"
  fi
elif [ -d "/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home" ]; then
  export JAVA_HOME="/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home"
fi

if [ -n "${JAVA_HOME:-}" ]; then
  export PATH="$JAVA_HOME/bin:$PATH"
fi
export HF_ENDPOINT=https://hf-mirror.com
# 启用离线模式，使用本地缓存的模型，避免每次连接 HuggingFace
export HF_HUB_OFFLINE=1
export TRANSFORMERS_OFFLINE=1
echo "Using JAVA_HOME: $JAVA_HOME"
echo "Using HF_ENDPOINT: $HF_ENDPOINT (Offline Mode: ON)"

# Fix for macOS multiprocessing issues
if [[ "$OSTYPE" == "darwin"* ]]; then
  export OBJC_FORBID_REENTRANT_INFO_BY_DEFAULT=NO
fi

ENVIRONMENT="${1:-local}"
case "$ENVIRONMENT" in
  local|dev|sit|pre|prod) ;;
  *)
    echo "Usage: $0 [local|dev|sit|pre|prod]"
    exit 1
    ;;
esac

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
API_DIR="$SCRIPT_DIR/urgs-api"
EXECUTOR_DIR="$SCRIPT_DIR/urgs-executor"
WEB_DIR="$SCRIPT_DIR/urgs-web"
DESKTOP_DIR="$SCRIPT_DIR/urgs-desktop"
PRESENTATION_DIR="$SCRIPT_DIR/urgs+-presentation-platform"
LOCAL_ENV_FILE="${START_ENV_FILE:-$SCRIPT_DIR/deploy/templates/deploy.${ENVIRONMENT}.env}"
if [ "$ENVIRONMENT" = "local" ]; then
  LOCAL_ENV_FILE="${START_ENV_FILE:-$SCRIPT_DIR/deploy/templates/deploy.local.env}"
fi

pids=()
AGENT_COMPOSE_DEPS_STARTED=false

# Flags for services
ENABLE_BACKEND=false
ENABLE_EXECUTOR=false
ENABLE_FRONTEND=false
ENABLE_DESKTOP=false
ENABLE_PRESENTATION=false

NODE_BIN=""
NPM_BIN=""

resolve_node_runtime() {
  local candidate
  for candidate in /opt/homebrew/bin /usr/local/bin; do
    if [ -x "$candidate/node" ] && [ -x "$candidate/npm" ]; then
      NODE_BIN="$candidate/node"
      NPM_BIN="$candidate/npm"
      break
    fi
  done

  if [ -z "$NODE_BIN" ] || [ -z "$NPM_BIN" ]; then
    NODE_BIN="$(command -v node || true)"
    NPM_BIN="$(command -v npm || true)"
  fi

  if [ -z "$NODE_BIN" ] || [ -z "$NPM_BIN" ]; then
    echo "Node.js/npm not found. Please install Node.js first."
    exit 1
  fi

  export PATH="$(dirname "$NODE_BIN"):$(dirname "$NPM_BIN"):$PATH"
  echo "Using NODE_BIN: $NODE_BIN"
  echo "Using NPM_BIN: $NPM_BIN"
}

ensure_npm_dependency() {
  local package_dir="$1"
  local required_bin="$2"

  cd "$package_dir"
  if [ ! -x "node_modules/.bin/$required_bin" ]; then
    echo "Installing frontend dependencies in $package_dir (missing node_modules/.bin/$required_bin)..."
    "$NPM_BIN" install
  fi
}

ensure_pnpm_dependencies() {
  local package_dir="$1"
  local pnpm_bin
  local -a pnpm_cmd

  pnpm_bin="$(command -v pnpm || true)"
  if [ -n "$pnpm_bin" ]; then
    pnpm_cmd=("$pnpm_bin")
  else
    echo "pnpm not found; using pnpm 10 through npm."
    pnpm_cmd=("$NPM_BIN" exec --yes --package=pnpm@10 -- pnpm)
  fi

  echo "Synchronizing frontend dependencies from pnpm-lock.yaml..."
  CI=true "${pnpm_cmd[@]}" --dir "$package_dir" install --frozen-lockfile

  # 分支切换会替换 node_modules 中的依赖版本；清除可再生的 Vite 预构建缓存，
  # 避免它继续引用已删除的旧依赖路径。
  if [ -d "$package_dir/node_modules/.vite" ]; then
    echo "Clearing stale Vite dependency cache..."
    rm -rf "$package_dir/node_modules/.vite"
  fi
}

kill_port_if_exists() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    local existing
    existing=$(lsof -ti :"$port" 2>/dev/null || true)
    if [ -n "$existing" ]; then
      local pid_list="${existing//$'\n'/ }"
      echo "Found process on port $port (PID: $pid_list), killing..."
      kill -9 $existing 2>/dev/null || true
    fi
  else
    echo "lsof not found; skip port $port pre-kill."
  fi
}

load_env_file() {
  if [ ! -f "$LOCAL_ENV_FILE" ]; then
    echo "Environment file not found: $LOCAL_ENV_FILE"
    exit 1
  fi
  set -a
  # shellcheck disable=SC1090
  source "$LOCAL_ENV_FILE"
  set +a
}

configure_storage_env() {
  local default_data_root="$SCRIPT_DIR/data"
  local effective_data_root="${DATA_ROOT:-$default_data_root}"

  if [[ "$effective_data_root" != /* ]]; then
    effective_data_root="$SCRIPT_DIR/${effective_data_root#./}"
  fi

  export DATA_ROOT="$effective_data_root"
  export URGS_PROFILE="${URGS_PROFILE:-${DATA_ROOT}/api/uploads}"
  export IM_UPLOAD_PATH="${IM_UPLOAD_PATH:-${DATA_ROOT}/api/im-uploads}"
  export DEPLOY_TOOL_WORKDIR="${DEPLOY_TOOL_WORKDIR:-${DATA_ROOT}/db_deploy}"
  export LINEAGE_ENGINE_SHARED_DIR="${LINEAGE_ENGINE_SHARED_DIR:-${DATA_ROOT}/lineage/share}"
  export ISSUE_ATTACHMENT_PATH="${ISSUE_ATTACHMENT_PATH:-${DATA_ROOT}/attachments}"

  for path_var in URGS_PROFILE IM_UPLOAD_PATH DEPLOY_TOOL_WORKDIR \
    LINEAGE_ENGINE_SHARED_DIR ISSUE_ATTACHMENT_PATH; do
    local path_value="${!path_var}"
    if [[ "$path_value" != /* ]]; then
      printf -v "$path_var" '%s/%s' "$SCRIPT_DIR" "${path_value#./}"
      export "$path_var"
    fi
  done

  mkdir -p "$URGS_PROFILE" "$IM_UPLOAD_PATH" "$DEPLOY_TOOL_WORKDIR" \
    "$LINEAGE_ENGINE_SHARED_DIR" "$ISSUE_ATTACHMENT_PATH"
}

generate_internal_api_token() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 32
  else
    od -An -N32 -tx1 /dev/urandom | tr -d ' \n'
  fi
}

configure_internal_api_auth() {
  if [ -n "${URGS_INTERNAL_API_TOKEN:-}" ]; then
    export URGS_INTERNAL_API_TOKEN
    return
  fi

  local token_file="${DATA_ROOT}/internal-api.token"
  if [ ! -s "$token_file" ]; then
    (umask 077 && generate_internal_api_token > "$token_file")
  fi
  chmod 600 "$token_file"
  URGS_INTERNAL_API_TOKEN="$(tr -d '\r\n' < "$token_file")"
  if [ -z "$URGS_INTERNAL_API_TOKEN" ]; then
    echo "Internal API token file is empty: $token_file"
    exit 1
  fi
  export URGS_INTERNAL_API_TOKEN
}

configure_database_env() {
  load_env_file
  configure_storage_env
  configure_internal_api_auth

  if [ -n "${DB_HOST:-}" ]; then
    local jdbc_url="jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}?useSSL=false&serverTimezone=Asia/Shanghai&characterEncoding=utf8&allowPublicKeyRetrieval=true"
    export SPRING_DATASOURCE_URL="${SPRING_DATASOURCE_URL:-$jdbc_url}"
    export SPRING_DATASOURCE_USERNAME="${SPRING_DATASOURCE_USERNAME:-${DB_USER}}"
    export SPRING_DATASOURCE_PASSWORD="${SPRING_DATASOURCE_PASSWORD:-${DB_PASSWORD}}"
    export URGS_EXECUTOR_DB_URL="${URGS_EXECUTOR_DB_URL:-$jdbc_url}"
    export URGS_EXECUTOR_DB_USERNAME="${URGS_EXECUTOR_DB_USERNAME:-${DB_USER}}"
    export URGS_EXECUTOR_DB_PASSWORD="${URGS_EXECUTOR_DB_PASSWORD:-${DB_PASSWORD}}"
  elif [ -n "${SPRING_DATASOURCE_URL:-}" ]; then
    export URGS_EXECUTOR_DB_URL="${URGS_EXECUTOR_DB_URL:-$SPRING_DATASOURCE_URL}"
    export URGS_EXECUTOR_DB_USERNAME="${URGS_EXECUTOR_DB_USERNAME:-${SPRING_DATASOURCE_USERNAME:-root}}"
    export URGS_EXECUTOR_DB_PASSWORD="${URGS_EXECUTOR_DB_PASSWORD:-${SPRING_DATASOURCE_PASSWORD:-}}"
  fi
}

configure_java_opts() {
  export API_JAVA_OPTS="${API_JAVA_OPTS:-"-Xms8g -Xmx20g -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${SCRIPT_DIR}/logs/api-heapdump.hprof -Dfile.encoding=UTF-8 -Duser.timezone=Asia/Shanghai"}"
  export EXECUTOR_JAVA_OPTS="${EXECUTOR_JAVA_OPTS:-"-Xms2g -Xmx4g -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${SCRIPT_DIR}/logs/executor-heapdump.hprof -Dfile.encoding=UTF-8 -Duser.timezone=Asia/Shanghai"}"
  mkdir -p "$SCRIPT_DIR/logs"
}

cleanup() {
  echo "Stopping services..."
  for pid in "${pids[@]:-}"; do
    kill "$pid" 2>/dev/null || true
  done
  if [ "$AGENT_COMPOSE_DEPS_STARTED" = true ]; then
    (cd "$AGENT_DIR" && docker compose stop postgres redis >/dev/null 2>&1) || true
  fi
}
trap cleanup EXIT

start_backend() {
  cd "$API_DIR"
  kill_port_if_exists 8080
  configure_database_env
  configure_java_opts
  local spring_profile="${SPRING_PROFILES_ACTIVE:-$ENVIRONMENT}"
  echo "Starting backend (env: $ENVIRONMENT, profile: $spring_profile, config: $LOCAL_ENV_FILE)..."
  echo "Backend JVM opts: $API_JAVA_OPTS"

  # Construct Neo4j Properties if var exists
  if [ -n "${NEO4J_HOST:-}" ]; then
    # 如果在宿主机运行，neo4j 习惯上访问 localhost
    REAL_NEO4J_HOST=$NEO4J_HOST
    if [ "$REAL_NEO4J_HOST" = "neo4j" ]; then
      REAL_NEO4J_HOST="localhost"
    fi
    export SPRING_NEO4J_URI="bolt://${REAL_NEO4J_HOST}:${NEO4J_PORT_BOLT:-7687}"
    export SPRING_NEO4J_AUTHENTICATION_USERNAME="${NEO4J_USER:-neo4j}"
    export SPRING_NEO4J_AUTHENTICATION_PASSWORD="${NEO4J_PASSWORD}"
    echo "Configured Neo4j URI: $SPRING_NEO4J_URI"
  fi

  ./mvnw spring-boot:run -Dspring-boot.run.profiles="$spring_profile" -Dspring-boot.run.jvmArguments="$API_JAVA_OPTS" &
  pids+=($!)
}

start_frontend() {
  echo "Starting frontend ($ENVIRONMENT)..."
  cd "$WEB_DIR"
  kill_port_if_exists 3000
  kill_port_if_exists 3001
  ensure_pnpm_dependencies "$WEB_DIR"

  if [ "$ENVIRONMENT" = "local" ] || [ "$ENVIRONMENT" = "dev" ]; then
    "$NPM_BIN" run dev -- --host &
  else
    "$NPM_BIN" run build
  fi
  pids+=($!)
}

start_desktop() {
  echo "Starting desktop client ($ENVIRONMENT)..."
  cd "$DESKTOP_DIR"
  kill_port_if_exists 3000
  kill_port_if_exists 3001

  if ! command -v cargo >/dev/null 2>&1; then
    echo "Rust/Cargo not found. Install the Rust toolchain before starting urgs-desktop."
    exit 1
  fi
  ensure_pnpm_dependencies "$WEB_DIR"

  local pnpm_bin
  local -a pnpm_cmd
  pnpm_bin="$(command -v pnpm || true)"
  if [ -n "$pnpm_bin" ]; then
    pnpm_cmd=("$pnpm_bin")
  else
    pnpm_cmd=("$NPM_BIN" exec --yes --package=pnpm@10 -- pnpm)
  fi
  if [ ! -x "node_modules/.bin/tauri" ]; then
    echo "Installing desktop dependencies in $DESKTOP_DIR..."
    CI=true "${pnpm_cmd[@]}" install --frozen-lockfile
  fi

  "${pnpm_cmd[@]}" dev &
  pids+=($!)
}

start_executor() {
  cd "$EXECUTOR_DIR"
  kill_port_if_exists 8082
  configure_database_env
  configure_java_opts
  local spring_profile="${SPRING_PROFILES_ACTIVE:-$ENVIRONMENT}"
  echo "Starting executor (env: $ENVIRONMENT, profile: $spring_profile, config: $LOCAL_ENV_FILE)..."
  echo "Executor JVM opts: $EXECUTOR_JAVA_OPTS"
  ./mvnw spring-boot:run -Dspring-boot.run.profiles="$spring_profile" -Dspring-boot.run.jvmArguments="$EXECUTOR_JAVA_OPTS" &
  pids+=($!)
}



start_presentation() {
  echo "Starting presentation platform..."
  cd "$PRESENTATION_DIR"
  kill_port_if_exists 3002
  ensure_npm_dependency "$PRESENTATION_DIR" vite
  "$NPM_BIN" run dev -- --host --port 3002 &
  pids+=($!)
}

AGENT_DIR="$SCRIPT_DIR/urgs-agent"

# ... (existing flags)
ENABLE_AGENT=false

# ... (existing functions)

start_agent() {
  echo "Starting agent runtime..."
  cd "$AGENT_DIR"
  load_env_file

  local agent_port="${AGENT_PORT:-8002}"
  kill_port_if_exists "$agent_port"

  if ! command -v uv >/dev/null 2>&1; then
    echo "uv not found. Install uv before starting urgs-agent."
    exit 1
  fi

  if ! nc -z 127.0.0.1 5432 >/dev/null 2>&1 || ! nc -z 127.0.0.1 6379 >/dev/null 2>&1; then
    if ! command -v docker >/dev/null 2>&1; then
      echo "PostgreSQL or Redis is unavailable, and Docker is not installed."
      exit 1
    fi
    echo "Starting agent PostgreSQL and Redis dependencies..."
    docker compose up -d postgres redis
    AGENT_COMPOSE_DEPS_STARTED=true
    for _ in $(seq 1 30); do
      if nc -z 127.0.0.1 5432 >/dev/null 2>&1 && nc -z 127.0.0.1 6379 >/dev/null 2>&1; then
        break
      fi
      sleep 1
    done
    if ! nc -z 127.0.0.1 5432 >/dev/null 2>&1 || ! nc -z 127.0.0.1 6379 >/dev/null 2>&1; then
      echo "Agent PostgreSQL or Redis failed to become ready."
      exit 1
    fi
  fi

  echo "Preparing agent Python 3.11 environment..."
  if [ "$ENVIRONMENT" = "local" ] || [ "$ENVIRONMENT" = "dev" ]; then
    uv sync --frozen --extra dev
  else
    uv sync --frozen --no-dev
  fi
  export PYTHONPATH="$AGENT_DIR/src${PYTHONPATH:+:$PYTHONPATH}"

  echo "Applying agent database migrations..."
  .venv/bin/alembic upgrade head

  echo "Starting agent API on port $agent_port..."
  .venv/bin/uvicorn urgs_agent.main:app --host "${AGENT_HOST:-0.0.0.0}" --port "$agent_port" &
  pids+=($!)

  echo "Starting agent worker..."
  .venv/bin/python -m urgs_agent.worker &
  pids+=($!)
}

# --- Interactive Menu ---
echo "Multiple services detected. Please select which ones to start:"
echo "  [1] All Services (Backend, Executor, Frontend, Agent)"
echo "  [2] Backend (urgs-api)"
echo "  [3] Executor (urgs-executor)"
echo "  [4] Frontend (urgs-web)"
echo "  [5] Presentation (urgs-presentation)"
echo "  [6] Agent (urgs-agent)"
echo "  [7] Desktop Client (urgs-desktop, includes frontend)"
echo ""
echo "Enter your choice (e.g., '1' for all, or '2 3 7' for Backend+Executor+Desktop):"
read -r -a choices

if [ ${#choices[@]} -eq 0 ]; then
  echo "No selection made. Defaulting to ALL..."
  choices=("1")
fi

for choice in "${choices[@]}"; do
  case "$choice" in
    1)
      ENABLE_BACKEND=true
      ENABLE_EXECUTOR=true
      ENABLE_FRONTEND=true
      ENABLE_PRESENTATION=true
      ENABLE_AGENT=true
      ;;
    2) ENABLE_BACKEND=true ;;
    3) ENABLE_EXECUTOR=true ;;
    4) ENABLE_FRONTEND=true ;;
    5) ENABLE_PRESENTATION=true ;;
    6) ENABLE_AGENT=true ;;
    7) ENABLE_DESKTOP=true ;;
    *) echo "Unknown option: $choice (ignored)" ;;
  esac
done

if [ "$ENABLE_DESKTOP" = true ] && [ "$ENABLE_FRONTEND" = true ]; then
  echo "Desktop starts urgs-web automatically; disabling the standalone frontend to avoid a port conflict."
  ENABLE_FRONTEND=false
fi

if [ "$ENABLE_BACKEND" = true ] && { [ "$ENABLE_FRONTEND" = true ] || [ "$ENABLE_DESKTOP" = true ]; } && [ "$ENABLE_EXECUTOR" != true ]; then
  echo "Backend + UI selected; enabling executor because task trigger APIs call urgs-executor on port 8082."
  ENABLE_EXECUTOR=true
fi

if [ "$ENABLE_BACKEND" = true ]; then start_backend; fi
if [ "$ENABLE_EXECUTOR" = true ]; then start_executor; fi
if [ "$ENABLE_FRONTEND" = true ] || [ "$ENABLE_DESKTOP" = true ] || [ "$ENABLE_PRESENTATION" = true ]; then resolve_node_runtime; fi
if [ "$ENABLE_FRONTEND" = true ]; then start_frontend; fi
if [ "$ENABLE_DESKTOP" = true ]; then start_desktop; fi
if [ "$ENABLE_PRESENTATION" = true ]; then start_presentation; fi
if [ "$ENABLE_AGENT" = true ]; then start_agent; fi

if [ ${#pids[@]} -eq 0 ]; then
  echo "No services selected. Exiting."
  exit 0
fi

echo "Selected services are running. Press Ctrl+C to stop."

while true; do
  for pid in "${pids[@]}"; do
    if ! kill -0 "$pid" 2>/dev/null; then
      echo "A process has exited; shutting down others."
      exit 0
    fi
  done
  sleep 1
done
