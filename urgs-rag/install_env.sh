#!/usr/bin/env bash
set -euo pipefail

# ---- config ----
VENV_DIR=".venv"
# Choose ONE mirror (uncomment one). Default: TUNA (tsinghua)
PIP_INDEX_URL="https://pypi.tuna.tsinghua.edu.cn/simple"
PIP_TRUSTED_HOST="pypi.tuna.tsinghua.edu.cn"

# Aliyun:
# PIP_INDEX_URL="https://mirrors.aliyun.com/pypi/simple"
# PIP_TRUSTED_HOST="mirrors.aliyun.com"

# Tencent:
# PIP_INDEX_URL="https://mirrors.cloud.tencent.com/pypi/simple"
# PIP_TRUSTED_HOST="mirrors.cloud.tencent.com"
# ----------------

echo "==> Detecting a compatible Python (prefer 3.11)..."

# Prefer python3.11, then 3.12, then 3.10, then python3
CANDIDATES=(python3.11 python3.12 python3.10 python3)

PYTHON_CMD=""
for c in "${CANDIDATES[@]}"; do
  if command -v "$c" >/dev/null 2>&1; then
    # Check version major.minor
    ver=$("$c" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    if [[ "$ver" == "3.10" || "$ver" == "3.11" || "$ver" == "3.12" ]]; then
      PYTHON_CMD="$c"
      break
    fi
  fi
done

if [[ -z "$PYTHON_CMD" ]]; then
  echo "ERROR: No compatible Python found (need 3.10/3.11/3.12)."
  echo "Your current python3 might be 3.13 which often breaks ML/OCR deps (onnxruntime, rapidocr, etc.)."
  echo
  echo "Fix options:"
  echo "  1) conda:   conda create -n urgs-rag-py311 python=3.11 -y"
  echo "             conda activate urgs-rag-py311"
  echo "             then re-run this script"
  echo "  2) pyenv:   pyenv install 3.11.8 && pyenv local 3.11.8"
  exit 1
fi

echo "==> Using: $PYTHON_CMD ($("$PYTHON_CMD" --version))"

echo "==> Recreating venv at $VENV_DIR ..."
rm -rf "$VENV_DIR"
"$PYTHON_CMD" -m venv "$VENV_DIR"

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

echo "==> Upgrading pip/setuptools/wheel ..."
python -m pip install --upgrade pip setuptools wheel \
  -i "$PIP_INDEX_URL" --trusted-host "$PIP_TRUSTED_HOST"

echo "==> Installing requirements ..."
# Prefer binary wheels to avoid compiling surprises
python -m pip install --prefer-binary -r requirements.txt \
  -i "$PIP_INDEX_URL" --trusted-host "$PIP_TRUSTED_HOST"

echo
echo "✅ Done."
echo "Activate with: source $VENV_DIR/bin/activate"
echo "Python: $(python -V)"
echo "pip:    $(pip -V)"
