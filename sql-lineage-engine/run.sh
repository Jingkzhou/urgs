#!/bin/bash
export PYTHONPATH=$(pwd)

if [ -x "$(pwd)/.venv/bin/python" ]; then
  exec "$(pwd)/.venv/bin/python" bin/lineage-cli "$@"
fi

exec python3 bin/lineage-cli "$@"
