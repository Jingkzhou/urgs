# SQL Lineage Engine

SQL Lineage Engine 是一款高性能、双引擎驱动的 SQL 血缘解析工具，旨在从复杂的存储逻辑中提取精确的字段级和表级血缘关系，并支持可视化导出。

## 核心架构

项目采用 **GSP (General SQL Parser)** + **SQLGlot** 的双引擎驱动架构：
- **GSP (核心引擎)**：利用成熟的商业解析能力，专注于复杂语法的深度血缘提取和存储过程解析。
- **SQLGlot (辅助引擎)**：用于轻量级的方言探测、SQL 拆分以及作为 GSP 解析失败时的健壮性降级方案。

## 关键特性

- **多方言自探测**：自动识别 Oracle, GBase, Hive, MySQL, SparkSQL 等方言特征，动态切换解析策略。
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
│   ├── indirect_parser.py # SQLGlot 间接血缘提取
│   └── parallel_parser.py # 多进程并行调度逻辑
├── utils/              # 通用组件
│   ├── splitter.py     # 智能 SQL 拆分器
│   └── normalize.py    # 表名/字段名标准化工具
├── requirements.txt    # Python 依赖清单
└── run.sh              # 快速运行脚本
```

## 快速开始

### 环境依赖

- **Python**: 3.8+
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

2. **批量并行解析整个 SQL 目录**:
   ```bash
   ./run.sh parse-sql --file ./path/to/sql_files/ --output json --output-file results.json
   ```
   ./run.sh parse-sql --file ./tests/sql/ --output neo4j
- **Web UI 适配**：提供与 URGS 平台深度集成的血缘可视化面板。

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
