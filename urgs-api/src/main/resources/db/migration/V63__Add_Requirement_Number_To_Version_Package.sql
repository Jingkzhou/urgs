-- 生产投产包记录需求编号

DROP PROCEDURE IF EXISTS ExecuteIdempotent_V63;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V63()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_version_package'
          AND COLUMN_NAME = 'requirement_number'
    ) THEN
        ALTER TABLE `t_version_package`
            ADD COLUMN `requirement_number` VARCHAR(100) COMMENT '需求编号' AFTER `previous_commit_sha`;
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V63();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V63;
