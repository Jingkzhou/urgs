-- V25__Remove_DocumentTitle.sql
ALTER TABLE `sys_reg_table` DROP COLUMN `document_title`;
ALTER TABLE `sys_reg_element` DROP COLUMN `document_title`;
