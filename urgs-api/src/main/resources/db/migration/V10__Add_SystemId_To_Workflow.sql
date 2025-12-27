-- Add system_id column to sys_workflow table
ALTER TABLE `sys_workflow` ADD COLUMN `system_id` BIGINT COMMENT '系统ID' AFTER `description`;
