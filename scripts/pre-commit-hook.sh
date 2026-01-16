#!/bin/bash

# Pre-commit hook logic
DATE=$(date +%Y-%m-%d)
RECORD_FILE="docs/release-notes/$DATE.md"

if [ ! -f "$RECORD_FILE" ]; then
    echo "💡 未检测到今日变更记录，正在自动为您生成模板..."
    # Run the generator script
    python3 scripts/changelog.py
    # Automatically add the new record file to the current commit
    git add "$RECORD_FILE"
    echo "⚠️  注意: 已自动生成 $RECORD_FILE 并加入提交，请确保后续补充详细摘要内容。"
fi

if grep -q "\[请在此填写变更的核心内容\]" "$RECORD_FILE"; then
    echo "⚠️ 警告: 变更记录内容尚未填写 (包含默认占位符)。"
    echo "请编辑 $RECORD_FILE 描述本次变更的具体内容。"
    exit 1
fi

# Note: We don't block on [AUTO_GEN] because commit-msg hook will sync it.
echo "✅ 变更记录检查通过 (包含自动生成内容)。"
exit 0
