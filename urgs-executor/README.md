# URGS Executor (Unified Resource Governance System Executor)

URGS Executor 是统一资源治理系统的任务执行引擎。它作为独立服务直接扫描共享库中的 `t_quartz_task / t_quartz_task_status`，并执行任务。

## ✨ 核心功能

### 1. 任务扫描与执行
- **定时扫描**: 每分钟按 `task_cron` 扫描活跃任务并下发。
- **依赖补偿**: 每 30 秒检查 `WAITING` 任务，前置完成后自动触发。
- **执行类型**:
  - `task_type=1`: SSH 执行脚本命令
  - `task_type=2`: JDBC 执行存储过程

### 2. 状态流转
- `WAITING -> RUNNING -> SUCCESS/FAILED`
- 防重入：同一 `taskId_dataDate` 不会重复执行。
- 支持重试：按任务 `period` 进行最多 3 次重试。

### 3. 资源隔离与并发控制
- 采用线程池管理任务执行，确保系统稳定性。
- 支持配置最大并发任务数。

## 🛠 技术栈

- **核心框架**: [Spring Boot 3.x](https://spring.io/projects/spring-boot)
- **持久层**: [MyBatis-Plus](https://baomidou.com/)
- **数据库**: MySQL 8.0 (共享 urgs-api 数据库)
- **进程管理**: Java `ProcessBuilder` (用于 Shell/Python 等外部进程调用)
- **工具库**: Hutool, Lombok

## 🚀 快速开始

### 环境要求
- JDK 17+
- Maven 3.6+
- 运行环境需安装相应的执行依赖 (如 `python3`, `datax` 等)，视具体任务类型而定。

### 配置文件
在 `src/main/resources/application.properties` 中通过环境变量配置数据库（需与 urgs-api 指向同一库）：

- `URGS_EXECUTOR_DB_URL`
- `URGS_EXECUTOR_DB_USERNAME`
- `URGS_EXECUTOR_DB_PASSWORD`
- `URGS_EXECUTOR_DB_DRIVER`（默认 `com.mysql.cj.jdbc.Driver`）

### 编译与运行

```bash
# 编译打包
mvn clean package -DskipTests

# 运行
java -jar target/urgs-executor-0.0.1-SNAPSHOT.jar
```

### 部署注意事项
- 如果执行 **Shell/Python** 任务，请确保运行 Executor 的用户有权限执行相关命令。
- 如果执行 **DataX** 任务，需要配置 DataX 的环境变量或指定 DataX 的安装路径。

## 📂 目录结构

```
urgs-executor/
├── src/main/java/com/example/executor/
│   ├── quartz/service/TaskDispatcherJob.java
│   ├── quartz/task/DependencyCheckTask.java
│   ├── quartz/service/ExecutorTaskService.java
│   └── UrgsExecutorApplication.java
└── src/main/resources/
    ├── mapper/QuartzTaskMapper.xml
    ├── mapper/QuartzTaskStatusMapper.xml
    └── application.properties
```

## 🤝 贡献指南

1. Fork 本仓库
2. 创建特性分支
3. 提交代码
4. 发起 Pull Request
