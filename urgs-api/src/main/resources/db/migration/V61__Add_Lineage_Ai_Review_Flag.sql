DROP PROCEDURE IF EXISTS ExecuteIdempotent_V61;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V61()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_lineage_analysis_record'
          AND COLUMN_NAME = 'ai_review_enabled'
    ) THEN
        ALTER TABLE `t_lineage_analysis_record`
            ADD COLUMN `ai_review_enabled` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否启用AI事后校验'
            AFTER `language`;
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V61();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V61;
