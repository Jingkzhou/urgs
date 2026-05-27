DROP PROCEDURE IF EXISTS ExecuteIdempotent_V70;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V70()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_lineage_review_issue'
          AND INDEX_NAME = 'idx_lineage_review_issue_pending_sort'
    ) THEN
        ALTER TABLE `t_lineage_review_issue`
            ADD INDEX `idx_lineage_review_issue_pending_sort` (
                `task_id`,
                `review_status`,
                `severity` DESC,
                `confidence` DESC,
                `create_time` DESC
            );
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V70();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V70;
