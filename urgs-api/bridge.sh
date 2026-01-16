#!/bin/sh
# 转发命令到 urgs-sql-lineage-engine-1 容器执行
# 注意：容器名称需要与 docker-compose 生成的一致
# Dynamically find the running container name for sql-lineage-engine
CONTAINER_NAME=$(docker ps --format "{{.Names}}" | grep "sql-lineage-engine" | head -n 1)

if [ -z "$CONTAINER_NAME" ]; then
    echo "Error: Could not find a running container for sql-lineage-engine" >&2
    exit 1
fi



if [ "$1" = "--kill-engine" ]; then
    echo "Stopping lineage engine (Force Kill)..."
    
    # Debug: show processes before kill
    echo "=== Processes before kill ==="
    docker exec "$CONTAINER_NAME" ps aux | grep -E "(python|PID)" || echo "No python process found"
    
    # 循环尝试杀死所有 Python 进程，最多重试 3 次
    MAX_RETRIES=3
    for i in $(seq 1 $MAX_RETRIES); do
        echo ">>> Kill attempt $i of $MAX_RETRIES"
        
        # 1. 使用 pgrep 获取所有 Python 进程 PID
        PIDS=$(docker exec "$CONTAINER_NAME" pgrep -f "python" 2>/dev/null || true)
        
        if [ -z "$PIDS" ]; then
            echo "No Python processes found. Engine stopped successfully."
            break
        fi
        
        echo "Found PIDs: $PIDS"
        
        # 2. 精确杀死每个 PID
        for PID in $PIDS; do
            echo "Killing PID $PID..."
            docker exec "$CONTAINER_NAME" kill -9 "$PID" 2>/dev/null || true
        done
        
        # 3. 备用方法：pkill 和 killall
        # 3. 备用方法：pkill 和 killall
        # Remove error suppression to see why commands fail
        docker exec "$CONTAINER_NAME" pkill -9 -f "lineage-cli" || echo "pkill lineage-cli failed"
        docker exec "$CONTAINER_NAME" pkill -9 -f "python" || echo "pkill python failed"
        
        # Check if killall exists before running
        if docker exec "$CONTAINER_NAME" command -v killall >/dev/null 2>&1; then
            docker exec "$CONTAINER_NAME" killall -9 python3 || echo "killall python3 failed"
            docker exec "$CONTAINER_NAME" killall -9 python || echo "killall python failed"
        else
            echo "command 'killall' not found in container"
        fi
        
        # 等待进程终止
        sleep 1
    done
    
    # 最终验证
    echo "=== Final verification ==="
    REMAINING=$(docker exec "$CONTAINER_NAME" pgrep -f "python" 2>/dev/null || true)
    if [ -z "$REMAINING" ]; then
        echo "SUCCESS: All Python processes terminated."
    else
        echo "WARNING: Some processes may still be running: $REMAINING"
        # 最后手段：使用 SIGKILL 对剩余进程
        for PID in $REMAINING; do
            docker exec "$CONTAINER_NAME" kill -9 "$PID" 2>/dev/null || true
        done
    fi
    
    echo "Kill commands executed."
    exit 0
fi

docker exec "$CONTAINER_NAME" /sql-lineage-engine/run.sh "$@"
