# URGS 资产契约

在 URGS 仓库使用本 Skill 时读取本文件。执行前仍需回读源码或接口，因为权限和表结构可能变化。

## 监管资产与口径目标

监管表：

- Java：`urgs-api/src/main/java/com/example/urgs_api/metadata/model/RegTable.java`
- 数据表：`reg_table`
- 回写目标：`business_caliber` / `businessCaliber`
- 定位键：`system_code`、表名或监管表 ID
- 相关证据：中文名、主题、频度、填报说明、研发备注

监管字段/指标：

- Java：`urgs-api/src/main/java/com/example/urgs_api/metadata/model/RegElement.java`
- 数据表：`reg_element`
- 类型：`FIELD` 或 `INDICATOR`
- 回写目标：`business_caliber` / `businessCaliber`
- 相关证据：中文名、公式、取数 SQL、代码片段、值域、校验规则、填报说明

`RegTable` 和 `RegElement` 已有专用业务口径字段。不要给 `model_table`、`model_field` 新增同名字段，也不要把物理模型的 `business_scope`、`domain` 或 `remark` 当作监管资产业务口径。

## 码表和值域

- 由 `reg_element.code_table_code` 定位码表；
- 读取当前有效码值、名称和说明；
- SQL 中出现的常量只有与正式码值匹配后才能写入业务口径。

## 物理绑定的作用

- `reg_table_model_table_rel`：监管表到物理模型表；
- `reg_element_model_field_rel`：监管字段/指标到物理模型字段；
- `RegulatoryMarketContextService`：读取监管语义、物理绑定和码值。

物理资产只用于把加工 SQL 的源表、目标列和表达式映射到监管资产，不是本 Skill 的业务口径回写目标。绑定关系也不自动证明多个源表之间的 JOIN，JOIN 仍以 SQL 和已维护关系为证据。

## 回写权限与边界

- 查询、定位和预览：`metadata:asset:view`；
- 更新监管表口径：`metadata:asset:edit`；
- 更新监管字段或指标口径：`metadata:asset:element:edit`；
- 服务端根据请求用户的监管系统范围校验 `RegTable.systemCode`；
- 回写只修改现有 `business_caliber` 和 `update_time`；
- 加工 SQL 只作为审计证据，不执行；
- 每个实际变更写入 `maintenance_record`，资产类型为 `REG_ASSET`。

## URGS 定位顺序

1. 使用 CodeGraph 定位 `RegTable`、`RegElement`、Controller、Service 和影响面。
2. 用监管系统编码和监管表名定位唯一 `RegTable`。
3. 用表 ID 和元素名称定位 `RegElement`，保留其 `FIELD` / `INDICATOR` 类型。
4. 通过物理绑定把加工 SQL 的表和字段映射到监管表及监管元素。
5. 通过监管集市接口加载表描述、元素描述、公式、码表和值域。
6. 按 `references/asset-caliber-writeback.md` 读取当前值、预览、确认、回写并回读验证。
