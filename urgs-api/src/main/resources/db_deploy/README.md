# db_deploy — 数据库版本一键部署引擎

## 简介
`db_deploy` 是配套 URGS 系统的离线部署引擎。它能够读取 URGS 生成的 ZIP 版本包，自动验证包的完整性，并按计划执行数据库变更。

## 快速开始

### 1. 安装依赖
需安装对应数据库类型的驱动：
```bash
pip install cx_Oracle pymysql
```

### 2. 配置连接
```bash
mkdir -p ~/.db_deploy
cp connections.template.json ~/.db_deploy/connections.json
# 修改 connections.json 填写实际用户名密码
```

### 3. 执行部署
```bash
# 校验包（不执行）
python -m db_deploy.cli.main check --pkg ./deploy_v1.0.0.zip

# 正式执行
python -m db_deploy.cli.main deploy --pkg ./deploy_v1.0.0.zip --operator zhangsan
```

## 功能特性
- **双轨日志**: 同步生成人类可读日志与 JSONL 结构化事件流。
- **自动备份**: `backup_table` 步骤会自动创建 `BAK_{TABLE}_{TS}`。
- **断点续跑**: 支持 `--resume` 参数，从上次失败位置继续。
- **完整性校验**: 强制 Checksum (SHA-256) 校验。
