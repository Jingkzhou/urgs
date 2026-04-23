DROP PROCEDURE IF EXISTS ExecuteIdempotent_V55;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V55()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF EXISTS (
        SELECT *
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_lineage_analysis_record'
          AND COLUMN_NAME = 'repo_id'
          AND IS_NULLABLE = 'NO'
    ) THEN
        ALTER TABLE `t_lineage_analysis_record`
            MODIFY COLUMN `repo_id` BIGINT NULL COMMENT 'Git仓库ID，上传模式可为空';
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V55();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V55;
