# URGS 非 Docker 部署打包

这个目录提供一套按服务名打包的非 Docker 部署方式。推荐流程是：构建机先把生产配置写入模板，再把应用、Nginx、Redis 一起打进 `tar.gz`；生产机只需要解压并执行 `bin/deploy.sh up`，不再手工调整配置。

## 支持的服务名

| 服务名 | 内容 | 运行方式 |
| --- | --- | --- |
| `api` | `urgs-api` Spring Boot JAR | `java -jar` |
| `web` | `urgs-web` Vite 静态产物 | Nginx |
| `executor` | `urgs-executor` Spring Boot JAR | `java -jar` |
| `rag` | `urgs-rag` Python 服务 | venv + uvicorn |
| `lineage` | `sql-lineage-engine` 血缘解析工具 | CLI 工具，随包分发 |
| `nginx` | Nginx 配置和可选二进制包 | 系统 Nginx 或随包 Nginx |
| `redis` | Redis 配置和可选二进制包 | `redis-server` |

## 构建机打包

### 1. 固化生产配置

打包前先确认以下文件已经是目标生产环境配置：

```text
deploy/non-docker/templates/deploy.env
```

必须确认的关键项：

- `DB_HOST` / `DB_PORT` / `DB_NAME` / `DB_USER` / `DB_PASSWORD`
- `NEO4J_HOST` / `NEO4J_PORT_BOLT` / `NEO4J_USER` / `NEO4J_PASSWORD`
- `LLM_API_BASE` / `LLM_MODEL` / `LLM_API_KEY`
- `PUBLIC_HOST` / `WEB_WS_URL`
- `API_JAVA_OPTS` / `EXECUTOR_JAVA_OPTS`
- `NGINX_ENABLED=1`
- `NGINX_USE_SYSTEM=0`

默认 `NGINX_USE_SYSTEM=0` 表示使用包内本地 Nginx 配置，不依赖 `/etc/nginx/conf.d`。

### 2. 准备 Nginx / Redis 离线包

如果生产机不再手工安装组件，打包时必须提供目标服务器架构匹配的 Nginx 和 Redis tar 包，例如：

```text
/path/to/nginx-linux-x86_64.tar.gz
/path/to/redis-linux-x86_64.tar.gz
```

选择 `nginx` / `redis` 组件时，默认要求提供对应 tar 包。这样可以把问题前移到打包阶段，避免到生产机才发现缺运行组件。

### 3. 执行完整生产打包

在项目根目录执行：

```bash
NGINX_TARBALL=/path/to/nginx-linux-x86_64.tar.gz \
REDIS_TARBALL=/path/to/redis-linux-x86_64.tar.gz \
PACKAGE_NAME=urgs-prod \
deploy/non-docker/package-services.sh full
```

默认输出：

```text
dist-packages/urgs-prod.tar.gz
```

如果不指定 `PACKAGE_NAME`，默认输出：

```text
dist-packages/urgs-nondocker-<时间戳>.tar.gz
```

### 4. 可选打包方式

只打包应用，不打 Nginx / Redis：

```bash
deploy/non-docker/package-services.sh api web executor rag
```

应用和依赖组件一起打包：

```bash
NGINX_TARBALL=/path/to/nginx-linux-x86_64.tar.gz \
REDIS_TARBALL=/path/to/redis-linux-x86_64.tar.gz \
deploy/non-docker/package-services.sh api web executor rag nginx redis
```

完整应用包：

```bash
NGINX_TARBALL=/path/to/nginx-linux-x86_64.tar.gz \
REDIS_TARBALL=/path/to/redis-linux-x86_64.tar.gz \
deploy/non-docker/package-services.sh full
```

只打包部分服务：

```bash
deploy/non-docker/package-services.sh api web
deploy/non-docker/package-services.sh api executor
deploy/non-docker/package-services.sh rag lineage
```

选择 `nginx` / `redis` 组件时，默认要求提供对应 tar 包，这样生产机解压后不需要再补安装运行组件。如果你明确要复用生产机已经安装的 Nginx / Redis，可以设置：

```bash
ALLOW_HOST_COMPONENTS=1 deploy/non-docker/package-services.sh api web nginx redis
```

也可以指定输出目录和包名：

```bash
OUT_DIR=/tmp/urgs-packages PACKAGE_NAME=urgs-prod-20260514 deploy/non-docker/package-services.sh api web executor rag
```

## 生产机部署

### 1. 上传并解压

把构建机生成的 `tar.gz` 上传到生产机，然后执行：

```bash
tar -xzf urgs-prod.tar.gz
cd urgs-prod
```

如果使用默认时间戳包名，则目录名是 `urgs-nondocker-<时间戳>`。

### 2. 一键安装并启动

```bash
bin/deploy.sh up
```

`up` 会连续执行：

- 初始化运行目录
- 解压随包 Nginx / Redis 组件
- 渲染前端运行时配置
- 渲染本地 Nginx 配置
- 启动 Redis
- 启动 RAG / executor / API
- 启动 Nginx

### 3. 查看运行状态

```bash
bin/deploy.sh status
```

### 4. 停止或重启

```bash
bin/deploy.sh stop
bin/deploy.sh restart
```

### 5. 仅在排错时拆开执行

正常生产部署只执行 `bin/deploy.sh up`。如果需要排查，可以拆成：

```bash
bin/deploy.sh install
bin/deploy.sh start
```

## 生产机前置要求

- JDK 17+
- Python 3.10+
- Nginx，已通过 `NGINX_TARBALL` 打进包时不需要生产机预装
- Redis，已通过 `REDIS_TARBALL` 打进包时不需要生产机预装
- MySQL 8.0+，作为外部数据库，不放入应用部署包
- Neo4j 5.x，作为外部图数据库，不放入应用部署包

`rag` 和 `lineage` 第一次安装会根据 `requirements.txt` 安装 Python 依赖。生产机无法联网时，需要提前准备内网 pip 源，或先在构建机扩展成离线 wheelhouse。

Redis 被选中时，`bin/deploy.sh start` 会优先使用随包 `components/redis/` 中的 `redis-server`，找不到时才使用生产机 PATH 里的 `redis-server`。

## Nginx 说明

`bin/deploy.sh install` 会根据 `config/nginx.conf.template` 渲染配置。默认 `NGINX_USE_SYSTEM=0`，脚本会生成本地完整配置：

```text
config/nginx.local.conf
```

`bin/deploy.sh start` 会优先使用随包 `components/nginx/` 中的 `nginx`，找不到时使用生产机 PATH 里的 `nginx`，并以本地配置启动，不需要手工创建 `/etc/nginx/conf.d`。

如果设置 `NGINX_USE_SYSTEM=1` 且 `NGINX_CONF_DIR` 存在，会写入：

```text
<NGINX_CONF_DIR>/urgs.conf
```

并尝试执行 `nginx -t` 和 reload。

如果 Nginx 由运维统一管理，可以设置：

```bash
NGINX_ENABLED=0
```

然后查看渲染结果，手工合并：

```bash
bin/deploy.sh nginx-config
```

## 注意

- `web` 静态文件需要 Nginx 代理 `/api`、`/ws`、`/uploads`、`/profile`、`/api/rag`，不要只用普通静态文件服务器上线。
- `lineage` 当前作为工具目录随包分发，不作为常驻服务启动。
- MySQL、Neo4j 不放入部署包，只在 `config/deploy.env` 中配置连接地址。
- 生产端零调整部署要求打包前写好 `deploy/non-docker/templates/deploy.env`，并提供目标服务器架构匹配的 `NGINX_TARBALL` / `REDIS_TARBALL`。
- 旧包不会自动包含脚本和配置变更；部署前需要重新打包并上传新生成的 `tar.gz`。
