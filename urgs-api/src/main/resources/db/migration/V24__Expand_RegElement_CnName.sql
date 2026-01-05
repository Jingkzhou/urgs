-- V24__Expand_RegElement_CnName.sql
-- Expand cn_name column length to 500 to prevent data truncation

ALTER TABLE `sys_reg_element` MODIFY COLUMN `name` VARCHAR(5000) COMMENT '名称';
ALTER TABLE `sys_reg_element` MODIFY COLUMN `cn_name` VARCHAR(5000) COMMENT '中文名';
