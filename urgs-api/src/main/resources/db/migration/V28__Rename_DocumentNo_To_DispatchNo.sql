-- V28__Rename_DocumentNo_To_DispatchNo.sql
ALTER TABLE `reg_table` CHANGE COLUMN `document_no` `dispatch_no` VARCHAR(255) COMMENT '发文号';
ALTER TABLE `reg_element` CHANGE COLUMN `document_no` `dispatch_no` VARCHAR(255) COMMENT '发文号';
