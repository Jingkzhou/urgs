# URGS (Unified Resource Governance System)

URGS 是一个企业级统一资源治理与调度系统。它集成了任务调度、数据治理（元数据与血缘分析）、知识库检索（RAG）以及可视化的运维监控能力。

## 🏗️ 软件架构

本项目采用微服务架构，包含以下核心模块：

| 模块 | 目录 | 说明 | 技术栈 |
| --- | --- | --- | --- |
| **Backend API** | [urgs-api](./urgs-api) | 核心后端服务，负责业务逻辑、调度管理、Auth等 | Spring Boot 3, MyBatis-Plus, Quartz |
| **Frontend** | [urgs-web](./urgs-web) | 现代化前端界面 | React 18, Vite, Ant Design, Tailwind |
| **Executor** | [urgs-executor](./urgs-executor) | 独立任务执行引擎，支持分布式部署 | Spring Boot 3, ProcessBuilder |
| **AI / RAG** | [urgs-rag](./urgs-rag) | 智能知识库与检索服务，支持 SQL 解释与问答 | Python 3.10, LangChain, ChromaDB |
| **Lineage** | [sql-lineage-engine](./sql-lineage-engine) | SQL 血缘分析引擎 | Python, Java (GSP) |

## 🚀 快速开始 (Docker 部署)

推荐使用 Docker Compose 快速启动完整环境。

### 1. 环境准备
- Docker & Docker Compose

### 2. 构建与启动
```bash
# 构建所有服务镜像 (首次运行需较长时间下载依赖)
docker-compose build

# 启动服务
docker-compose up -d
```


### 3. 访问服务

启动成功后，各服务访问地址如下：

| 服务 | 地址 | 默认账号/备注 |
| --- | --- | --- |
| **前端页面** | [http://localhost:3000](http://localhost:3000) | - |
| **后端接口** | [http://localhost:8080/swagger-ui.html](http://localhost:8080/swagger-ui.html) | API 文档 |
| **RAG 文档** | [http://localhost:8001/doc](http://localhost:8001/doc) | AI 服务接口文档 |
| **Neo4j** | [http://localhost:7474](http://localhost:7474) | neo4j / 12345678 |
| **MySQL** | `localhost:3306` | root / a8548879 (库: urgs_dev) |

> 💡 **提示**: 
> - 生产环境部署请参考下方 [生产环境配置](#生产环境配置) 章节。
> - 构建 Python 镜像时已配置清华源镜像加速。

---

## 💻 本地开发指南

如果您需要独立开发某个模块，请参考以下指南。

### 数据准备
确保本地已安装 **MySQL 8.0+** 和 **Neo4j 5.x**。
初始化数据库脚本位于根目录 `migrated_urgs_data.sql`。

### 1. 后端 (urgs-api)
```bash
cd urgs-api
# 编译并运行 (默认 dev 环境)
./mvnw spring-boot:run
# 或打包
./mvnw clean package -DskipTests
```
配置文件：`src/main/resources/application.properties`

### 2. 前端 (urgs-web)
确保 Node.js >= 16。
```bash
cd urgs-web
npm install
npm run dev
```
访问地址：`http://localhost:5173`

### 3. 执行器 (urgs-executor)
需配置与 api 相同的数据库连接。
```bash
cd urgs-executor
./mvnw spring-boot:run
```

### 4. 智能服务 (urgs-rag)
确保 Python 3.10+ 和 Java 21 (用于依赖库)。
```bash
cd urgs-rag
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8001
```

---

## ⚙️ 生产环境配置

如需部署生产环境（Prod）：

1.  **修改环境变量**: 
    在 `docker-compose.yml` 中，将 `urgs-api` 和 `urgs-executor` 的 `SPRING_PROFILES_ACTIVE` 从 `dev` 改为 `prod`。
    
2.  **配置生产参数**:
    确保 `urgs-api/src/main/resources/config/prod/application.properties` 中配置了正确的生产数据库地址。

3.  **重新部署**:
    ```bash
    docker-compose up -d --build
    ```

## 🤝 参与贡献

1.  Fork 本仓库
2.  新建 Feat_xxx 分支
3.  提交代码
4.  新建 Pull Request

## 📄 许可证

[MIT](LICENSE)
