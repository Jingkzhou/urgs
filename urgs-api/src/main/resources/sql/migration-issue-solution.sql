-- 增加解决方案字段
ALTER TABLE sys_issue ADD COLUMN solution TEXT COMMENT '解决方案' AFTER description;
