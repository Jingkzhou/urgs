DROP PROCEDURE IF EXISTS upgrade_v20251229_hardware_model;

DELIMITER $$
CREATE PROCEDURE upgrade_v20251229_hardware_model()
BEGIN
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_infrastructure_asset'
        AND COLUMN_NAME = 'hardware_model'
    ) THEN
        ALTER TABLE t_infrastructure_asset ADD COLUMN hardware_model VARCHAR(100) COMMENT '服务器硬件型号';
    END IF;
END $$
DELIMITER ;

CALL upgrade_v20251229_hardware_model();
DROP PROCEDURE IF EXISTS upgrade_v20251229_hardware_model;
