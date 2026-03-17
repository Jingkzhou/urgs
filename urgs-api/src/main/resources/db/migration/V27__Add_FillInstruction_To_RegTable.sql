DROP PROCEDURE IF EXISTS ExecuteIdempotent_V27;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V27()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

-- V27__Add_FillInstruction_To_RegTable.sql
ALTER TABLE `reg_table` ADD COLUMN `fill_instruction` TEXT COMMENT '填报说明';


END$$
DELIMITER ;
CALL ExecuteIdempotent_V27();
DROP PROCEDURE ExecuteIdempotent_V27;
