-- Add attachment columns to sys_issue
ALTER TABLE `sys_issue` ADD COLUMN `attachment_path` VARCHAR(500) COMMENT '附件存储路径';
ALTER TABLE `sys_issue` ADD COLUMN `attachment_name` VARCHAR(255) COMMENT '附件原始名称';
