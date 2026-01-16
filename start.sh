#!/usr/bin/env bash
set -euo pipefail

# Force Java 17 for Lombok compatibility
export JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH
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
  # Load .env if exists
  if [ -f "$SCRIPT_DIR/../.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/../.env" | xargs)
  elif [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
  fi

  # Construct DataSource URL if var exists
  if [ -n "${DB_HOST:-}" ]; then
    export SPRING_DATASOURCE_URL="jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}?useSSL=false&serverTimezone=UTC&characterEncoding=utf8&allowPublicKeyRetrieval=true"
    export SPRING_DATASOURCE_USERNAME="${DB_USER}"
    export SPRING_DATASOURCE_PASSWORD="${DB_PASSWORD}"
  fi

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
  if [ ! -d node_modules ]; then
    npm install
  fi

  if [ "$ENVIRONMENT" = "dev" ]; then
    npm run dev -- --host &
  else
    npm run build
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
  kill_port_if_exists 8081
  ./mvnw spring-boot:run -Dspring-boot.run.profiles="$ENVIRONMENT" -Dspring-boot.run.arguments="--server.port=8081" &
  pids+=($!)
}



start_presentation() {
  echo "Starting presentation platform..."
  cd "$PRESENTATION_DIR"
  kill_port_if_exists 3002
  if [ ! -d node_modules ]; then
    npm install
  fi
  npm run dev -- --host --port 3002 &
  pids+=($!)
}

# --- Interactive Menu ---
echo "Multiple services detected. Please select which ones to start:"
echo "  [1] All Services (Backend, Executor, Frontend, RAG)"
echo "  [2] Backend (urgs-api)"
echo "  [3] Executor (urgs-executor)"
echo "  [4] Frontend (urgs-web)"
echo "  [5] RAG (urgs-rag)"
echo "  [6] Presentation (urgs-presentation)"
echo ""
echo "Enter your choice (e.g., '1' for all, or '2 3' for Backend+Executor):"
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
      ;;
    2) ENABLE_BACKEND=true ;;
    3) ENABLE_EXECUTOR=true ;;
    4) ENABLE_FRONTEND=true ;;
    5) ENABLE_RAG=true ;;
    6) ENABLE_PRESENTATION=true ;;
    *) echo "Unknown option: $choice (ignored)" ;;
  esac
done

if [ "$ENABLE_BACKEND" = true ]; then start_backend; fi
if [ "$ENABLE_EXECUTOR" = true ]; then start_executor; fi
if [ "$ENABLE_FRONTEND" = true ]; then start_frontend; fi
if [ "$ENABLE_RAG" = true ]; then start_rag; fi
if [ "$ENABLE_PRESENTATION" = true ]; then start_presentation; fi

if [ ${#pids[@]} -eq 0 ]; then
  echo "No services selected. Exiting."
  exit 0
fi

echo "Selected services are running. Press Ctrl+C to stop."

# Portable wait-for-any (macOS bash 3.x lacks `wait -n`)
while true; do
  for pid in "${pids[@]}"; do
    if ! kill -0 "$pid" 2>/dev/null; then
      echo "A process has exited; shutting down others."
      exit 0
    fi
  done
  sleep 1
done
