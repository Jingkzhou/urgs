# URGS Executor (Unified Resource Governance System Executor)

URGS Executor 是统一资源治理系统的任务执行引擎。它作为一个独立的服务运行，负责接收调度中心分发的任务，并在本地或远程环境中执行具体的业务逻辑。

## ✨ 核心功能

### 1. 多类型任务执行
Executor 内置了多种 TaskHandler，支持执行不同类型的任务：
- **ShellHandler**: 执行本地 Shell 脚本或命令。
- **SqlHandler**: 连接数据库执行 SQL 语句 (支持 MySQL, Oracle, PG 等)。
- **PythonHandler**: 执行 Python 脚本。
- **DataXHandler**: 调度 DataX 任务进行数据同步。
- **HttpHandler**: 发送 HTTP 请求 (GET/POST)。
- **ProcedureHandler**: 执行数据库存储过程。

### 2. 任务生命周期管理
- **任务拉取**: 定时从数据库或队列中拉取待执行的任务实例。
- **状态上报**: 实时监控任务执行状态 (Running, Success, Failed) 并上报给调度中心。
- **日志采集**: 实时捕获任务执行的标准输出 (stdout) 和标准错误 (stderr)，并持久化保存，供前端查看。
- **超时控制**: 支持任务执行超时自动终止。

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

在 `src/main/resources/application.yml` 中配置数据库连接（需与 urgs-api 指向同一数据库）：

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/urgs?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai
    username: root
    password: your_password

executor:
  max-threads: 20  # 最大并发执行线程数
  log-path: /var/log/urgs/tasks # 任务日志本地存储路径
```

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
├── src/main/java/com/example/executor/urgs_executor/
│   ├── handler/        # 核心：各种任务类型的处理器实现 (ShellHandler, SqlHandler等)
│   ├── job/            # 定时任务 (如任务拉取 Job)
│   ├── entity/         # 实体类
│   ├── mapper/         # 数据访问层
│   ├── service/        # 业务逻辑层
│   ├── config/         # 配置类
│   ├── util/           # 工具类
│   └── UrgsExecutorApplication.java  # 启动类
└── src/main/resources/
    ├── mapper/         # MyBatis XML Mapper
    └── application.yml # 配置文件
```

## 🤝 贡献指南

1. Fork 本仓库
2. 创建特性分支
3. 提交代码
4. 发起 Pull Request
