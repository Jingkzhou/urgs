CREATE TABLE IF NOT EXISTS `sys_task_instance` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'Instance ID',
  `task_id` varchar(64) NOT NULL COMMENT 'Task ID',
  `task_type` varchar(20) NOT NULL COMMENT 'Task Type',
  `data_date` varchar(20) NOT NULL COMMENT 'Data Date (yyyy-MM-dd)',
  `status` varchar(20) NOT NULL DEFAULT 'WAITING' COMMENT 'Status',
  `retry_count` int(11) DEFAULT 0 COMMENT 'Retry Count',
  `log_path` varchar(255) DEFAULT NULL COMMENT 'Log File Path',
  `log_content` longtext COMMENT 'Task Execution Log',
  `content_snapshot` longtext COMMENT 'Task Content Snapshot',
  `start_time` datetime DEFAULT NULL COMMENT 'Start Time',
  `end_time` datetime DEFAULT NULL COMMENT 'End Time',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_task_date` (`task_id`,`data_date`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Task Instances';
