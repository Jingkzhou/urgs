# URGS 非 Docker 部署

本文只保留打包和部署的必要步骤。默认推荐使用固定运行目录：

```bash
URGS_DEPLOY_HOME=/home/urgs/urgs-app bin/deploy.sh up
```

`URGS_DEPLOY_HOME` 是服务器上的固定运行目录。每次上传的新包只是安装源，脚本会把包里的服务、组件和配置同步到固定运行目录后启动。

固定运行目录部署默认会用包内 `config/deploy.env` 覆盖运行目录里的现有配置。投产配置已经固化在 `deploy/templates/deploy.<env>.env` 时，直接执行上面的命令即可。

## 1. 打包前检查配置

按环境修改对应模板：

```text
deploy/templates/deploy.sit.env
deploy/templates/deploy.pre.env
deploy/templates/deploy.prod.env
```

打包时脚本会把选中的模板复制为包内：

```text
config/deploy.env
```

重点检查这些配置：

- 数据库：`DB_HOST` / `DB_PORT` / `DB_NAME` / `DB_USER` / `DB_PASSWORD`
- Neo4j：`NEO4J_HOST` / `NEO4J_PORT_BOLT` / `NEO4J_USER` / `NEO4J_PASSWORD`
- SSO 私钥：`URGS_INBOUND_SSO_RSA_PRIVATE_KEY`
- RAG/LLM：`LLM_API_BASE` / `LLM_MODEL` / `LLM_API_KEY`
- 端口：`API_PORT` / `EXECUTOR_PORT` / `RAG_PORT` / `AGENT_PORT` / `WEB_LISTEN_PORT`
- Agent Runtime：`AGENT_DATABASE_URL` / `AGENT_CHECKPOINT_DATABASE_URL` / `AGENT_REDIS_URL` / `AGENT_OPENAI_BASE_URL`
- Nginx 代理：`API_TARGET` / `API_UPSTREAM_SERVERS` / `RAG_TARGET` / `IM_API_TARGET`
- JVM：`API_JAVA_OPTS` / `EXECUTOR_JAVA_OPTS`
- 性能监控：`MONITOR_SSH_KNOWN_HOSTS` / `MONITOR_COLLECT_INTERVAL_MS` / `MONITOR_SLOW_SQL_INTERVAL_MS`

服务器性能监控启用严格 SSH 主机密钥校验。部署前应把资产服务器公钥加入
`MONITOR_SSH_KNOWN_HOSTS` 指向的文件；监控进程不会自动信任未知主机。MySQL 慢 SQL
监控账号还需要读取 `performance_schema.events_statements_summary_by_digest` 的权限。

API 与 Executor 之间的 `/api/internal/**` 接口使用共享令牌鉴权。默认情况下部署脚本会首次启动时生成
`config/internal-api.token`（权限为 `600`）并在单服务重启时复用；如需由密钥管理系统托管，可显式设置
`URGS_INTERNAL_API_TOKEN` 覆盖该文件。

## 2. 准备 Nginx / Redis / ONLYOFFICE 组件包

如果部署包要自带 Nginx 和 Redis，先生成组件包：

```bash
deploy/build-arm64-components.sh
```

生成位置：

```text
deploy/components-cache/nginx-linux-aarch64-<版本>.tar.gz
deploy/components-cache/redis-linux-aarch64-<版本>.tar.gz
```

`deploy/package-services.sh` 会自动选择 `deploy/components-cache/` 下最新的对应组件包。

ONLYOFFICE 使用官方 Linux ARM64 DEB，缓存路径如下：

```text
deploy/components-cache/onlyoffice-documentserver_<版本>_arm64.deb
```

下载或更新官方包：

```bash
deploy/download-onlyoffice.sh
# 或指定版本
deploy/download-onlyoffice.sh 9.4.0
```

完整包会自动包含该文件。目标服务器必须是 Debian/Ubuntu ARM64，并需要 root 或 sudo 权限安装系统依赖。安装过程不使用 Docker。

## 3. 打包

生产环境完整包：

```bash
DEPLOY_ENV=prod PACKAGE_NAME=urgs-prod deploy/package-services.sh full
```

测试环境完整包：

```bash
DEPLOY_ENV=sit PACKAGE_NAME=urgs-sit deploy/package-services.sh full
```

准生产环境完整包：

```bash
DEPLOY_ENV=pre PACKAGE_NAME=urgs-pre deploy/package-services.sh full
```

输出文件：

```text
dist-packages/<PACKAGE_NAME>.tar.gz
```

如果不指定 `PACKAGE_NAME`，默认输出：

```text
dist-packages/urgs-<环境>-<时间戳>.tar.gz
```

常用服务组合：

```bash
# 完整包：api web executor rag agent lineage nginx redis onlyoffice
DEPLOY_ENV=prod deploy/package-services.sh full

# 只打应用，不带 nginx / redis
DEPLOY_ENV=prod deploy/package-services.sh api web executor rag agent lineage

# 只升级 api 和 web
DEPLOY_ENV=prod PACKAGE_NAME=urgs-api-web deploy/package-services.sh api web nginx

# 只补充在线文档组件
DEPLOY_ENV=prod PACKAGE_NAME=urgs-onlyoffice deploy/package-services.sh onlyoffice

# 升级 api、web，并随包带上在线文档组件
DEPLOY_ENV=prod PACKAGE_NAME=urgs-api-web-onlyoffice deploy/package-services.sh api web nginx onlyoffice
```

如果服务器已经安装好 Nginx / Redis，不想把组件打进包：

```bash
DEPLOY_ENV=prod ALLOW_HOST_COMPONENTS=1 deploy/package-services.sh api web nginx redis
```

## 4. 上传并解压

把包上传到服务器后执行：

```bash
tar -xzf urgs-prod.tar.gz
cd urgs-prod
```

如果包名带时间戳，解压目录就是对应的包名。

## 5. 部署执行

推荐使用固定运行目录：

```bash
URGS_DEPLOY_HOME=/home/urgs/urgs-app bin/deploy.sh up
```

这条命令会：

- 把当前包里的脚本、配置、服务和组件同步到 `/home/urgs/urgs-app`
- 用包内 `config/deploy.env` 覆盖 `/home/urgs/urgs-app/config/deploy.env`
- 备份被覆盖的旧文件到 `/home/urgs/urgs-app/backups/<时间戳>/`
- 停止并启动当前包内包含的服务

以后升级仍然进入新解压目录执行同一条命令：

```bash
cd <新解压目录>
URGS_DEPLOY_HOME=/home/urgs/urgs-app bin/deploy.sh up
```

如果本次必须保留服务器现有配置，不覆盖 `config/deploy.env`：

```bash
URGS_DEPLOY_HOME=/home/urgs/urgs-app URGS_DEPLOY_ENV_KEEP=1 bin/deploy.sh up
```

此时包内配置会保存为：

```text
/home/urgs/urgs-app/config/deploy.env.package
```

## 6. 常用运维命令

进入固定运行目录：

```bash
cd /home/urgs/urgs-app
```

查看状态：

```bash
bin/deploy.sh status
```

重启全部当前启用服务：

```bash
bin/deploy.sh restart
```

只重启单个服务：

```bash
bin/deploy.sh restart api
bin/deploy.sh restart nginx
bin/deploy.sh restart executor
bin/deploy.sh restart rag
bin/deploy.sh restart agent
bin/deploy.sh restart redis
bin/deploy.sh restart onlyoffice
```

停止服务：

```bash
bin/deploy.sh stop
```

查看 Nginx 渲染结果：

```bash
bin/deploy.sh nginx-config
```

## 7. 日志和目录

固定运行目录：

```text
/home/urgs/urgs-app
```

主要目录：

```text
/home/urgs/urgs-app/config/deploy.env
/home/urgs/urgs-app/config/internal-api.token
/home/urgs/urgs-app/logs/
/home/urgs/urgs-app/pids/
/home/urgs/urgs-app/services/
/home/urgs/urgs-app/components/
/home/urgs/urgs-app/backups/
```

常看日志：

```text
logs/api.log
logs/executor.log
logs/rag.log
logs/agent-api.log
logs/agent-worker.log
logs/nginx/error.log
logs/nginx/access.log
logs/java/urgs-api-prod.log
logs/java/urgs-executor-prod.log
```

默认日志策略：

- Java 服务使用 `logs/java/` 下的 logback 滚动日志，按 `LOG_MAX_FILE_SIZE` 切分，历史保留 `LOG_RETENTION_DAYS` 天，总量受 `LOG_TOTAL_SIZE_CAP` 控制。
- `api.log`、`executor.log`、`rag.log`、`agent-*.log` 和 nginx 日志用于进程 stdout/stderr，启动前超过 `SERVICE_LOG_MAX_SIZE_MB` 会归档到 `logs/**/archive/`。
- `LOG_CLEAN_ON_START=1` 时，启动服务会清理 `logs/` 下超过 `LOG_RETENTION_DAYS` 的归档日志。
- prod 默认 `LOG_LEVEL_ROOT/SPRING_WEB/APP=ERROR`；sit 默认 `ROOT=INFO`、`SPRING_WEB=WARN`、`APP=INFO`。

## 8. 补充说明

- `full` 包含：`api web executor rag agent lineage nginx redis onlyoffice`。
- `lineage` 是随包分发的命令行工具，不是常驻服务。
- `onlyoffice` 使用官方 ARM64 DEB 安装为 Linux 系统服务，首次执行 `bin/deploy.sh install/up` 需要 sudo 权限并安装 PostgreSQL、RabbitMQ、字体、Nginx 等系统依赖。
- MySQL 和 Neo4j 不放入部署包，只通过 `config/deploy.env` 配置连接。
- 默认 `WEB_LISTEN_PORT=18080`，普通用户可直接监听；如果要使用 80 端口，建议由系统 Nginx、负载均衡或端口转发处理。
- 默认 `NGINX_USE_SYSTEM=0`，使用包内 Nginx 或 PATH 中的 Nginx，并读取本地渲染配置。
- 修改 `config/deploy.env` 后需要执行 `bin/deploy.sh restart` 才会生效。
