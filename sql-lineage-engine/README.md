# SQL Lineage Engine

SQL Lineage Engine 是一款高性能、双引擎驱动的 SQL 血缘解析工具，旨在从复杂的存储逻辑中提取精确的字段级和表级血缘关系，并支持可视化导出。

## 核心架构

项目采用 **方言注册表 + GSP + SQLGlot + metadata-pack** 的双引擎架构：
- **DialectProfile**：统一外部方言名、SQLGlot 方言、GSP vendor 和路径探测，避免同一 SQL 在不同阶段使用不同语法假设。
- **GSP**：负责复杂存储过程、表级证据和兼容兜底。
- **SQLGlot**：负责可验证的字段直接流、条件流，以及 UPDATE、MERGE、INSERT ALL/FIRST 等 mutation 解析。
- **MetadataResolver**：使用 `metadata-pack.json` 完成 schema 补全、字段消歧和 `SELECT *` 展开。

## 关键特性

- **多方言策略**：显式方言优先；支持 Oracle、GBase 8a、Hive、MySQL、SparkSQL 等，默认 MySQL 模式下才启用内容探测。
- **复杂 DML**：支持 Oracle/Hive MERGE、UPDATE、Oracle INSERT ALL/FIRST 和 Hive Multi-Table Insert。
- **存储过程支持**：能够自动提取并解析 `CREATE PROCEDURE` 中的主体逻辑，透视复杂流程中的数据流向。
- **智能 SQL 拆分**：针对超长脚本（如 10,000+ 字符），自动平衡性能与准确性，进行语义化拆分处理。
- **高性能并行解析**：在目录扫描模式下，利用多进程（ProcessPool）并行解析数千个 SQL 文件，显著提升吞吐量。
- **Neo4j 集成**：内置 Neo4j Exporter，支持血缘数据的一键入库及版本化管理，方便进行图谱可视化。

## 项目结构

```text
sql-lineage-engine/
├── bin/                # 入口目录，包含 CLI 工具
│   └── lineage-cli     # 主命令行程序
├── config/             # 配置目录
│   └── settings.py     # 环境变量及连接配置
├── exporters/          # 导出逻辑
│   └── neo4j.py        # Neo4j 客户端及 Cypher 模板
├── parsers/            # 核心解析器
│   ├── sql_parser.py   # 顶层调度解析器 (Parser Manager)
│   ├── gsp.py          # GSP 引擎封装
│   ├── indirect_flow_parser.py # SQLGlot 字段与控制血缘提取
│   ├── indirect_flow_mutation_helpers.py # UPDATE/MERGE/多目标 INSERT
│   └── parallel_parser.py # 多进程并行调度逻辑
├── utils/              # 通用组件
│   ├── dialect_registry.py # 方言注册表
│   ├── dialect_preprocessor.py # 方言解析视图预处理
│   ├── splitter.py     # 智能 SQL 拆分器
│   └── normalize.py    # 表名/字段名标准化工具
├── requirements.txt    # Python 依赖清单
└── run.sh              # 快速运行脚本
```

## 快速开始

### 环境依赖

- **Python**: 3.10+
- **Java**: 推荐使用 Java 8 (Corretto/OpenJDK)。
- **GSP 引擎库**: 
    - 必须手动下载 `gudusoft.gsqlparser.jar` 及相关依赖。
    - 将 JAR 文件放置于 `parsers/jar/` 目录下。
    - (缺失 JAR 将导致 `Java Virtual Machine is not running` 或 `No JARs found` 错误)
- **依赖库**: `pip install -r requirements.txt`

### 运行示例

1. **解析单个 SQL 字符串并导出到 Neo4j**:
   ```bash
   ./run.sh parse-sql --sql "INSERT INTO B SELECT * FROM A" --dialect mysql --output neo4j
   ```

   GBase 8a 使用 `--dialect gbase`（等价于 `gbase_8a`），不会映射为 Oracle：

   ```bash
   ./run.sh parse-sql --sql "INSERT INTO \`B\` SELECT * FROM \`A\`" --dialect gbase --output json
   ```

2. **批量并行解析整个 SQL 目录**:
   ```bash
   ./run.sh parse-sql --file ./path/to/sql_files/ --output json --output-file results.json
   ./run.sh parse-sql --file ./tests/sql/ --output neo4j
   ```

---

## 🧪 测试

项目使用 **黄金测试集** 对血缘解析的准确性进行量化度量，测试数据位于 `tests/golden/` 目录。

### 运行全部测试

```bash
.venv/bin/python -m pytest tests -q
```

### 运行单个用例

```bash
# 按用例名筛选
.venv/bin/python -m pytest tests/test_golden_lineage.py -k "04_subquery_cte" -v

# 只跑表级 / 字段级
.venv/bin/python -m pytest tests/test_golden_lineage.py::test_table_lineage -v
.venv/bin/python -m pytest tests/test_golden_lineage.py::test_column_lineage -v
```

### 生成准确率报告

```bash
# 输出到终端（Markdown 格式，含 Precision / Recall / F1）
.venv/bin/python scripts/run_golden_tests.py

# 保存到文件
.venv/bin/python scripts/run_golden_tests.py -o report.md
```

### 添加新的测试用例

在 `tests/golden/` 或其方言子目录下添加一对文件即可递归发现：

- `xxx.sql` 或 `xxx.prc` — 待测试的 SQL
- `xxx.expected.json` — 人工标注的预期血缘

预期 JSON 格式：

```json
{
  "dialect": "oracle",
  "description": "用例描述",
  "table_lineage": {
    "sources": ["源表"],
    "targets": ["目标表"]
  },
  "column_lineage": [
    {
      "source_table": "源表",
      "source_column": "源列",
      "target_table": "目标表",
      "target_column": "目标列",
      "dependency_type": "fdd"
    }
  ]
}
```

> `dependency_type` 可选值：`fdd`（直接数据流）、`fdr`（WHERE/HAVING 条件）、`join`（JOIN 关联）

可通过 `quality_gates` 为新语料设置直接流和控制流门禁。架构与扩展约束见 [方言血缘架构](docs/design/dialect_lineage_architecture.md)。

---

## 🛠️ 故障排除 (Troubleshooting)

如果在容器环境（Docker/K8s）中运行遇到 `pthread_create failed (EPERM)` 或 `GC Thread#0` 启动失败，请参考以下方案：

### 1. 放宽容器限制 (推荐)
`EPERM` 错误通常由于容器运行时的 `seccomp` 策略限制了新的系统调用（如 `clone3`）。
- **Docker**: 启动时增加 `--security-opt seccomp=unconfined` 参数。
- **K8s**: 在 `securityContext` 中设置：
  ```yaml
  securityContext:
    seccompProfile:
      type: Unconfined
  ```
- **资源限制**: 确保容器的 `pids-limit` 足够大（建议 `8192` 以上）。

### 2. 规避 clone3 路径 (镜像优化)
如果无法修改宿主机容器运行时配置，建议调整基础镜像以避开高版本 JDK 的 `clone3` 调用路径：
- **基础镜像**: 改用 `Debian bullseye` 或其变体。
- **Java 版本**: 维持在 `openjdk-8-jre-headless` 或 `openjdk-17-jre-headless`。

### 3. 宿主机运行
若受限容器环境始终无法解决权限问题，建议在宿主机直接安装 Python 依赖并运行 `lineage-cli`。

## 📄 许可证

[MIT](LICENSE)
