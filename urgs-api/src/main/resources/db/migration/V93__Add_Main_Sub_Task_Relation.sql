DROP PROCEDURE IF EXISTS ExecuteIdempotent_V93;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V93()
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
              AND COLUMN_NAME = 'task_role'
        ) THEN
            ALTER TABLE `sys_work_task`
                ADD COLUMN `task_role` VARCHAR(16) DEFAULT 'SUB' COMMENT '任务角色: MAIN/SUB' AFTER `work_id`;
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'sys_work_task'
              AND COLUMN_NAME = 'parent_task_id'
        ) THEN
            ALTER TABLE `sys_work_task`
                ADD COLUMN `parent_task_id` VARCHAR(64) DEFAULT NULL COMMENT '父任务ID, 子任务指向主任务' AFTER `task_role`;
        END IF;

        UPDATE `sys_work_task`
        SET `task_role` = 'SUB'
        WHERE `task_role` IS NULL OR `task_role` = '';

        INSERT INTO `sys_work_task` (
            `id`, `work_id`, `task_role`, `parent_task_id`, `title`, `description`,
            `task_type`, `difficulty`, `required_skills`, `acceptance_criteria`,
            `points`, `estimated_hours`, `assign_mode`, `status`, `assignee_id`,
            `max_applicants`, `deadline`, `completion_description`, `deliverables`,
            `actual_hours`, `impact_scope`, `delay_reported`, `delay_reason`,
            `quality_score`, `review_comment`, `reviewer_id`, `submitted_at`,
            `reviewed_at`, `rework_count`, `bonus_points`, `penalty_points`,
            `final_points`, `kpi_period`, `sort_order`
        )
        SELECT
            LEFT(CONCAT('M', w.`id`), 64),
            w.`id`,
            'MAIN',
            NULL,
            w.`title`,
            w.`description`,
            '主任务',
            NULL,
            NULL,
            NULL,
            0,
            NULL,
            'ASSIGN',
            CASE w.`status`
                WHEN 'COMPLETED' THEN 'COMPLETED'
                WHEN 'CANCELLED' THEN 'CANCELLED'
                WHEN 'IN_PROGRESS' THEN 'IN_PROGRESS'
                ELSE 'ASSIGNED'
            END,
            w.`publisher_id`,
            0,
            w.`deadline`,
            NULL,
            NULL,
            NULL,
            NULL,
            0,
            NULL,
            NULL,
            '历史工作自动生成主任务',
            w.`publisher_id`,
            CASE WHEN w.`status` = 'COMPLETED' THEN w.`update_time` ELSE NULL END,
            CASE WHEN w.`status` = 'COMPLETED' THEN w.`update_time` ELSE NULL END,
            0,
            0,
            0,
            0,
            NULL,
            0
        FROM `sys_work` w
        WHERE NOT EXISTS (
            SELECT 1 FROM `sys_work_task` mt
            WHERE mt.`work_id` = w.`id`
              AND mt.`task_role` = 'MAIN'
        );

        UPDATE `sys_work_task` t
        JOIN `sys_work_task` mt
          ON mt.`work_id` = t.`work_id`
         AND mt.`task_role` = 'MAIN'
        SET t.`task_role` = 'SUB',
            t.`parent_task_id` = mt.`id`
        WHERE t.`task_role` <> 'MAIN'
          AND (t.`parent_task_id` IS NULL OR t.`parent_task_id` = '');

        IF NOT EXISTS (
            SELECT 1 FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'sys_work_task'
              AND INDEX_NAME = 'idx_work_task_role'
        ) THEN
            ALTER TABLE `sys_work_task`
                ADD INDEX `idx_work_task_role` (`work_id`, `task_role`);
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'sys_work_task'
              AND INDEX_NAME = 'idx_parent_task_id'
        ) THEN
            ALTER TABLE `sys_work_task`
                ADD INDEX `idx_parent_task_id` (`parent_task_id`);
        END IF;
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V93();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V93;
