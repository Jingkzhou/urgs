-- V48: DEPENDENT 任务类型重构 — 清除历史实例并确保依赖关系完整
-- DEPENDENT 任务从此只作为纯虚拟 DAG 边存在，不再产生任务实例

-- 1. 删除所有 DEPENDENT 类型的任务实例（历史残留）
DELETE FROM sys_task_instance WHERE task_type = 'DEPENDENT';

-- 2. 清除 DEPENDENT 任务定义的 cron_expression，防止 TaskGeneratorJob 触发
UPDATE sys_task
SET cron_expression = NULL, last_trigger_time = NULL
WHERE type = 'DEPENDENT';

-- 3. 将 content.taskId 中的母体关系补录到 sys_task_dependency 表
--    确保 sys_task_dependency 成为依赖图遍历的唯一数据源
INSERT IGNORE INTO sys_task_dependency (task_id, pre_task_id)
SELECT
    t.id AS task_id,
    JSON_UNQUOTE(JSON_EXTRACT(t.content, '$.taskId')) AS pre_task_id
FROM sys_task t
WHERE t.type = 'DEPENDENT'
  AND JSON_EXTRACT(t.content, '$.taskId') IS NOT NULL
  AND JSON_UNQUOTE(JSON_EXTRACT(t.content, '$.taskId')) != ''
  AND NOT EXISTS (
      SELECT 1 FROM sys_task_dependency d
      WHERE d.task_id = t.id
        AND d.pre_task_id = JSON_UNQUOTE(JSON_EXTRACT(t.content, '$.taskId'))
  );
