DROP PROCEDURE IF EXISTS ExecuteIdempotent_V111;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V111()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_lineage_analysis_record'
          AND COLUMN_NAME = 'paths'
          AND DATA_TYPE <> 'longtext'
    ) THEN
        ALTER TABLE `t_lineage_analysis_record`
            MODIFY COLUMN `paths` LONGTEXT COMMENT '分析路径列表(JSON)';
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V111();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V111;
