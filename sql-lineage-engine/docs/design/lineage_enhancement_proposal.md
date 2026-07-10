# 元数据驱动血缘方案（已落地）

原方案曾计划把生成的 DDL 文本拼接到业务 SQL 前再解析；当前实现已经改为更稳定的 metadata-pack 方案，禁止继续按“DDL 注入”理解或扩展。

## 当前数据流

```text
URGS 物理模型 ModelTable / ModelField
  -> LineageMetadataPackService
  -> logs/metadata-packs/{recordId}/metadata-pack.json
  -> lineage-cli --metadata-file
  -> MetadataResolver / MetadataPackResolver
  -> 默认 schema、字段归属消歧、SELECT * 展开、目标列位置推断
  -> confidence / ambiguityCode / metadataPackHash
```

## 设计约束

- metadata-pack v1 是外部兼容契约，新增字段必须可选。
- 元数据缺失时可以降级解析，但必须保留 LOW/MEDIUM 置信度或歧义原因，不能猜测多表无别名字段。
- `SELECT *` 只有在字段顺序可确定时才能展开为字段级血缘；否则保留 `STAR_EXPANSION_UNAVAILABLE` 事实。
- SQL 文件内的 INSERT 目标列可以注册为本次分析的局部元数据，但不能污染其他任务。
- 方言选择、mutation 解析和输出模型见 [dialect_lineage_architecture.md](./dialect_lineage_architecture.md)。

## 验证要求

- `tests/test_metadata_pack_resolver.py` 验证唯一匹配、歧义、星号展开和目标列推断。
- Golden corpus 必须同时比较表级、直接字段和控制字段关系。
- 元数据增强不得改变原 SQL 的 `statementUid`、证据片段和版本隔离语义。
