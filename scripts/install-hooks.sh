#!/bin/bash

# Script to install git hooks
HOOK_DIR=".git/hooks"
PRE_COMMIT_SRC="scripts/pre-commit-hook.sh"

if [ ! -d ".git" ]; then
    echo "❌ 错误: 当前目录不是 Git 仓库根目录。"
    exit 1
fi

cp "$PRE_COMMIT_SRC" "$HOOK_DIR/pre-commit"
chmod +x "$HOOK_DIR/pre-commit"

echo "✅ Git hooks 已安装成功。"
