# db_deploy — 数据库版本一键部署引擎

`db_deploy` 是配套 URGS 系统的离线部署引擎。读取 URGS 生成的 ZIP 版本包，
自动验证完整性，并按 `manifest.json` 中定义的计划顺序执行数据库变更。

---

## 一、部署包目录结构

从 URGS 下载的 `.zip` 包解压后，完整结构如下：

```text
<版本号>.zip (解压后)
├── manifest.json              # [核心] 部署执行计划、回滚计划、数据库连接配置
├── checksum.sha256            # [安全] 所有文件的 SHA-256 校验码
│
├── sql/                       # DDL/DML 变更脚本（按文件名升序执行）
├── procedures/                # 当前版本存储过程脚本
├── prev_procedures/           # 上一版本存储过程（用于部署前一致性校验）
├── production_procedure_backup/ # 执行 deploy 时导出的生产存储过程备份
├── backup/                    # 部署前执行的备份脚本
├── rollback/                  # 回滚脚本（回退时执行）
│
└── bin/
    └── db_deploy/             # Python 部署引擎（本工具）
        ├── README.md          # 本文件
        ├── INSTALL_GUIDE.md   # 详细安装与规格手册
        ├── __init__.py
        ├── connections.template.json   # 外部连接配置模板
        ├── cli/
        │   └── main.py        # 命令行入口
        ├── connectors/
        │   ├── __init__.py
        │   └── factory.py     # 数据库连接工厂（Oracle / MySQL / GBase / JDBC）
        ├── core/
        │   ├── __init__.py
        │   ├── engine.py      # 部署引擎核心（check / deploy / rollback）
        │   └── steps.py       # 步骤处理器
        └── logger/
            └── deploy_logger.py   # 双轨日志（可读日志 + JSONL 结构化流）
```

---

## 二、环境要求

- **Python**: 3.8+
- **数据库驱动**

**离线/内网环境（推荐）：** 部署包已根据数据库类型内置对应驱动，直接执行：

```bash
bash bin/db_deploy/install_deps.sh
```

URGS 后端打包时默认从 `classpath:db_deploy` 读取工具与驱动。生产环境可配置
`DEPLOY_TOOL_WORKDIR=/data/urgs/db_deploy`，然后将驱动上传到
`/data/urgs/db_deploy/drivers/<dbType>/`，避免每次新增驱动都重打后端包。

**在线环境（有外网）：**

```bash
pip3 install cx_Oracle          # Oracle（需额外安装 Oracle Instant Client）
pip3 install pymysql            # MySQL / GBase
pip3 install JayDeBeApi JPype1  # 星环/Transwarp 等 JDBC 平台
```

---

## 三、连接配置

引擎按以下优先级加载数据库连接配置：

| 优先级 | 来源 | 说明 |
|--------|------|------|
| 1（最高）| `manifest.json` 内嵌 `connections` | URGS 打包时自动写入，**推荐使用** |
| 2 | `--conn-config` 参数指定的文件路径 | 手动指定外部配置 |
| 3（兜底）| `~/.db_deploy/connections.json` | 执行机本地默认配置 |

若使用外部配置文件，参考 `connections.template.json` 格式：

```json
{
  "prod_db": {
    "type": "oracle",
    "user": "irs_datacore",
    "password": "your_password",
    "dsn": "192.168.1.10:1521/ORCL"
  }
}
```

星环/Transwarp 等 JDBC 平台示例：

```json
{
  "prod_db": {
    "type": "xinghuan",
    "user": "prod_user",
    "password": "your_password",
    "jdbc_url": "jdbc:inceptor2://10.10.1.30:10000/business_prod",
    "driver_class": "org.apache.hive.jdbc.HiveDriver",
    "driver_jar": "bin/db_deploy/drivers/xinghuan/inceptor-sdk-studio-1.2.jar",
    "schema": "business_prod"
  }
}
```

---

## 四、使用方法

所有命令在**解压目录内**执行，`--pkg .` 表示当前目录即为部署包根目录。

### 4.1 校验包完整性（不执行 SQL）

```bash
python3 -m bin.db_deploy.cli.main check --pkg .
```

校验内容：
- SHA-256 完整性（`checksum.sha256`）
- `manifest.json` 存在性与格式

### 4.2 正式部署

```bash
python3 -m bin.db_deploy.cli.main deploy --pkg . --operator 张三
```

按 `manifest.json` 中 `execution_plan` 的 step 顺序依次执行：
1. 生产存储过程对比。
2. 执行 `backup/` 目录 SQL。
3. 执行 `sql/` 目录 SQL。
4. 部署 `procedures/` 目录存储过程。

**断点续跑**（部署中断后，修复问题再继续）：

```bash
python3 -m bin.db_deploy.cli.main deploy --pkg . --operator 张三 --resume
```

### 4.3 执行回滚

```bash
python3 -m bin.db_deploy.cli.main rollback --pkg . --operator 张三
```

按 `manifest.json` 中 `rollback_plan` 顺序执行：
1. 执行 `rollback/` 目录 SQL。
2. 恢复 `production_procedure_backup/` 中的生产执行前存储过程。

### 4.4 查看部署状态

```bash
python3 -m bin.db_deploy.cli.main status --pkg .
```

### 4.5 参数说明

| 参数 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `command` | 是 | — | `check` / `deploy` / `rollback` / `status` |
| `--pkg` | 是 | — | 部署包路径（ZIP 文件或解压后目录） |
| `--operator` | 否 | `system` | 操作人名称，记录到日志 |
| `--conn-config` | 否 | — | 外部连接配置文件路径（非默认路径时使用） |
| `--resume` | 否 | `false` | 从上次失败步骤继续（仅 `deploy` 有效） |

---

## 五、manifest.json 步骤类型说明

`execution_plan` 和 `rollback_plan` 中每个 step 的 `type` 字段对应的处理器行为：

| type | 说明 |
|------|------|
| `execute_sql_ordered` | 扫描 `source_dir` 目录，按文件名**升序**执行所有 `.sql` 文件（以 `;` 分割语句） |
| `execute_sql` | 执行 `files` 列表中指定的 SQL 文件 |
| `deploy_procedures` | 部署存储过程，每个文件**整体**执行（不按 `;` 分割，自动去除 Oracle `/` 终止符） |
| `export_and_compare_procedures` | 执行部署时先从生产数据库导出存储过程到 `production_procedure_backup/`，再与 `prev_procedures/` 基线对比，不一致则**中止**部署 |
| `restore_procedure_backups` | 回滚时恢复 `production_procedure_backup/` 中的生产执行前存储过程 |
| `post_check` | 执行后置校验 SQL |

---

## 六、日志

部署执行后，在包目录的 `.meta/` 下自动生成：

| 文件 | 说明 |
|------|------|
| `deploy_YYYYMMDD_HHmmss.log` | 人类可读日志，记录每个 step 的执行详情与耗时 |
| `runtime_log.jsonl` | 结构化日志（JSONL），供 URGS 系统回传展示部署进度 |
| `summary_*.json` | 执行摘要，汇总总耗时与最终状态（success / failed / rollback_success） |

---

## 七、安全建议

- **勿修改 SQL 脚本**：修改后 `checksum.sha256` 校验将失败，部署被拒绝
- **权限收紧**：建议 `chmod 700 <解压目录>`，防止敏感 SQL 泄露
- **密码隔离**：数据库密码仅存于 `connections.json`，切勿明文写入 SQL 文件或提交到 Git
