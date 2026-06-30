DROP PROCEDURE IF EXISTS ExecuteIdempotent_V92;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V92()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_work'
    ) THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'sys_work'
              AND COLUMN_NAME = 'application_department'
        ) THEN
            ALTER TABLE `sys_work`
                ADD COLUMN `application_department` VARCHAR(100) DEFAULT NULL COMMENT '申请部门' AFTER `requirement_number`;
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'sys_work'
              AND COLUMN_NAME = 'applicant_name'
        ) THEN
            ALTER TABLE `sys_work`
                ADD COLUMN `applicant_name` VARCHAR(100) DEFAULT NULL COMMENT '申请人' AFTER `application_department`;
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'sys_work'
              AND COLUMN_NAME = 'owning_system'
        ) THEN
            ALTER TABLE `sys_work`
                ADD COLUMN `owning_system` VARCHAR(100) DEFAULT NULL COMMENT '归属系统' AFTER `applicant_name`;
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'sys_work'
              AND COLUMN_NAME = 'primary_system'
        ) THEN
            ALTER TABLE `sys_work`
                ADD COLUMN `primary_system` TINYINT(1) DEFAULT 1 COMMENT '是否主系统' AFTER `owning_system`;
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'sys_work'
              AND COLUMN_NAME = 'primary_system_name'
        ) THEN
            ALTER TABLE `sys_work`
                ADD COLUMN `primary_system_name` VARCHAR(100) DEFAULT NULL COMMENT '主系统名称' AFTER `primary_system`;
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'sys_work'
              AND COLUMN_NAME = 'project_type'
        ) THEN
            ALTER TABLE `sys_work`
                ADD COLUMN `project_type` VARCHAR(20) DEFAULT NULL COMMENT '项目类型: 变更类/仅配合' AFTER `primary_system_name`;
        END IF;
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V92();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V92;
