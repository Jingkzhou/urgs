CREATE TABLE IF NOT EXISTS `t_quartz_task_dependency` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `task_id` bigint NOT NULL COMMENT '当前任务ID',
  `pre_task_id` bigint NOT NULL COMMENT '上游依赖任务ID',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_task_pre` (`task_id`, `pre_task_id`) USING BTREE,
  KEY `idx_task_id` (`task_id`) USING BTREE,
  KEY `idx_pre_task_id` (`pre_task_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='Quartz任务依赖关系表';

INSERT IGNORE INTO `t_quartz_task_dependency` (`task_id`, `pre_task_id`)
SELECT
  t.id AS task_id,
  CAST(
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.depend_id, ',', seq.n), ',', -1))
    AS UNSIGNED
  ) AS pre_task_id
FROM `t_quartz_task` t
JOIN (
  SELECT ones.n + tens.n * 10 + hundreds.n * 100 + 1 AS n
  FROM
    (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
     UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) ones
  CROSS JOIN
    (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
     UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) tens
  CROSS JOIN
    (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
     UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) hundreds
) seq
  ON seq.n <= 1 + LENGTH(t.depend_id) - LENGTH(REPLACE(t.depend_id, ',', ''))
WHERE t.depend_id IS NOT NULL
  AND TRIM(t.depend_id) <> ''
  AND TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.depend_id, ',', seq.n), ',', -1)) REGEXP '^[0-9]+$';
