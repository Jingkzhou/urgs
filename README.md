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
> - 生产环境部署请参考下方 [环境配置](#️-环境配置) 章节。
> - 构建 Python 镜像时已配置清华源镜像加速。

### 4. 服务调用说明

#### urgs-api / urgs-executor / urgs-web / urgs-rag
这些服务在 `docker-compose up -d` 后自动启动，无需手动干预。

```bash
# 查看服务日志
docker-compose logs -f urgs-api
docker-compose logs -f urgs-executor
docker-compose logs -f urgs-rag

# 重启单个服务
docker-compose restart urgs-api
```

#### sql-lineage-engine (SQL 血缘分析)
该服务是命令行工具，需通过 `docker exec` 调用：

```bash
# 解析单条 SQL 并导出到 Neo4j
docker exec -it urgs-sql-lineage-engine-1 ./run.sh parse-sql \
  --sql "INSERT INTO B SELECT * FROM A" \
  --dialect mysql \
  --output neo4j

# 批量解析目录中的 SQL 文件
docker exec -it urgs-sql-lineage-engine-1 ./run.sh parse-sql \
  --file ./tests/sql/ \
  --output json

# 或使用 docker-compose run (一次性执行)
docker-compose run --rm sql-lineage-engine parse-sql --help
```

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

## ⚙️ 环境配置

所有环境相关的配置均通过根目录下的 `.env` 文件进行统一管理。Docker Compose 会自动读取该文件并将变量注入到各服务容器中。

### 配置步骤

1.  **复制模板文件**:
    ```bash
    cp .env.example .env
    ```

2.  **修改 `.env` 文件**:
    根据您的部署环境（开发、测试、生产），修改 `.env` 文件中的数据库地址、端口、密码等配置项。

3.  **启动服务**:
    ```bash
    docker-compose up -d --build
    ```

### 生产环境部署 (离线导入镜像)

如果生产服务器无法直接构建镜像，可先在开发机导出镜像，再导入生产环境。

#### 1. 开发机：构建并导出镜像
```bash
# 构建所有镜像
docker-compose build

# 导出镜像为 tar 文件
docker save -o urgs-images.tar \
  urgs-api:latest \
  urgs-executor:latest \
  urgs-web:latest \
  urgs-rag:latest \
  sql-lineage-engine:latest \
  neo4j:5.15.0
```

#### 2. 传输文件到生产服务器
将以下文件传输到生产服务器：
- `urgs-images.tar` (镜像包)
- `docker-compose.yml`
- `.env.example` (复制为 `.env` 后修改)

#### 3. 生产服务器：导入镜像并启动
```bash
# 导入镜像
docker load -i urgs-images.tar

# 配置环境变量
cp .env.example .env
# 编辑 .env 文件，设置生产数据库地址等

# 启动服务 (不需要 --build)
docker-compose up -d
```

### 增量更新 / 单独更新服务 (例如 urgs-api)

如果只修复了某个服务的代码 (例如 `urgs-api`)，不需要重新部署所有服务。

#### 1. 开发机：重新构建并导出该服务的镜像
```bash
# 只构建 urgs-api
docker-compose build urgs-api

# 导出 urgs-api 镜像
docker save -o urgs-api-update.tar urgs-api:latest
```

#### 2. 传输文件
将 `urgs-api-update.tar` 传输到生产服务器。

#### 3. 生产服务器：更新服务
```bash
# 导入新镜像
docker load -i urgs-api-update.tar

# 重建并重启该服务 (Docker Compose 会自动检测到镜像变化)
docker-compose up -d --no-deps urgs-api
```


# 1. 停掉并删除所有容器
docker rm -f $(docker ps -aq)

# 2. 删除所有镜像
docker rmi -f $(docker images -aq)

# 3. 顺手清理缓存/网络/构建残留
docker system prune -af

## 🤝 参与贡献

1.  Fork 本仓库
2.  新建 Feat_xxx 分支
3.  提交代码
4.  新建 Pull Request


## 📄 许可证

[MIT](LICENSE)
