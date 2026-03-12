DROP PROCEDURE IF EXISTS ExecuteIdempotent_V28;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V28()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

-- V28__Rename_DocumentNo_To_DispatchNo.sql
ALTER TABLE `reg_table` CHANGE COLUMN `document_no` `dispatch_no` VARCHAR(255) COMMENT '发文号';
ALTER TABLE `reg_element` CHANGE COLUMN `document_no` `dispatch_no` VARCHAR(255) COMMENT '发文号';


END$$
DELIMITER ;
CALL ExecuteIdempotent_V28();
DROP PROCEDURE ExecuteIdempotent_V28;
