DROP PROCEDURE IF EXISTS ExecuteIdempotent_V98;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V98()
BEGIN
    DECLARE task_status_migration_needed BOOLEAN DEFAULT FALSE;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_work_task'
    ) THEN
        IF NOT EXISTS (
            SELECT 1 FROM `sys_work_task`
            WHERE `status` IN ('APPLIED', 'ASSIGNED', 'ASSET_REVIEW', 'REVIEW', 'REJECTED', 'OVERDUE')
        ) THEN
            SET task_status_migration_needed = FALSE;
        ELSE
            SET task_status_migration_needed = TRUE;
        END IF;

        IF task_status_migration_needed THEN
            UPDATE `sys_work_task`
            SET `status` = CASE `status`
                WHEN 'APPLIED' THEN 'OPEN'
                WHEN 'ASSIGNED' THEN 'READY'
                WHEN 'ASSET_REVIEW' THEN 'WAITING_REVIEW'
                WHEN 'REVIEW' THEN 'WAITING_REVIEW'
                WHEN 'REJECTED' THEN 'REWORK'
                WHEN 'OVERDUE' THEN IF(`assignee_id` IS NULL OR `assignee_id` = '', 'OPEN', 'IN_PROGRESS')
                ELSE `status`
            END
            WHERE `status` IN ('APPLIED', 'ASSIGNED', 'ASSET_REVIEW', 'REVIEW', 'REJECTED', 'OVERDUE');
        END IF;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_work'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_work_task'
    ) THEN
        UPDATE `sys_work` work_record
        SET `status` = CASE
            WHEN work_record.`status` = 'DRAFT' THEN 'DRAFT'
            WHEN work_record.`status` = 'CANCELLED' THEN 'CANCELLED'
            WHEN EXISTS (
                SELECT 1
                FROM `sys_work_task` main_task
                WHERE main_task.`work_id` = work_record.`id`
                  AND main_task.`task_role` = 'MAIN'
                  AND main_task.`status` = 'COMPLETED'
            ) AND NOT EXISTS (
                SELECT 1
                FROM `sys_work_task` sub_task
                WHERE sub_task.`work_id` = work_record.`id`
                  AND sub_task.`task_role` = 'SUB'
                  AND sub_task.`status` NOT IN ('COMPLETED', 'CANCELLED')
            ) THEN 'COMPLETED'
            WHEN EXISTS (
                SELECT 1
                FROM `sys_work_task` main_task
                WHERE main_task.`work_id` = work_record.`id`
                  AND main_task.`task_role` = 'MAIN'
                  AND main_task.`status` = 'WAITING_REVIEW'
                  AND main_task.`current_stage` = 'LAUNCH'
            ) THEN 'ACCEPTANCE'
            WHEN EXISTS (
                SELECT 1
                FROM `sys_work_task` unfinished_task
                WHERE unfinished_task.`work_id` = work_record.`id`
                  AND unfinished_task.`status` NOT IN ('COMPLETED', 'CANCELLED')
            ) AND NOT EXISTS (
                SELECT 1
                FROM `sys_work_task` unpaused_task
                WHERE unpaused_task.`work_id` = work_record.`id`
                  AND unpaused_task.`status` NOT IN ('COMPLETED', 'CANCELLED', 'PAUSED')
            ) THEN 'PAUSED'
            WHEN EXISTS (
                SELECT 1
                FROM `sys_work_task` started_task
                WHERE started_task.`work_id` = work_record.`id`
                  AND started_task.`status` IN (
                      'IN_PROGRESS', 'WAITING_REVIEW', 'REWORK', 'PAUSED', 'COMPLETED'
                  )
            ) THEN 'ACTIVE'
            ELSE 'PUBLISHED'
        END
        WHERE work_record.`status` <> 'DRAFT';
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V98();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V98;
