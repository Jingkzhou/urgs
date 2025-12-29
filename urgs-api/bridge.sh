#!/bin/sh
# 转发命令到 urgs-sql-lineage-engine-1 容器执行
# 注意：容器名称需要与 docker-compose 生成的一致
# Dynamically find the running container name for sql-lineage-engine
CONTAINER_NAME=$(docker ps --format "{{.Names}}" | grep "sql-lineage-engine" | head -n 1)

if [ -z "$CONTAINER_NAME" ]; then
    echo "Error: Could not find a running container for sql-lineage-engine" >&2
    exit 1
fi

docker exec "$CONTAINER_NAME" /sql-lineage-engine/run.sh "$@"
