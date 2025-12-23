# URGS API (Unified Resource Governance System Backend)

URGS API 是统一资源治理系统的核心后端服务，基于 Spring Boot 构建。它提供了系统的核心业务逻辑、RESTful API 接口、权限管理以及与执行器 (Executor) 的交互能力。

## ✨ 核心模块

### 1. 任务调度 (Task & Workflow)
- **任务管理**：任务的增删改查 (CRUD)，支持 Shell, SQL, Python 等多种类型。
- **工作流编排**：基于 DAG 的工作流定义、保存与版本管理。
- **调度引擎**：集成 Quartz 调度器，支持 Cron 表达式触发。
- **实例管理**：任务实例的生成、状态流转、日志记录与依赖检查。
- **依赖图谱**：提供任务上下游依赖关系的查询接口。

### 2. 元数据管理 (Metadata)
- **模型管理**：逻辑数据模型 (LDM) 和物理数据模型 (PDM) 的定义与维护。
- **数据源管理**：多源异构数据源的连接配置与测试 (MySQL, Oracle, Hive 等)。
- **血缘分析**：字段级的数据血缘追踪。

### 3. 系统核心
- **认证与授权**：基于 JWT 的身份认证，支持 SSO 单点登录集成。
- **权限控制**：基于 RBAC (Role-Based Access Control) 的细粒度权限管理。
- **组织架构**：用户、角色、部门管理。

### 4. 运维工具
- **SQL 执行**：提供在线 SQL 执行能力的后端支持。
- **系统监控**：系统运行状态指标暴露。

## 🛠 技术栈

- **核心框架**：[Spring Boot 3.x](https://spring.io/projects/spring-boot)
- **持久层**：[MyBatis-Plus](https://baomidou.com/)
- **数据库**：MySQL 8.0
- **任务调度**：[Quartz Scheduler](http://www.quartz-scheduler.org/)
- **API 文档**：Swagger / OpenAPI 3
- **工具库**：Hutool, Lombok, Fastjson2

## 🚀 快速开始

### 环境要求
- JDK 17+
- Maven 3.6+
- MySQL 8.0+

### 配置文件

在 `src/main/resources/application.yml` 中配置数据库连接：

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/urgs?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai
    username: root
    password: your_password
```

### 编译与运行

```bash
# 编译打包
mvn clean package -DskipTests

# 运行
java -jar target/urgs-api-0.0.1-SNAPSHOT.jar
```
服务默认启动在 `8080` 端口。

### API 文档
启动后访问：`http://localhost:8080/swagger-ui/index.html` (如果集成了 Swagger)

## 📂 目录结构

```
urgs-api/
├── src/main/java/com/example/urgs_api/
│   ├── auth/           # 认证授权模块
│   ├── config/         # 全局配置 (Web, Security, Swagger等)
│   ├── datasource/     # 数据源管理模块
│   ├── metadata/       # 元数据管理模块
│   ├── task/           # 任务管理与调度核心模块
│   ├── workflow/       # 工作流管理模块
│   ├── user/           # 用户管理
│   ├── role/           # 角色管理
│   ├── permission/     # 权限管理
│   ├── sql/            # SQL 执行模块
│   └── UrgsApiApplication.java  # 启动类
└── src/main/resources/
    ├── mapper/         # MyBatis XML Mapper 文件
    └── application.yml # 配置文件
```

## 🤝 贡献指南

1. Fork 本仓库
2. 创建特性分支
3. 提交代码
4. 发起 Pull Request
