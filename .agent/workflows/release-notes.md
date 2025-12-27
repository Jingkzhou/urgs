---
description: 版本维护记录管理工作流
---

# 版本维护记录规范

为了清晰追踪项目的演进过程，每次需求开发或重大修复完成后，必须在版本记录中进行登记。

## 记录规则

1. **路径要求**：记录存放在 `/Users/work/Documents/JLbankGit/URGS/docs/release-notes/` 目录下。
2. **文件命名**：
    - 日常变更：使用 `YYYY-MM-DD.md`（如果当天已有文件，则追加内容）。
    - 重大版本：使用 `v<Version>__<Description>.md`。
3. **内容格式**：
    - **变更摘要**：简短描述新增功能、变更点或修复项。
    - **修改类型**：区分 [新增] (New Feature)、[变更] (Update/Adjustment) 或 [修复] (Fix)。
    - **影响范围**：列出受影响的模块或核心文件路径。
4. **Agent 执行流程**：
    - 在完成 USER 侧的功能开发和自测后，作为最后一步，Agent 必须检查今日是否存在变更记录文件。
    - 若不存在，参照模板创建新文件；若已存在，在合适位置追加本次任务的摘要和文件列表。

## 示例

### [新增] 工作流关联系统字段
- **描述**: 在创建工作流时增加“关联系统”选择，并设为必填。
- **文件**: `WorkflowDefinition.tsx`, `WorkflowService.java`, `V10__Add_SystemId_To_Workflow.sql`
