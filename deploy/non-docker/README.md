# URGS 非 Docker 部署打包

这个目录提供一套按服务名打包的非 Docker 部署方式。构建机执行打包脚本后，会生成一个 `tar.gz`；生产机解压后修改 `config/deploy.env`，再执行 `bin/deploy.sh install` 和 `bin/deploy.sh start`。

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

## 构建打包

在项目根目录执行：

```bash
deploy/non-docker/package-services.sh api web executor rag
```

应用和依赖组件一起打包：

```bash
deploy/non-docker/package-services.sh api web executor rag nginx redis
```

完整应用包：

```bash
deploy/non-docker/package-services.sh full
```

只打包部分服务：

```bash
deploy/non-docker/package-services.sh api web
deploy/non-docker/package-services.sh api executor
deploy/non-docker/package-services.sh rag lineage
```

如果要把 Redis / Nginx 的离线安装包也放进产物，可以指定本机已有 tar 包：

```bash
REDIS_TARBALL=/path/to/redis-linux-x86_64.tar.gz \
NGINX_TARBALL=/path/to/nginx-linux-x86_64.tar.gz \
deploy/non-docker/package-services.sh api web executor rag nginx redis
```

默认输出到：

```text
dist-packages/urgs-nondocker-<时间戳>.tar.gz
```

也可以指定输出目录和包名：

```bash
OUT_DIR=/tmp/urgs-packages PACKAGE_NAME=urgs-prod-20260514 deploy/non-docker/package-services.sh api web executor rag
```

## 生产机部署

上传并解压：

```bash
tar -xzf urgs-nondocker-<时间戳>.tar.gz
cd urgs-nondocker-<时间戳>
```

先修改配置：

```bash
vi config/deploy.env
```

重点配置：

- `DB_HOST` / `DB_PORT` / `DB_NAME` / `DB_USER` / `DB_PASSWORD`
- `NEO4J_HOST` / `NEO4J_PORT_BOLT` / `NEO4J_USER` / `NEO4J_PASSWORD`
- `WEB_WS_URL`
- `NGINX_CONF_DIR`

安装依赖并写入 Nginx 配置：

```bash
bin/deploy.sh install
```

启动服务：

```bash
bin/deploy.sh start
```

查看状态：

```bash
bin/deploy.sh status
```

停止或重启：

```bash
bin/deploy.sh stop
bin/deploy.sh restart
```

## 生产机前置要求

- JDK 17+
- Python 3.10+
- Nginx
- Redis，或打包时通过 `REDIS_TARBALL` 放入可执行包
- MySQL 8.0+，作为外部数据库，不放入应用部署包
- Neo4j 5.x，作为外部图数据库，不放入应用部署包

`rag` 和 `lineage` 第一次安装会根据 `requirements.txt` 安装 Python 依赖。生产机无法联网时，需要提前准备内网 pip 源，或先在构建机扩展成离线 wheelhouse。

Redis 被选中时，`bin/deploy.sh start` 会优先使用随包 `components/redis/` 中的 `redis-server`，找不到时使用生产机 PATH 里的 `redis-server`。

## Nginx 说明

`bin/deploy.sh install` 会根据 `config/nginx.conf.template` 渲染配置。如果 `NGINX_ENABLED=1` 且 `NGINX_CONF_DIR` 存在，会写入：

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
- Nginx 默认按系统服务集成；如果要连二进制一起交付，需要按目标服务器架构准备 `NGINX_TARBALL`。
