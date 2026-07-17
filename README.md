# URGS (Unified Resource Governance System)

URGS 是一个企业级统一资源治理与调度系统。它集成了任务调度、数据治理（元数据与血缘分析）、AI 智能体以及可视化的运维监控能力。

## 🏗️ 软件架构

本项目采用微服务架构，包含以下核心模块：

| 模块             | 目录                                                         | 说明                                         | 技术栈                                     |
| ---------------- | ------------------------------------------------------------ | -------------------------------------------- | ------------------------------------------ |
| **Backend API**  | [urgs-api](./urgs-api)                                       | 核心后端服务，负责业务逻辑、调度管理、Auth等 | Spring Boot 3, MyBatis-Plus, Quartz        |
| **Frontend**     | [urgs-web](./urgs-web)                                       | 现代化前端界面                               | React 18, Vite, Ant Design, Tailwind       |
| **Executor**     | [urgs-executor](./urgs-executor)                             | 独立任务执行引擎，支持分布式部署             | Spring Boot 3, ProcessBuilder              |
| **AI Agent**     | [urgs-agent](./urgs-agent)                                   | 智能体运行时与工具编排                       | Python, LangGraph                          |
| **Lineage**      | [sql-lineage-engine](./sql-lineage-engine)                   | SQL 血缘分析引擎                             | Python, Java (GSP)                         |
| **Presentation** | [urgs+-presentation-platform](./urgs+-presentation-platform) | 演示交互平台                                 | React, Vite, Tailwind                      |
| **Dify AI**      | [urgs-dify](./urgs-dify)                                     | 全栈 LLM 应用开发平台 (Integrated)           | Python (Flask), Next.js, PostgreSQL, Redis |

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

| 服务             | 地址                                                                           | 默认账号/备注                  |
| ---------------- | ------------------------------------------------------------------------------ | ------------------------------ |
| **前端页面**     | [http://localhost:3000](http://localhost:3000)                                 | -                              |
| **后端接口**     | [http://localhost:8080/swagger-ui.html](http://localhost:8080/swagger-ui.html) | API 文档                       |
| **Neo4j**        | [http://localhost:7474](http://localhost:7474)                                 | neo4j / 12345678               |
| **Presentation** | [http://localhost:3002](http://localhost:3002)                                 | -                              |
| **MySQL**        | `localhost:3306`                                                               | root / a8548879 (库: urgs_dev) |
| **Dify 控制台**  | [http://localhost:5001](http://localhost:5001)                                 | 首次启动需设置管理员账号       |

> 💡 **提示**: 
> - 生产环境部署请参考下方 [环境配置](#️-环境配置) 章节。
> - 构建 Python 镜像时已配置清华源镜像加速。

### 4. 服务调用说明

#### urgs-api / urgs-executor / urgs-web / urgs-agent
这些服务在 `docker-compose up -d` 后自动启动，无需手动干预。

```bash
# 查看服务日志
docker-compose logs -f urgs-api
docker-compose logs -f urgs-executor
docker-compose logs -f urgs-agent
docker-compose logs -f urgs-dify-api

# 重启单个服务
docker-compose restart urgs-api
docker-compose restart urgs-dify-api
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

## 🧰 在线文档（ONLYOFFICE Docs）

前端“工具”页签中的“在线文档”使用 ONLYOFFICE Docs 进行 Office/PDF 在线预览、编辑和协同。开发环境可单独启动 Document Server：

```bash
docker run -d --name urgs-onlyoffice \
  -p 8088:80 \
  -e JWT_ENABLED=true \
  -e JWT_SECRET=<替换为随机密钥> \
  --restart unless-stopped \
  onlyoffice/documentserver:latest
```

本地 API 默认读取以下配置：

```bash
export ONLYOFFICE_DOCUMENT_SERVER_URL=http://localhost:8088
export URGS_API_BASE_URL=http://host.docker.internal:8080
export ONLYOFFICE_CALLBACK_SECRET=<替换为随机密钥>
export ONLYOFFICE_JWT_SECRET=<与 JWT_SECRET 保持一致>
```

`URGS_API_BASE_URL` 必须是 ONLYOFFICE Document Server 可以访问的后端地址，用于读取 `/profile/**` 文件和回调保存编辑结果。生产环境请在 `deploy/templates/deploy.<env>.env` 中改成实际内网或网关地址。

---


## 💻 本地开发指南

如果您需要独立开发某个模块，请参考以下指南。

`urgs-api` 与 `urgs-executor` 的内部接口必须使用同一个 `URGS_INTERNAL_API_TOKEN`。推荐直接使用
`./start.sh`，脚本会在 `data/internal-api.token` 中生成并复用令牌。若需在不同终端中单独启动服务，先在
每个终端执行以下命令；缺少该变量时两个服务都会拒绝启动：

```bash
TOKEN_FILE="${TMPDIR:-/tmp}/urgs-internal-api.token"
test -s "$TOKEN_FILE" || (umask 077 && openssl rand -hex 32 > "$TOKEN_FILE")
export URGS_INTERNAL_API_TOKEN="$(tr -d '\r\n' < "$TOKEN_FILE")"
```

容器或 Kubernetes 部署同样必须把同一个 `URGS_INTERNAL_API_TOKEN` Secret 注入 API 与 Executor，
不得把固定令牌写入镜像或提交到仓库。

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

### 4. AI 应用平台 (urgs-dify)
Dify 作为子模块引入，支持可视化编排：
```bash
# 启动 Dify 核心服务
docker-compose up -d urgs-dify-api urgs-dify-web urgs-dify-worker
```
访问 `http://localhost:5001` 进行初始化。

---

## ⚙️ 环境配置

本地启动和非 Docker 部署统一使用 `deploy/templates/` 下的环境配置文件，不再依赖根目录 Docker `.env`。

### 本地启动

`start.sh` 默认读取：

```text
deploy/templates/deploy.local.env
```

启动时执行：

```bash
./start.sh
```

也可以显式选择环境：

```bash
./start.sh local
./start.sh sit
./start.sh pre
./start.sh prod
```

如果需要临时指定配置文件：

```bash
START_ENV_FILE=/path/to/deploy.local.env ./start.sh
```

### 生产环境部署

生产、准生产、测试环境的非 Docker 打包入口在 `deploy/` 目录：

```bash
deploy/package-services.sh --env sit full
deploy/package-services.sh --env pre full
deploy/package-services.sh --env prod full
```

部署包会把对应模板复制为包内 `config/deploy.env`：

```text
deploy/templates/deploy.sit.env
deploy/templates/deploy.pre.env
deploy/templates/deploy.prod.env
```

详细说明见 `deploy/README.md`。

---

## ⚡ 性能与运维 (Advanced OPS)

### SQL 血缘引擎线程报错 (EPERM)
如果在生产环境运行 `sql-lineage-engine` 遇到线程启动失败，通常由于高版本 JDK 的 `clone3` 调用受限。
- **配置方案**: Docker 运行时增加 `--security-opt seccomp=unconfined`，或 K8s 设置 `seccompProfile.type: Unconfined`。
- **镜像方案**: 建议基础镜像降级至 `Debian bullseye` 并配合 `OpenJDK 8/17` 使用。
- **资源限制**: 必须调优 `pids-limit`（建议 8192+）。

## 🤝 参与贡献

1.  Fork 本仓库
2.  新建 Feat_xxx 分支
3.  提交代码
4.  新建 Pull Request


## 📄 许可证

[MIT](LICENSE)
