-- 1. Re-create sys_task table with VARCHAR id
DROP TABLE IF EXISTS `sys_task`;
CREATE TABLE `sys_task` (
  `id` varchar(64) NOT NULL COMMENT 'Task ID (UUID)',
  `name` varchar(100) NOT NULL COMMENT 'Task Name',
  `type` varchar(50) NOT NULL COMMENT 'Task Type (SHELL, SQL, etc)',
  `content` longtext COMMENT 'Task Configuration (JSON)',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Task Definitions';

-- 2. Add content column to sys_workflow if it doesn't exist
-- Note: This might fail if column exists, safe to ignore in dev or wrap in procedure if needed.
ALTER TABLE `sys_workflow` ADD COLUMN `content` longtext DEFAULT NULL COMMENT 'Graph JSON';
