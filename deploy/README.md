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

### 1. 固化投产环境配置

打包前先确认目标投产环境对应的配置文件已经写好：

```text
deploy/templates/deploy.sit.env
deploy/templates/deploy.pre.env
deploy/templates/deploy.prod.env
```

打包时通过 `DEPLOY_ENV` 或 `--env` 选择配置。脚本会把对应模板复制进部署包的 `config/deploy.env`：

```bash
DEPLOY_ENV=prod deploy/package-services.sh full
deploy/package-services.sh --env pre full
deploy/package-services.sh --env sit api web nginx redis
```

如果不指定 `DEPLOY_ENV` / `--env`，脚本仍会沿用 `deploy/templates/deploy.env`，用于兼容旧的单配置打包方式。

必须确认的关键项：

- `DB_HOST` / `DB_PORT` / `DB_NAME` / `DB_USER` / `DB_PASSWORD`
- `NEO4J_HOST` / `NEO4J_PORT_BOLT` / `NEO4J_USER` / `NEO4J_PASSWORD`
- `LLM_API_BASE` / `LLM_MODEL` / `LLM_API_KEY`
- `WEB_LISTEN_PORT`
- `PUBLIC_HOST` / `WEB_WS_URL`
- `API_TARGET` / `API_UPSTREAM_SERVERS` / `API_UPSTREAM_STICKY` / `RAG_TARGET` / `IM_API_TARGET`
- `API_JAVA_OPTS` / `EXECUTOR_JAVA_OPTS`
- `NGINX_ENABLED=1`
- `NGINX_USE_SYSTEM=0`

默认 `NGINX_USE_SYSTEM=0` 表示使用包内本地 Nginx 配置，不依赖 `/etc/nginx/conf.d`。

默认 `WEB_LISTEN_PORT=18080`，普通 `appuser` 可以直接启动。Linux 普通用户不能监听 80 端口；如果必须使用 80，请由运维在系统层做端口转发、负载均衡映射，或改用系统 Nginx/root 权限管理。

默认 `WEB_WS_URL` 留空，前端会按浏览器当前访问地址自动生成 `ws://<host>:<port>/ws/im`，避免换端口后还写死 `127.0.0.1`。

默认 `API_TARGET` / `RAG_TARGET` 留空，Nginx 会反代到本机 `API_PORT` / `RAG_PORT`。如果 Web/Nginx 和后端不在同一台服务器，打包前可以写成 `API_TARGET=http://<API服务器IP>:8080`、`RAG_TARGET=http://<RAG服务器IP>:8001`。

如果普通 API 需要代理到两台后端服务器，可以填写 `API_UPSTREAM_SERVERS=<API服务器1IP>:8080,<API服务器2IP>:8080`。这个配置只写 `IP:端口`，不要带 `http://`。填写后，Nginx 会自动生成 upstream，普通 `/api`、`/uploads`、`/profile` 和普通 `/ws/` 会走该 upstream。

当前登录 token 保存在单个 API 进程内存中，不是 Redis/JWT 共享。因此多 API 节点必须保持 `API_UPSTREAM_STICKY=ip_hash`，保证同一个客户端登录和后续权限校验落到同一台 API。否则登录成功后，权限校验请求可能被轮询到另一台 API，返回 401 后前端会跳回登录页。

默认 `IM_API_TARGET` 留空时跟随 `API_TARGET`。如果有两台 API 服务器但 WebSocket 不做共享会话，建议把 `IM_API_TARGET` 固定到其中一台，例如 `IM_API_TARGET=http://<IM服务器IP>:8080`，Nginx 会自动把 `/ws/im` 和 `/api/im` 路由到这台机器。

### 2. 准备 Nginx / Redis 离线包

当前生产服务器为 Linux ARM64 / `aarch64`（Kunpeng 920）。如果生产机不再手工安装组件，先在构建机生成 ARM64 的 Nginx 和 Redis 组件包：

```bash
deploy/build-arm64-components.sh
```

生成结果默认在：

```text
deploy/components-cache/nginx-linux-aarch64-<版本>.tar.gz
deploy/components-cache/redis-linux-aarch64-<版本>.tar.gz
```

`package-services.sh` 会自动使用 `components-cache/` 里的最新 ARM64 组件包。这样可以把问题前移到打包阶段，避免到生产机才发现缺运行组件。

### 3. 执行完整生产打包

在项目根目录执行：

```bash
DEPLOY_ENV=prod PACKAGE_NAME=urgs-prod \
deploy/package-services.sh full
```

默认输出：

```text
dist-packages/urgs-prod.tar.gz
```

打包完成后默认只保留 `.tar.gz` 文件，不保留展开的临时目录。如果需要保留临时目录用于检查内容，可以加：

```bash
KEEP_WORK_DIR=1
```

如果不指定 `PACKAGE_NAME`，默认输出：

```text
dist-packages/urgs-prod-<时间戳>.tar.gz
```

默认包名格式为 `urgs-<环境>-<时间戳>.tar.gz`。例如 `--env pre` 会输出 `urgs-pre-<时间戳>.tar.gz`，`--env sit` 会输出 `urgs-sit-<时间戳>.tar.gz`。

### 4. 可选打包方式

按准生产环境打包：

```bash
PACKAGE_NAME=urgs-pre deploy/package-services.sh --env pre full
```

按测试环境打包：

```bash
PACKAGE_NAME=urgs-sit deploy/package-services.sh --env sit full
```

只打包应用，不打 Nginx / Redis：

```bash
DEPLOY_ENV=prod deploy/package-services.sh api web executor rag
```

应用和依赖组件一起打包：

```bash
DEPLOY_ENV=prod deploy/package-services.sh api web executor rag nginx redis
```

如果本机没有完整 `urgs-web/node_modules`，但已有 `urgs-web/dist`，脚本默认复用现有前端产物，避免卡在 `npm ci`。需要强制重新安装依赖并重建前端时执行：

```bash
DEPLOY_ENV=prod WEB_REUSE_DIST_IF_NO_NODE_MODULES=0 deploy/package-services.sh api web executor nginx redis
```

完整应用包：

```bash
DEPLOY_ENV=prod deploy/package-services.sh full
```

只打包部分服务：

```bash
DEPLOY_ENV=prod deploy/package-services.sh api web
DEPLOY_ENV=prod deploy/package-services.sh api executor
DEPLOY_ENV=prod deploy/package-services.sh rag lineage
```

选择 `nginx` / `redis` 组件时，默认要求提供对应 tar 包，这样生产机解压后不需要再补安装运行组件。如果你明确要复用生产机已经安装的 Nginx / Redis，可以设置：

```bash
DEPLOY_ENV=prod ALLOW_HOST_COMPONENTS=1 deploy/package-services.sh api web nginx redis
```

也可以指定输出目录和包名：

```bash
DEPLOY_ENV=prod OUT_DIR=/tmp/urgs-packages PACKAGE_NAME=urgs-prod-20260514 deploy/package-services.sh api web executor rag
```

## 生产机部署

### 1. 上传并解压

把构建机生成的 `tar.gz` 上传到生产机，然后执行：

```bash
tar -xzf urgs-prod.tar.gz
cd urgs-prod
```

如果使用默认时间戳包名，则目录名是 `urgs-<环境>-<时间戳>`。

### 2. 推荐：固定运行目录部署

生产机建议只维护一个固定运行目录，例如：

```bash
export URGS_DEPLOY_HOME=/home/appuser/urgs-app
```

`URGS_DEPLOY_HOME` 只放应用运行文件、日志、pid、备份和组件；`DATA_ROOT` 仍用于上传文件、Redis 数据、RAG 文档库等业务数据，默认可以继续保持 `/data/urgs`。

这样每个解压出来的包都只是安装源，真正运行的 JAR、前端静态文件、组件、日志和 pid 都固定在 `/home/appuser/urgs-app`。部分升级时，本包包含什么服务就只替换并重启什么服务，其他服务继续沿用固定运行目录中的旧版本，不会出现 `executor` 从包 1 启动、`api` 从包 3 启动后难以追踪的问题。

第一次迁移到固定运行目录时，建议用一次完整包，让所有服务都进入同一个运行根目录：

```bash
tar -xzf urgs-prod.tar.gz
cd urgs-prod
URGS_DEPLOY_HOME=/home/appuser/urgs-app bin/deploy.sh up
```

后续只升级 API 和 Web：

```bash
tar -xzf urgs-api-web.tar.gz
cd urgs-api-web
URGS_DEPLOY_HOME=/home/appuser/urgs-app bin/deploy.sh up
```

这次只会同步并重启当前包里的服务，例如 `api web nginx`，不会重启未打入本包的 `executor` / `redis`。

固定运行目录模式默认会先备份本次即将被覆盖的旧版本，再部署新版本。备份目录为：

```text
/home/appuser/urgs-app/backups/<时间戳>/
```

例如 `api web nginx` 增量包会备份：

```text
/home/appuser/urgs-app/backups/<时间戳>/services/api
/home/appuser/urgs-app/backups/<时间戳>/services/web
/home/appuser/urgs-app/backups/<时间戳>/components/nginx
```

没有包含在本包里的 `executor` / `redis` 不会被覆盖，也不会被重启。需要指定备份名时可以设置：

```bash
BACKUP_NAME=before-api-web-20260529 URGS_DEPLOY_HOME=/home/appuser/urgs-app bin/deploy.sh up
```

如果确认不需要备份，可以关闭：

```bash
BACKUP_BEFORE_DEPLOY=0 URGS_DEPLOY_HOME=/home/appuser/urgs-app bin/deploy.sh up
```

需要手工回退时，把备份目录中的对应服务复制回固定运行目录，然后只重启对应服务：

```bash
cd /home/appuser/urgs-app
cp -a backups/<时间戳>/services/api services/api
bin/deploy.sh restart api
```

查看全局运行状态时，进入固定运行目录执行：

```bash
cd /home/appuser/urgs-app
bin/deploy.sh status
```

固定运行目录部署默认会用包内 `config/deploy.env` 覆盖 `/home/appuser/urgs-app/config/deploy.env`，适合按 `deploy.sit.env` / `deploy.pre.env` / `deploy.prod.env` 固化配置后投产。覆盖前会先备份旧配置。

如果生产机本地临时改过配置，并且本次部署明确要保留现场配置，可以执行：

```bash
URGS_DEPLOY_HOME=/home/appuser/urgs-app URGS_DEPLOY_ENV_KEEP=1 bin/deploy.sh up
```

此时包内配置会另存为 `config/deploy.env.package`，不会覆盖当前运行配置。

### 3. 兼容：在解压目录内运行

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

这种方式会把当前解压目录作为运行目录。它适合临时测试；生产长期运行不推荐用这种方式混合部署多个包。

### 4. 查看运行状态

```bash
bin/deploy.sh status
```

### 5. 停止或重启

```bash
bin/deploy.sh stop
bin/deploy.sh restart
```

### 6. 仅在排错时拆开执行

正常生产部署只执行 `bin/deploy.sh up`。如果需要排查，可以拆成：

```bash
bin/deploy.sh install
bin/deploy.sh start
```

### 7. deploy.sh 命令说明

`bin/deploy.sh` 会按 `config/services.list` 中的服务清单执行动作。不同包的服务清单不同，例如 `api web nginx` 包不会启动 `executor` / `redis`，`api web executor nginx redis` 包会启动这些服务。

| 命令 | 作用 | 典型使用场景 |
| --- | --- | --- |
| `bin/deploy.sh install` | 只做安装准备，不启动服务。创建运行目录、解压随包 Nginx / Redis、创建 Python venv、渲染 Nginx 配置。 | 第一次部署前分步排查环境。 |
| `bin/deploy.sh start` | 只启动 `services.list` 中启用的服务，不重新做安装准备。 | 已经执行过 `install`，只需要启动服务。 |
| `bin/deploy.sh up` | 先停止本包 `services.list` 中启用的服务，再执行 `install` 和 `start`。 | 第一次部署和发布新包时推荐使用，确保新 JAR、配置和 Nginx 渲染结果生效。 |
| `bin/deploy.sh stop` | 停止 `services.list` 中启用的服务。 | 停机维护。 |
| `bin/deploy.sh restart` | 停止再启动全部启用服务，不重新执行 `install`。 | 修改 `config/deploy.env` 后重启生效。 |
| `bin/deploy.sh status` | 查看全部启用服务状态。 | 检查 API / Nginx / Redis / executor 是否运行。 |
| `bin/deploy.sh nginx-config` | 将渲染后的 Nginx 配置打印到终端，不写文件、不启动。 | 检查 `API_UPSTREAM_SERVERS` / `IM_API_TARGET` / `RAG_TARGET` 渲染结果。 |

支持对单个服务执行 `start` / `stop` / `restart` / `status`：

```bash
bin/deploy.sh restart api
bin/deploy.sh restart nginx
bin/deploy.sh restart executor
bin/deploy.sh restart redis
bin/deploy.sh status api
```

常见操作建议：

- 第一次部署或上传新包后：`bin/deploy.sh up`
- 只修改数据库、端口、JDBC 参数等 `config/deploy.env` 配置后：`bin/deploy.sh restart`
- 只修 API 配置后：`bin/deploy.sh restart api`
- 只调整 Nginx 代理、上游节点或 WebSocket 固定节点后：`bin/deploy.sh restart nginx`
- 排查 502 时：先执行 `bin/deploy.sh status`，再查看 `logs/api.log` 和 `logs/nginx/error.log`

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

随包本地 Nginx 默认监听 `18080`，部署后访问：

```text
http://<服务器IP>:18080/
```

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
- 生产端零调整部署要求打包前写好对应环境的 `deploy/templates/deploy.<sit|pre|prod>.env`，并提供目标服务器架构匹配的 `NGINX_TARBALL` / `REDIS_TARBALL`。
- 旧包不会自动包含脚本和配置变更；部署前需要重新打包并上传新生成的 `tar.gz`。
