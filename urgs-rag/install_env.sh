#!/bin/bash
set -e

# 1. Check for Python 3.11
PYTHON_CMD="python3.11"
if ! command -v $PYTHON_CMD &> /dev/null; then
    echo "Python 3.11 not found. Trying python3..."
    PYTHON_CMD="python3"
fi

# Verify version is not 3.13
VER=$($PYTHON_CMD --version)
echo "Using $VER"
if [[ "$VER" == *"3.13"* ]]; then
    echo "Warning: Python 3.13 detected. This might cause dependency issues."
    echo "Recommended: Python 3.10, 3.11 or 3.12"
fi

# 2. Create venv
echo "Creating virtual environment in .venv..."
rm -rf .venv
$PYTHON_CMD -m venv .venv

# 3. Install dependencies
echo "Installing dependencies..."
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo "Done! Activate with: source .venv/bin/activate"
