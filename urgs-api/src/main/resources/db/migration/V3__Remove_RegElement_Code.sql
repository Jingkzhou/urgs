-- Remove 'code' column from sys_reg_element
DROP PROCEDURE IF EXISTS DropCodeColumnIfExists;
DELIMITER $$
CREATE PROCEDURE DropCodeColumnIfExists()
BEGIN
    IF EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'sys_reg_element'
        AND COLUMN_NAME = 'code'
    ) THEN
        ALTER TABLE `sys_reg_element` DROP COLUMN `code`;
    END IF;
END$$
DELIMITER ;

CALL DropCodeColumnIfExists();
DROP PROCEDURE DropCodeColumnIfExists;
