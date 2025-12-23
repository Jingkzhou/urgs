ALTER TABLE `sys_task`
ADD COLUMN `cron_expression` varchar(100) DEFAULT NULL COMMENT 'Cron Expression',
ADD COLUMN `data_date_rule` varchar(50) DEFAULT NULL COMMENT 'Data Date Rule (e.g., T, T-1)',
ADD COLUMN `status` int(1) DEFAULT 1 COMMENT 'Status (1: Enable, 0: Disable)',
ADD COLUMN `last_trigger_time` datetime DEFAULT NULL COMMENT 'Last Trigger Time',
ADD COLUMN `priority` int(11) DEFAULT 0 COMMENT 'Priority';
