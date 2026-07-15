DROP PROCEDURE IF EXISTS ExecuteIdempotent_V104;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V104()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_work_task'
          AND COLUMN_NAME = 'current_stage'
    ) THEN
        UPDATE `sys_work_task`
        SET `current_stage` = CASE `current_stage`
            WHEN 'REQUIREMENT' THEN 'TEST_SUBMISSION_COMPLETED'
            WHEN 'DEVELOPMENT' THEN 'TEST_SUBMISSION_COMPLETED'
            WHEN 'TESTING' THEN 'QUALITY_ACCEPTANCE_COMPLETED'
            ELSE `current_stage`
        END
        WHERE `current_stage` IN ('REQUIREMENT', 'DEVELOPMENT', 'TESTING');

        ALTER TABLE `sys_work_task`
            MODIFY COLUMN `current_stage` VARCHAR(32) DEFAULT 'TEST_SUBMISSION_COMPLETED'
                COMMENT '当前阶段: TEST_SUBMISSION_COMPLETED/QUALITY_ACCEPTANCE_COMPLETED/ASSET_REVIEW/LAUNCH';
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V104();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V104;
