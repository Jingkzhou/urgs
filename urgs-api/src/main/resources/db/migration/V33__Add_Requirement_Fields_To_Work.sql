-- 为 sys_work 表添加需求编号和附件字段
ALTER TABLE `sys_work` ADD COLUMN `requirement_number` VARCHAR(100) DEFAULT NULL COMMENT '需求编号' AFTER `deadline`;
ALTER TABLE `sys_work` ADD COLUMN `attachments` TEXT DEFAULT NULL COMMENT '附件列表(JSON字符串)' AFTER `requirement_number`;
