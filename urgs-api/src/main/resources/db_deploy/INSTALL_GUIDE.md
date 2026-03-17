# 数据库版本安装包操作手册 (Installation & Spec Guide)

本手册详细说明了由 URGS 生成的自动化安装包结构、环境要求及具体操作流程。

## 1. 安装包目录结构

解压后的完整目录结构如下：

```text
deploy_pkg_{version}/
├── manifest.json            # [核心] 部署执行计划与元数据
├── checksum.sha256          # [安全] 完整性校验文件（SHA-256）
├── bin/                     # [工具] 内置部署引擎
│   └── db_deploy/           #   Python 部署引擎源代码
├── sql/                     # [数据] 变更脚本
│   ├── oracle/              #   按数据库类型分类
│   │   ├── ddl/             #   DDL 脚本 (建表、改表等)
│   │   └── dml/             #   DML 脚本 (数据修正等)
│   └── mysql/               
├── procedures/              # [可选] 存储过程/函数脚本
└── rollback/                # [必选] 回退脚本目录
    ├── sql/                 #   对应的逆向回滚脚本
    └── procedures/          #   存储过程备份
```

## 2. 环境准备 (Prerequisites)

执行机（生产/测试服务器）需具备以下环境：

1. **Python 环境**: Python 3.8+
2. **数据库驱动**: 
   - **Oracle**: `pip install cx_Oracle` (需安装 Oracle Instant Client)
   - **MySQL**: `pip install pymysql`
3. **连接配置**: 
   在执行机 `~/.db_deploy/connections.json` 中配置数据库连接信息（此文件不入包，由本地环境持有）。

## 3. 操作流程 (Operation Flow)

### 3.1 步骤一：上传并解压
将从 URGS 下载的 `.zip` 包上传至目标执行机并解压。

### 3.2 步骤二：完整性校验
在执行前，建议先执行校验命令，确保安装包在传输过程中未损坏。
```bash
# 进入解压目录
cd deploy_pkg_{version}

# 使用内置工具执行校验
python3 -m bin.db_deploy.cli.main check --pkg .
```

### 3.3 步骤三：执行部署
校验通过后，执行部署指令。
```bash
python3 -m bin.db_deploy.cli.main deploy --pkg . --operator your_name
```
> [!TIP]
> **断点续跑**: 若部署过程中因数据库暂时连不通等外部原因中断，修复后可增加 `--resume` 参数从中断点继续执行。

### 3.4 步骤四：执行回退 (若需)
若部署后验证不通过，可执行回退：
```bash
python3 -m bin.db_deploy.cli.main rollback --pkg . --operator your_name
```

## 4. 日志审计

部署执行过程中及其完成后，会在包内的 `.meta/` 目录下生成以下日志：
- `deploy_YYYYMMDD_HHmmss.log`: **人类可读日志**，记录详细执行步骤。
- `runtime_log.jsonl`: **结构化日志**，供 URGS 系统回传并展示进度。
- `summary_*.json`: **执行摘要**，汇总耗时与最终状态。

## 5. 配置规格 (manifest.json)

`manifest.json` 定义了引擎执行的行为。URGS 会在打包时自动生成。

| 字段 | 说明 |
|------|------|
| `pkg_version` | 版本号 |
| `execution_plan` | 执行顺序列表，定义了 step, type, targets, params |
| `rollback_plan` | 对应的回退顺序列表 |

## 6. 安全建议

- **校验和强制性**: 严禁修改安装包内的 SQL 脚本，否则校验将无法通过。
- **权限控制**: 建议将解压目录权限设为 `700`，防止敏感 SQL 泄露。
- **配置隔离**: 数据库密码应仅存于 `connections.json`，切勿明文写入脚本。
