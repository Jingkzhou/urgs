#!/bin/bash

# 打印带颜色的信息
print_info() {
  echo -e "\033[1;34m[INFO] $1\033[0m"
}

print_error() {
  echo -e "\033[1;31m[ERROR] $1\033[0m"
}

print_success() {
  echo -e "\033[1;32m[SUCCESS] $1\033[0m"
}

# 检查 Node.js 是否安装
if ! command -v node &> /dev/null; then
    print_error "未检测到 Node.js，请先安装 Node.js (推荐 v18+)"
    exit 1
fi

# 检查 npm 是否安装
if ! command -v npm &> /dev/null; then
    print_error "未检测到 npm，请检查 Node.js 安装情况"
    exit 1
fi

print_info "环境检查通过: Node.js $(node -v), npm $(npm -v)"

# 检查依赖是否安装
if [ ! -d "node_modules" ]; then
    print_info "未检测到 node_modules，正在安装依赖..."
    npm install
    if [ $? -eq 0 ]; then
        print_success "依赖安装完成"
    else
        print_error "依赖安装失败，请手动检查"
        exit 1
    fi
else
    print_info "依赖已安装，跳过安装步骤"
fi

# 启动开发服务器
print_info "正在启动开发服务器..."
npm run dev
