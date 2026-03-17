---
name: sql-lineage-analyzer
description: 双引擎 SQL 血缘解析工具（GSP + sqlglot），支持多方言解析。提供表级和字段级血缘分析、存储过程解析、增量比对及影响范围评估。当需要进行数据治理、数据血缘可视化、数据质量管理、ETL 文档生成或变更影响分析时使用。
---

# SQL 血缘解析器

双引擎架构（GSP 核心 + sqlglot 辅助）的 SQL 血缘分析工具。

## 核心能力

| 能力       | 说明                                             |
| ---------- | ------------------------------------------------ |
| 双引擎     | GSP 深度解析 + sqlglot 方言探测/间接依赖/降级    |
| 多方言     | MySQL, Oracle, Hive, GBase, SparkSQL, PostgreSQL |
| 存储过程   | 自动提取 BEGIN..END 主体逻辑                     |
| 智能切片   | 超长 SQL 自动三策略拆分（VALUES/UNION ALL/列宽） |
| CTE 展开   | 递归解析 WITH 子句到物理表                       |
| 表级血缘   | 源表→目标表关系（fdd/fdr/join 类型）             |
| 字段级血缘 | 字段来源追踪，含间接依赖（WHERE/JOIN/GROUP BY）  |
| 增量比对   | 对比新旧版本血缘差异                             |
| 可视化     | Mermaid 图、影响分析报告                         |

## 环境依赖

- **Python 3.8+**
- **Java 8+**：GSP 引擎需要 JVM
- **Python 包**：`pip install sqlglot jpype1`
- **GSP JAR**：位于 `assets/jar/`（`gudusoft.gsqlparser-*.jar`）

## 工作流

### 1. 解析 SQL 血缘

```python
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'scripts'))
from parse_lineage import LineageParser

parser = LineageParser(dialect="oracle")

# 表级血缘
result = parser.parse(sql_content, source_file="path/to/file.sql")
# 返回: {"sources": [...], "targets": [...], "relationships": [...]}

# 字段级血缘
deps = parser.get_column_lineage(sql_content, source_file="path/to/file.sql")
# 返回: [{"source_table", "source_column", "target_table", "target_column", "dependency_type"}, ...]
```

命令行用法：
```bash
# 表级血缘
python scripts/parse_lineage.py input.sql oracle

# 字段级血缘
python scripts/parse_lineage.py procedure.prc oracle --column
```

### 2. 生成可视化

```bash
# 表级血缘图
python scripts/visualize_lineage.py lineage.json table

# 字段级血缘图
python scripts/visualize_lineage.py lineage.json column

# 影响分析
python scripts/visualize_lineage.py lineage.json impact ods.orders
```

### 3. 增量比对

```python
from parse_lineage import LineageParser, compare_lineage

parser = LineageParser()
old = parser.parse(old_sql)
new = parser.parse(new_sql)
diff = compare_lineage(old, new)
# diff: {added_sources, removed_sources, added_targets, removed_targets}
```

## 解析策略

1. **GSP 优先** - 商业级 SQL 解析器提供深度血缘
2. **sqlglot 补充** - 提取间接依赖（WHERE/HAVING/JOIN/GROUP BY）
3. **CTE 递归展开** - WITH 别名解析到物理表
4. **方言自动探测** - 根据关键字启发式识别 Oracle/Hive
5. **正则降级** - GSP 失败时的最终兜底方案

## 配置

| 环境变量             | 说明             | 默认值 |
| -------------------- | ---------------- | ------ |
| `SQLFLOW_CHAR_LIMIT` | 智能切片触发阈值 | 10000  |

## 详细参考

- [preprocessing.md](references/preprocessing.md) - SQL 预处理逻辑
- [dialect-patterns.md](references/dialect-patterns.md) - 各方言特殊语法
- [complex-cases.md](references/complex-cases.md) - 复杂场景处理策略
- [output-schema.md](references/output-schema.md) - 输出格式规范

## 脚本清单

| 脚本                      | 说明                                        |
| ------------------------- | ------------------------------------------- |
| `parse_lineage.py`        | 主解析入口（LineageParser 类 + CLI）        |
| `gsp_parser.py`           | GSP 引擎封装（JVM 管理、预处理、JSON 映射） |
| `indirect_flow_parser.py` | sqlglot 间接依赖提取                        |
| `splitter.py`             | SQL 智能拆分器                              |
| `normalize.py`            | 表名标准化工具                              |
| `visualize_lineage.py`    | Mermaid 可视化 + 影响分析                   |
