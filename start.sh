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
RAG_DIR="$SCRIPT_DIR/urgs-rag"
PRESENTATION_DIR="$SCRIPT_DIR/urgs+-presentation-platform"
DEEPAGENTS_DIR="$SCRIPT_DIR/urgs-deepagents"
LOCAL_ENV_FILE="${START_ENV_FILE:-$SCRIPT_DIR/deploy/templates/deploy.${ENVIRONMENT}.env}"
if [ "$ENVIRONMENT" = "local" ]; then
  LOCAL_ENV_FILE="${START_ENV_FILE:-$SCRIPT_DIR/deploy/templates/deploy.local.env}"
fi

pids=()
external_services=0
AGENT_COMPOSE_DEPS_STARTED=false
ONLYOFFICE_LOCAL_CONTAINER_STARTED=false

# Flags for services
ENABLE_BACKEND=false
ENABLE_EXECUTOR=false
ENABLE_FRONTEND=false
ENABLE_RAG=false
ENABLE_PRESENTATION=false
ENABLE_ONLYOFFICE=false
ENABLE_DEEPAGENTS=false

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

kill_port_if_exists() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    local existing
    existing=$(lsof -ti :"$port" 2>/dev/null || true)
    if [ -n "$existing" ]; then
      echo "Found process on port $port (PID: $existing), killing..."
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
  export RAG_DOC_STORE_PATH="${RAG_DOC_STORE_PATH:-${DATA_ROOT}/rag/doc_store}"
  export CHROMA_PERSIST_DIRECTORY="${CHROMA_PERSIST_DIRECTORY:-${DATA_ROOT}/rag/chroma_db}"
  export DOC_STORAGE_PATH="${DOC_STORAGE_PATH:-${DATA_ROOT}/rag/doc_store}"
  export PARENT_DOC_STORE_PATH="${PARENT_DOC_STORE_PATH:-${DATA_ROOT}/rag/parent_store}"
  export CLEAN_SAMPLE_DIR="${CLEAN_SAMPLE_DIR:-${DATA_ROOT}/rag/clean_samples}"
  export DEPLOY_TOOL_WORKDIR="${DEPLOY_TOOL_WORKDIR:-${DATA_ROOT}/db_deploy}"
  export LINEAGE_ENGINE_SHARED_DIR="${LINEAGE_ENGINE_SHARED_DIR:-${DATA_ROOT}/lineage/share}"
  export ISSUE_ATTACHMENT_PATH="${ISSUE_ATTACHMENT_PATH:-${DATA_ROOT}/attachments}"

  for path_var in URGS_PROFILE IM_UPLOAD_PATH RAG_DOC_STORE_PATH CHROMA_PERSIST_DIRECTORY \
    DOC_STORAGE_PATH PARENT_DOC_STORE_PATH CLEAN_SAMPLE_DIR DEPLOY_TOOL_WORKDIR \
    LINEAGE_ENGINE_SHARED_DIR ISSUE_ATTACHMENT_PATH; do
    local path_value="${!path_var}"
    if [[ "$path_value" != /* ]]; then
      printf -v "$path_var" '%s/%s' "$SCRIPT_DIR" "${path_value#./}"
      export "$path_var"
    fi
  done

  mkdir -p "$URGS_PROFILE" "$IM_UPLOAD_PATH" "$RAG_DOC_STORE_PATH" \
    "$CHROMA_PERSIST_DIRECTORY" "$PARENT_DOC_STORE_PATH" "$CLEAN_SAMPLE_DIR" \
    "$DEPLOY_TOOL_WORKDIR" "$LINEAGE_ENGINE_SHARED_DIR" "$ISSUE_ATTACHMENT_PATH"
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
  if [ "$ONLYOFFICE_LOCAL_CONTAINER_STARTED" = true ]; then
    docker stop "${ONLYOFFICE_LOCAL_DOCKER_CONTAINER:-urgs-onlyoffice-test}" >/dev/null 2>&1 || true
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

  # Explicitly export RAG properties to avoid placeholder resolution issues
  export RAG_BASE_URL="${RAG_SERVICE_URL:-http://localhost:8001}/api/rag"
  export AI_RAG_BASE_URL="$RAG_BASE_URL"
  export AI_RAG_DOC_STORE_PATH="$RAG_DOC_STORE_PATH"

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
  ensure_npm_dependency "$WEB_DIR" vite

  if [ "$ENVIRONMENT" = "local" ] || [ "$ENVIRONMENT" = "dev" ]; then
    "$NPM_BIN" run dev -- --host &
  else
    "$NPM_BIN" run build
  fi
  pids+=($!)
}

start_rag() {
  echo "Starting rag..."
  cd "$RAG_DIR"
  load_env_file
  configure_storage_env
  
  if [ ! -d ".venv" ]; then
    echo "Creating virtual environment for RAG..."
    chmod +x install_env.sh
    ./install_env.sh
  fi

  kill_port_if_exists 8001
  
  if [ "$ENVIRONMENT" = "local" ] || [ "$ENVIRONMENT" = "dev" ]; then
    .venv_312/bin/uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload --loop asyncio &
  else
    .venv_312/bin/uvicorn app.main:app --host 0.0.0.0 --port 8001 --loop asyncio &
  fi
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

start_onlyoffice() {
  load_env_file
  local onlyoffice_port="${ONLYOFFICE_PORT:-8088}"

  if curl -fsS "http://127.0.0.1:${onlyoffice_port}/healthcheck" 2>/dev/null | grep -qi true; then
    echo "ONLYOFFICE Document Server is already running on port ${onlyoffice_port}."
    external_services=$((external_services + 1))
    return
  fi

  if [[ "$OSTYPE" == "linux"* ]]; then
    if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files ds-docservice.service >/dev/null 2>&1; then
      echo "Starting system ONLYOFFICE Document Server..."
      sudo systemctl restart ds-docservice ds-converter ds-metrics nginx
      external_services=$((external_services + 1))
      return
    fi
    echo "ONLYOFFICE is not installed. Package it with deploy/package-services.sh onlyoffice and install it through bin/deploy.sh."
    exit 1
  fi

  if [[ "$OSTYPE" == "darwin"* ]]; then
    local container="${ONLYOFFICE_LOCAL_DOCKER_CONTAINER:-urgs-onlyoffice-test}"
    if command -v docker >/dev/null 2>&1 && docker inspect "$container" >/dev/null 2>&1; then
      echo "macOS cannot run the Linux ARM64 DEB directly; starting existing local development container ${container}."
      docker start "$container" >/dev/null
      ONLYOFFICE_LOCAL_CONTAINER_STARTED=true
      external_services=$((external_services + 1))
      return
    fi
    echo "macOS cannot run the ONLYOFFICE Linux package directly. Start it in a Linux VM or create the local development container first."
    exit 1
  fi

  echo "Unsupported platform for ONLYOFFICE: ${OSTYPE}"
  exit 1
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
  if [ -d ".venv" ] && [ ! -x ".venv/bin/python" ]; then
    echo "Found invalid agent .venv; recreating it..."
    rm -rf .venv
  fi
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

start_deepagents() {
  echo "Starting DeepAgents service..."
  cd "$DEEPAGENTS_DIR"
  load_env_file
  configure_storage_env
  configure_internal_api_auth

  local deepagents_port="${DEEPAGENTS_PORT:-8003}"
  kill_port_if_exists "$deepagents_port"

  if ! command -v uv >/dev/null 2>&1; then
    echo "uv not found. Install uv before starting urgs-deepagents."
    exit 1
  fi

  if [ -z "${DEEPAGENTS_URGS_API_URL:-}" ]; then
    export DEEPAGENTS_URGS_API_URL="${URGS_API_URL:-${AGENT_URGS_API_URL:-http://127.0.0.1:8080}}"
  fi
  export DEEPAGENTS_INTERNAL_API_TOKEN="${DEEPAGENTS_INTERNAL_API_TOKEN:-$URGS_INTERNAL_API_TOKEN}"
  export DEEPAGENTS_WORKSPACE_ROOT="${DEEPAGENTS_WORKSPACE_ROOT:-$SCRIPT_DIR}"
  if [ -f "$SCRIPT_DIR/AGENTS.md" ]; then
    export DEEPAGENTS_MEMORY_FILES="${DEEPAGENTS_MEMORY_FILES:-/AGENTS.md}"
  fi

  echo "Preparing DeepAgents Python 3.11 environment..."
  if [ -d ".venv" ] && [ ! -x ".venv/bin/python" ]; then
    echo "Found invalid DeepAgents .venv; recreating it..."
    rm -rf .venv
  fi
  if [ "$ENVIRONMENT" = "local" ] || [ "$ENVIRONMENT" = "dev" ]; then
    uv sync --frozen --extra dev
  else
    uv sync --frozen --no-dev
  fi
  export PYTHONPATH="$DEEPAGENTS_DIR/src${PYTHONPATH:+:$PYTHONPATH}"

  echo "Starting DeepAgents API on port $deepagents_port..."
  .venv/bin/uvicorn urgs_deepagents_service.main:app --host "${DEEPAGENTS_HOST:-0.0.0.0}" --port "$deepagents_port" &
  pids+=($!)
}

# --- Interactive Menu ---
echo "Multiple services detected. Please select which ones to start:"
echo "  [1] All Services (Backend, Executor, Frontend, RAG, Agent, DeepAgents)"
echo "  [2] Backend (urgs-api)"
echo "  [3] Executor (urgs-executor)"
echo "  [4] Frontend (urgs-web)"
echo "  [5] RAG (urgs-rag)"
echo "  [6] Presentation (urgs-presentation)"
echo "  [7] Agent (urgs-agent)"
echo "  [8] ONLYOFFICE Docs"
echo "  [9] DeepAgents (urgs-deepagents)"
echo ""
echo "Enter your choice (e.g., '1' for all, or '2 7' for Backend+Agent):"
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
      ENABLE_RAG=true
      ENABLE_PRESENTATION=true
      ENABLE_AGENT=true
      ENABLE_ONLYOFFICE=true
      ENABLE_DEEPAGENTS=true
      ;;
    2) ENABLE_BACKEND=true ;;
    3) ENABLE_EXECUTOR=true ;;
    4) ENABLE_FRONTEND=true ;;
    5) ENABLE_RAG=true ;;
    6) ENABLE_PRESENTATION=true ;;
    7) ENABLE_AGENT=true ;;
    8) ENABLE_ONLYOFFICE=true ;;
    9) ENABLE_DEEPAGENTS=true ;;
    *) echo "Unknown option: $choice (ignored)" ;;
  esac
done

if [ "$ENABLE_BACKEND" = true ] && [ "$ENABLE_FRONTEND" = true ] && [ "$ENABLE_EXECUTOR" != true ]; then
  echo "Backend + frontend selected; enabling executor because task trigger APIs call urgs-executor on port 8082."
  ENABLE_EXECUTOR=true
fi

if [ "$ENABLE_ONLYOFFICE" = true ]; then start_onlyoffice; fi
if [ "$ENABLE_BACKEND" = true ]; then start_backend; fi
if [ "$ENABLE_EXECUTOR" = true ]; then start_executor; fi
if [ "$ENABLE_FRONTEND" = true ] || [ "$ENABLE_PRESENTATION" = true ]; then resolve_node_runtime; fi
if [ "$ENABLE_FRONTEND" = true ]; then start_frontend; fi
if [ "$ENABLE_RAG" = true ]; then start_rag; fi
if [ "$ENABLE_PRESENTATION" = true ]; then start_presentation; fi
if [ "$ENABLE_AGENT" = true ]; then start_agent; fi
if [ "$ENABLE_DEEPAGENTS" = true ]; then start_deepagents; fi

if [ ${#pids[@]} -eq 0 ] && [ "$external_services" -eq 0 ]; then
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
