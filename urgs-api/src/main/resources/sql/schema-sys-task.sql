-- 任务定义表
CREATE TABLE IF NOT EXISTS `sys_task` (
  `id` varchar(64) NOT NULL COMMENT 'Task ID',
  `name` varchar(100) NOT NULL COMMENT 'Task Name',
  `type` varchar(50) NOT NULL COMMENT 'Task Type (SHELL, SQL, etc)',
  `content` longtext COMMENT 'Task Configuration (JSON)',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Task Definitions';
