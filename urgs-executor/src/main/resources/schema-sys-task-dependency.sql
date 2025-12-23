CREATE TABLE IF NOT EXISTS `sys_task_dependency` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `task_id` varchar(64) NOT NULL COMMENT 'Downstream Task ID',
  `pre_task_id` varchar(64) NOT NULL COMMENT 'Upstream Task ID',
  PRIMARY KEY (`id`),
  KEY `idx_task` (`task_id`),
  KEY `idx_pre_task` (`pre_task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Task Dependencies';
