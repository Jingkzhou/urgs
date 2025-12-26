#!/bin/bash

# Pre-commit hook logic
DATE=$(date +%Y-%m-%d)
RECORD_FILE="docs/release-notes/$DATE.md"

if [ ! -f "$RECORD_FILE" ]; then
    echo "❌ 错误: 未检测到当日变更记录文件: $RECORD_FILE"
    echo "请运行 './scripts/changelog.py' 生成模板并填写变更内容后再提交。"
    exit 1
fi

if grep -q "\[请在此填写变更的核心内容\]" "$RECORD_FILE"; then
    echo "⚠️ 警告: 变更记录内容尚未填写 (包含默认占位符)。"
    echo "请编辑 $RECORD_FILE 描述本次变更的具体内容。"
    exit 1
fi

exit 0
