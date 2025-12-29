#!/bin/sh
# 转发命令到 urgs-sql-lineage-engine-1 容器执行
# 注意：容器名称需要与 docker-compose 生成的一致
docker exec urgs-sql-lineage-engine-1 /sql-lineage-engine/run.sh "$@"
