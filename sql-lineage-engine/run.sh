#!/bin/bash
export PYTHONPATH=$(pwd)
exec python3 bin/lineage-cli "$@"
