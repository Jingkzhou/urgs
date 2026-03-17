DROP PROCEDURE IF EXISTS ExecuteIdempotent_V25;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V25()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

-- V25__Remove_DocumentTitle.sql
ALTER TABLE `sys_reg_table` DROP COLUMN `document_title`;
ALTER TABLE `sys_reg_element` DROP COLUMN `document_title`;


END$$
DELIMITER ;
CALL ExecuteIdempotent_V25();
DROP PROCEDURE ExecuteIdempotent_V25;
