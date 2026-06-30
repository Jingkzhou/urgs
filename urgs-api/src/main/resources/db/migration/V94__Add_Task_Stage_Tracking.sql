DROP PROCEDURE IF EXISTS ExecuteIdempotent_V94;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V94()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_work_task'
    ) THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'sys_work_task'
              AND COLUMN_NAME = 'current_stage'
        ) THEN
            ALTER TABLE `sys_work_task`
                ADD COLUMN `current_stage` VARCHAR(32) DEFAULT 'REQUIREMENT' COMMENT '当前阶段: REQUIREMENT/DEVELOPMENT/TESTING/LAUNCH' AFTER `parent_task_id`;
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'sys_work_task'
              AND COLUMN_NAME = 'stage_risk_reported'
        ) THEN
            ALTER TABLE `sys_work_task`
                ADD COLUMN `stage_risk_reported` TINYINT(1) DEFAULT 0 COMMENT '当前阶段是否已报备风险' AFTER `current_stage`;
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'sys_work_task'
              AND COLUMN_NAME = 'stage_risk_note'
        ) THEN
            ALTER TABLE `sys_work_task`
                ADD COLUMN `stage_risk_note` TEXT COMMENT '当前阶段风险说明' AFTER `stage_risk_reported`;
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'sys_work_task'
              AND COLUMN_NAME = 'stage_updated_at'
        ) THEN
            ALTER TABLE `sys_work_task`
                ADD COLUMN `stage_updated_at` DATETIME DEFAULT NULL COMMENT '阶段更新时间' AFTER `stage_risk_note`;
        END IF;

        UPDATE `sys_work_task`
        SET `current_stage` = 'REQUIREMENT'
        WHERE `current_stage` IS NULL OR `current_stage` = '';

        UPDATE `sys_work_task`
        SET `stage_risk_reported` = 0
        WHERE `stage_risk_reported` IS NULL;
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V94();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V94;
