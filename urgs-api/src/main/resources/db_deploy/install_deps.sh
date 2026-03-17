#!/bin/bash
# 离线安装数据库驱动（内网/无外网环境使用）
# 部署包生成时已根据数据库类型自动打入对应 .whl 文件

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DRIVER_DIR="$SCRIPT_DIR/drivers"

if [ ! -d "$DRIVER_DIR" ]; then
    echo "[INFO] 未找到 drivers/ 目录，跳过离线安装"
    exit 0
fi

WHL_FILES=$(ls "$DRIVER_DIR"/*.whl 2>/dev/null)
if [ -z "$WHL_FILES" ]; then
    echo "[INFO] drivers/ 目录中无 .whl 文件，跳过离线安装"
    echo "[HINT] 如需在线安装，请手动执行: pip3 install cx_Oracle 或 pip3 install pymysql"
    exit 0
fi

echo "[INFO] 从 $DRIVER_DIR 离线安装驱动..."
pip3 install --no-index --find-links="$DRIVER_DIR" $WHL_FILES
if [ $? -eq 0 ]; then
    echo "[OK] 驱动安装完成"
else
    echo "[ERROR] 驱动安装失败，请检查 Python 版本与 .whl 文件是否匹配"
    exit 1
fi
