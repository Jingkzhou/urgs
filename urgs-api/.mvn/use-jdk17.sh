#!/bin/bash
# =============================================================
# Maven Wrapper 启动脚本 - 确保使用 JDK 17 编译
# 用法: source .mvn/use-jdk17.sh && ./mvnw clean compile
# 或直接: JAVA_HOME=$(/usr/libexec/java_home -v 17) ./mvnw clean compile
# =============================================================
export JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null)
if [ -z "$JAVA_HOME" ]; then
    echo "❌ 未找到 JDK 17，请先安装: brew install --cask temurin@17"
    return 1 2>/dev/null || exit 1
fi
echo "✅ JAVA_HOME 已设置为: $JAVA_HOME"
echo "   Java 版本: $(java -version 2>&1 | head -1)"
