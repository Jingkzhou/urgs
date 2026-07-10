# SQL 血缘引擎方言架构

## 1. 架构目标

本引擎以“准确率可验证、方言差异显式化、旧输出可兼容”为核心约束。Oracle、GBase、Hive 不再通过分散的字符串判断选择解析器，而是统一经过方言注册表、解析视图预处理、双引擎取证、事实归一化和质量门禁。

## 2. 主链路

```text
CLI / 并行 Worker
  -> LineageParser.analyze
  -> DialectProfile（显式方言优先，默认 mysql 才允许内容探测）
  -> SqlSplitter + 方言预处理（只生成解析视图，保留原 SQL 证据）
  -> GSP（存储过程、表级证据、兼容兜底）
  -> SQLGlot
       -> SELECT / CTAS / Hive MTI
       -> WHERE / JOIN / GROUP / ORDER 等控制依赖
       -> UPDATE / MERGE / INSERT ALL|FIRST mutation helper
  -> MetadataResolver（metadata-pack、星号展开、无别名字段消歧）
  -> 表名/字段名归一化、双引擎去重、置信度与歧义标记
  -> JSON / CSV / Neo4j
```

`parse()` 与 `get_column_lineage()` 继续作为旧调用方兼容接口；新调用方统一使用 `analyze()`，一次获得表级关系、字段级关系和实际方言信息。

## 3. 方言策略

| 外部方言 | Canonical Profile | SQLGlot | GSP | 说明 |
|---|---|---|---|---|
| `oracle` | `oracle` | `oracle` | `oracle` | 支持 q-quote、层次查询、MERGE、UPDATE、条件多表插入 |
| `gbase` / `gbase_8a` | `gbase_8a` | `mysql` | `mysql` | 与 URGS 连接器一致，按 GBase 8a/MySQL 协议解析 |
| `gbase_8s` | `gbase_8s` | 通用降级 | `informix` | 独立显式入口，不与 8a 混用 |
| `gbase_legacy_oracle` | `gbase_legacy_oracle` | `oracle` | 旧 GBase/Oracle 映射 | 只用于迁移期结果比对 |
| `hive` | `hive` | `hive` | `hive` | 支持 MTI、动态分区、LATERAL VIEW、位置引用和 JOIN USING |

方言选择优先级：显式 CLI/数据源配置 > 文件路径 > SQL 内容探测 > 默认值。显式 `gbase` 不会因为 SQL 中出现 `NVL` 而被切换为 Oracle。

## 4. 解析视图与原始证据

预处理只能修改交给解析器的“解析视图”，`snippet`、`statementHash` 和 `statementUid` 继续基于原始 SQL：

- GBase 8a：`REPLACE INTO` 生成等价 INSERT 解析视图；忽略 `DISTRIBUTED BY`、`COMPRESS`、`REPLICATED` 等存储属性。
- Oracle：q-quote 常量在 SQLGlot 解析视图中掩码，分号、注释符和单引号不会破坏 SQL 拆分。
- Hive：MTI 的共享 FROM 直接复制到每个分支，保留 JOIN 和 LATERAL VIEW 的原始别名作用域。

## 5. Mutation 模型

非 SELECT 型 DML 由独立 mutation helper 负责，避免继续把单目标假设堆入主解析器：

- `MERGE`：分别抽取 matched update、not-matched insert、ON 条件、USING 子查询过滤。
- `UPDATE`：区分 SET 直接数据流与 WHERE/EXISTS 控制流。
- Oracle `INSERT ALL` / `INSERT FIRST`：每个目标分支独立映射；WHEN 字段只产生控制依赖，不伪装成目标字段。

每条分支事实保留 `mutationIndex` / `mutation_index`，旧字段名及关系 UID 规则保持兼容。

## 6. 元数据与输出契约

物理模型不会以原始 DDL 拼接到 SQL 前。URGS 生成 `metadata-pack.json` 并通过 `--metadata-file` 传入；`MetadataResolver` 用它完成默认 schema、无别名字段消歧、目标列位置推断和 `SELECT *` 展开。

稳定输出字段包括：

- 表级：`source`、`target`、`dependency_type`、`neo4j_type`。
- 字段级：`source_table`、`source_column`、`target_table`、`target_column`、`dependency_type`。
- 证据：`statementUid`、`relationUid`、`sourceExpression`、`targetExpression`、`confidence`、`ambiguityCode`、`metadataPackHash`。

Neo4j 关系类型包含 `DERIVES_TO`、`FILTERS`、`JOINS`、`GROUPS`、`ORDERS`、`DISTRIBUTES`、`CLUSTERS`、`CALLS`、`REFERENCES`、`CASE_WHEN`。未知类型不得静默降成直接数据流。

## 7. 准确率门禁

测试分为三层：

1. 方言专项回归：精确断言正向边和禁止出现的假边。
2. Golden corpus：递归发现 Oracle、GBase、Hive 语料，分别统计表级、直接字段和控制字段 Precision / Recall / F1。
3. 输出契约：验证 CLI、方言信息、Neo4j 关系类型和 metadata-pack 行为。

新增方言或语法必须同时提交：方言 profile、必要的解析视图预处理、至少一个失败复现、精确预期边和质量门禁。升级 SQLGlot 前必须先跑完整 corpus；当前锁定 `sqlglot==27.27.0`。

## 8. 后续演进边界

Oracle PIVOT/UNPIVOT、MODEL、MATCH_RECOGNIZE 仍应作为独立 extractor 扩展，不在通用列遍历中增加启发式特判。GBase 8s/8c 必须以新的 profile 和真实业务语料接入，不允许复用裸 `gbase` 猜测产品族。
