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

ENVIRONMENT="${1:-dev}"
case "$ENVIRONMENT" in
  dev|sit|prod) ;;
  *)
    echo "Usage: $0 [dev|sit|prod]"
    exit 1
    ;;
esac

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
API_DIR="$SCRIPT_DIR/urgs-api"
EXECUTOR_DIR="$SCRIPT_DIR/urgs-executor"
WEB_DIR="$SCRIPT_DIR/urgs-web"
RAG_DIR="$SCRIPT_DIR/urgs-rag"
PRESENTATION_DIR="$SCRIPT_DIR/urgs+-presentation-platform"

pids=()

# Flags for services
ENABLE_BACKEND=false
ENABLE_EXECUTOR=false
ENABLE_FRONTEND=false
ENABLE_RAG=false
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
  if [ -f "$SCRIPT_DIR/../.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/../.env" | xargs)
  elif [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
  fi
}

configure_database_env() {
  load_env_file

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

cleanup() {
  echo "Stopping services..."
  for pid in "${pids[@]:-}"; do
    kill "$pid" 2>/dev/null || true
  done
}
trap cleanup EXIT

start_backend() {
  echo "Starting backend (profile: $ENVIRONMENT)..."
  cd "$API_DIR"
  kill_port_if_exists 8080
  configure_database_env

  # Explicitly export RAG properties to avoid placeholder resolution issues
  export RAG_BASE_URL="${RAG_SERVICE_URL:-http://localhost:8001}/api/rag"
  export AI_RAG_BASE_URL="$RAG_BASE_URL"
  export AI_RAG_DOC_STORE_PATH="${RAG_DOC_STORE_PATH:-${SCRIPT_DIR}/../urgs-rag/doc_store}"

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

  ./mvnw spring-boot:run -Dspring-boot.run.profiles="$ENVIRONMENT" &
  pids+=($!)
}

start_frontend() {
  echo "Starting frontend ($ENVIRONMENT)..."
  cd "$WEB_DIR"
  kill_port_if_exists 3000
  kill_port_if_exists 3001
  ensure_npm_dependency "$WEB_DIR" vite

  if [ "$ENVIRONMENT" = "dev" ]; then
    "$NPM_BIN" run dev -- --host &
  else
    "$NPM_BIN" run build
  fi
  pids+=($!)
}

start_rag() {
  echo "Starting rag..."
  cd "$RAG_DIR"
  
  if [ ! -d ".venv" ]; then
    echo "Creating virtual environment for RAG..."
    chmod +x install_env.sh
    ./install_env.sh
  fi

  kill_port_if_exists 8001
  
  if [ "$ENVIRONMENT" = "dev" ]; then
    .venv_312/bin/uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload --loop asyncio &
  else
    .venv_312/bin/uvicorn app.main:app --host 0.0.0.0 --port 8001 --loop asyncio &
  fi
  pids+=($!)
}

start_executor() {
  echo "Starting executor..."
  cd "$EXECUTOR_DIR"
  kill_port_if_exists 8082
  configure_database_env
  ./mvnw spring-boot:run -Dspring-boot.run.profiles="$ENVIRONMENT" &
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
  echo "Starting agent..."
  cd "$AGENT_DIR"
  kill_port_if_exists 8002
  
  # Ensure script is executable
  chmod +x start.sh
  ./start.sh &
  pids+=($!)
}

# --- Interactive Menu ---
echo "Multiple services detected. Please select which ones to start:"
echo "  [1] All Services (Backend, Executor, Frontend, RAG, Agent)"
echo "  [2] Backend (urgs-api)"
echo "  [3] Executor (urgs-executor)"
echo "  [4] Frontend (urgs-web)"
echo "  [5] RAG (urgs-rag)"
echo "  [6] Presentation (urgs-presentation)"
echo "  [7] Agent (urgs-agent)"
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
      ;;
    2) ENABLE_BACKEND=true ;;
    3) ENABLE_EXECUTOR=true ;;
    4) ENABLE_FRONTEND=true ;;
    5) ENABLE_RAG=true ;;
    6) ENABLE_PRESENTATION=true ;;
    7) ENABLE_AGENT=true ;;
    *) echo "Unknown option: $choice (ignored)" ;;
  esac
done

if [ "$ENABLE_BACKEND" = true ] && [ "$ENABLE_FRONTEND" = true ] && [ "$ENABLE_EXECUTOR" != true ]; then
  echo "Backend + frontend selected; enabling executor because task trigger APIs call urgs-executor on port 8082."
  ENABLE_EXECUTOR=true
fi

if [ "$ENABLE_BACKEND" = true ]; then start_backend; fi
if [ "$ENABLE_EXECUTOR" = true ]; then start_executor; fi
if [ "$ENABLE_FRONTEND" = true ] || [ "$ENABLE_PRESENTATION" = true ]; then resolve_node_runtime; fi
if [ "$ENABLE_FRONTEND" = true ]; then start_frontend; fi
if [ "$ENABLE_RAG" = true ]; then start_rag; fi
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
