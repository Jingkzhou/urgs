# URGS (Unified Resource Governance System)

URGS 是一个企业级统一资源治理与调度系统。它集成了任务调度、数据治理（元数据与血缘分析）、知识库检索（RAG）以及可视化的运维监控能力。

## 🏗️ 软件架构

本项目采用微服务架构，包含以下核心模块：

| 模块             | 目录                                                         | 说明                                         | 技术栈                                     |
| ---------------- | ------------------------------------------------------------ | -------------------------------------------- | ------------------------------------------ |
| **Backend API**  | [urgs-api](./urgs-api)                                       | 核心后端服务，负责业务逻辑、调度管理、Auth等 | Spring Boot 3, MyBatis-Plus, Quartz        |
| **Frontend**     | [urgs-web](./urgs-web)                                       | 现代化前端界面                               | React 18, Vite, Ant Design, Tailwind       |
| **Executor**     | [urgs-executor](./urgs-executor)                             | 独立任务执行引擎，支持分布式部署             | Spring Boot 3, ProcessBuilder              |
| **AI / RAG**     | [urgs-rag](./urgs-rag)                                       | 智能知识库与检索服务，支持 SQL 解释与问答    | Python 3.10, LangChain, ChromaDB           |
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
| **RAG 文档**     | [http://localhost:8001/doc](http://localhost:8001/doc)                         | AI 服务接口文档                |
| **Neo4j**        | [http://localhost:7474](http://localhost:7474)                                 | neo4j / 12345678               |
| **Presentation** | [http://localhost:3002](http://localhost:3002)                                 | -                              |
| **MySQL**        | `localhost:3306`                                                               | root / a8548879 (库: urgs_dev) |
| **Dify 控制台**  | [http://localhost:5001](http://localhost:5001)                                 | 首次启动需设置管理员账号       |

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

### 5. AI 应用平台 (urgs-dify)
Dify 作为子模块引入，支持可视化编排：
```bash
# 启动 Dify 核心服务
docker-compose up -d urgs-dify-api urgs-dify-web urgs-dify-worker
```
访问 `http://localhost:5001` 进行初始化。

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

### 生产环境部署（离线安装包）

如果生产服务器无法联网，可先在有网络的构建机生成离线安装包，再复制到内网服务器安装。项目根目录提供两个脚本：

| 脚本 | 用途 |
| ---- | ---- |
| `package.sh` | 打单架构离线包，默认架构是 `linux/arm64` |
| `package-dual-arch.sh` | 一次打 ARM64 和 X86_64 两套离线包 |

#### 1. 开发机/构建机：生成离线包

首次使用先赋予执行权限：

```bash
chmod +x package.sh package-dual-arch.sh
```

只打 X86_64 包：

```bash
BUILD_ARCH=linux/amd64 ./package.sh
```

输出文件示例：

```text
urgs-offline-x86_64-20260516104515.tar.gz
```

只打 ARM64 包：

```bash
BUILD_ARCH=linux/arm64 ./package.sh
```

输出文件示例：

```text
urgs-offline-aarch64-20260516104515.tar.gz
```

同时打 ARM64 和 X86_64 两套包：

```bash
./package-dual-arch.sh
```

输出文件示例：

```text
urgs-offline-aarch64-20260516104515.tar.gz
urgs-offline-x86_64-20260516104515.tar.gz
```

#### 2. 选择性打包模块

不传模块参数时，默认打包当前仓库存在的核心服务：

```text
mysql api web executor rag lineage neo4j
```

`presentation` 只有在 `urgs+-presentation-platform/` 目录存在时才会自动加入默认包。`urgs-dify/` 目录存在时，会自动加入 Dify 相关服务。

也可以显式指定模块：

```bash
# 只打前端
BUILD_ARCH=linux/amd64 ./package.sh web

# 打指定核心服务
BUILD_ARCH=linux/amd64 ./package.sh mysql api web executor rag lineage neo4j

# 双架构打指定模块
./package-dual-arch.sh mysql api web executor rag lineage neo4j
```

支持的模块名：

```text
mysql, api, web, executor, rag, lineage, neo4j, presentation,
dify-api, dify-web, dify-worker, dify-db, dify-redis, dify-nginx, dify-weaviate
```

#### 3. 包内容

脚本会生成 `urgs-dist*` 目录和对应 `.tar.gz` 压缩包，主要包含：

- `images/urgs-images.tar`：项目服务和第三方依赖镜像
- `docker/`：Docker Engine 与 Docker Compose 离线安装介质
- `docker-compose.yml`：服务编排文件
- `.env`：部署环境配置
- `install.sh`：离线安装和启动脚本
- `uninstall.sh`：停止服务脚本
- `manifest.txt`：本次打包清单

#### 4. 内网服务器：安装

把对应架构的压缩包复制到目标服务器后执行：

```bash
tar -xzf urgs-offline-x86_64-*.tar.gz
cd urgs-dist-x86_64
```

安装前按实际服务器地址修改 `.env`，重点检查数据库、端口、Neo4j 密码、LLM/RAG 地址等配置。

如果服务器尚未安装 Docker/Compose，使用 root 权限执行：

```bash
sudo ./install.sh
```

如果服务器已经安装 Docker/Compose，且当前用户有 Docker 权限，可以直接执行：

```bash
./install.sh
```

查看服务状态：

```bash
docker compose --env-file .env -f docker-compose.yml ps
docker compose --env-file .env -f docker-compose.yml logs -f urgs-api
```

停止服务：

```bash
./uninstall.sh
```

#### 5. 可选：清理本机 Docker 资源

以下命令会删除本机所有容器、镜像和构建缓存，只建议在确认不再需要当前 Docker 资源时执行：

```bash
# 1. 停掉并删除所有容器
docker rm -f $(docker ps -aq)

# 2. 删除所有镜像
docker rmi -f $(docker images -aq)

# 3. 顺手清理缓存/网络/构建残留
docker system prune -af
```

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
