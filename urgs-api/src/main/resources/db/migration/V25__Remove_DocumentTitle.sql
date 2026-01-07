-- V25__Remove_DocumentTitle.sql
ALTER TABLE `reg_table` DROP COLUMN `document_title`;
ALTER TABLE `reg_element` DROP COLUMN `document_title`;
