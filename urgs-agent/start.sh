#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load .env from parent directory (project root) if exists
if [ -f "../.env" ]; then
    set -a
    source "../.env"
    set +a
fi

echo "Using python: $(python3 --version)"

# Check if .venv exists, if not create
if [ ! -d ".venv" ] && [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv .venv
fi

# Activate venv
if [ -d ".venv" ]; then
    source .venv/bin/activate
elif [ -d "venv" ]; then
    source "venv/bin/activate"
fi

echo "Installing/Updating dependencies..."
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple -e ".[dev]"

# Export default environment variables if not set
export OPENAI_BASE_URL=${OPENAI_BASE_URL:-"http://localhost:11434/v1"}
export OPENAI_API_KEY=${OPENAI_API_KEY:-"dummy"}
export MODEL_NAME=${MODEL_NAME:-"qwen2.5"}
export RAG_SERVICE_URL=${RAG_SERVICE_URL:-"http://localhost:8001"}
export LINEAGE_SERVICE_URL=${LINEAGE_SERVICE_URL:-"http://localhost:8002"}
export API_SERVICE_URL=${API_SERVICE_URL:-"http://localhost:8080"}
export PYTHONPATH=${PYTHONPATH:-}:$(pwd)

echo "Starting urgs-agent on port 8002..."
python -m uvicorn app.main:app --reload --port 8002 --host 0.0.0.0
