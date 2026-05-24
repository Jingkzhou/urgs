DROP PROCEDURE IF EXISTS ExecuteIdempotent_V66;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V66()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_lineage_review_issue'
          AND COLUMN_NAME = 'confirmed_problem_type'
    ) THEN
        ALTER TABLE `t_lineage_review_issue`
            ADD COLUMN `confirmed_problem_type` VARCHAR(64) DEFAULT NULL COMMENT '人工确认问题类型：SQL_STANDARD SQL书写规范，PARSER_BUG 解析程序BUG' AFTER `reviewer_note`;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_lineage_review_issue'
          AND COLUMN_NAME = 'confirmed_problem_description'
    ) THEN
        ALTER TABLE `t_lineage_review_issue`
            ADD COLUMN `confirmed_problem_description` TEXT COMMENT '人工确认问题描述' AFTER `confirmed_problem_type`;
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V66();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V66;
