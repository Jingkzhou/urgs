-- Ensure table exists first!
CREATE TABLE IF NOT EXISTS `t_deploy_environment` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(50) NOT NULL,
    `code` VARCHAR(20) NOT NULL,
    `sso_id` BIGINT NOT NULL,
    `deploy_url` VARCHAR(500),
    `deploy_type` VARCHAR(20),
    `config` JSON,
    `created_at` DATETIME,
    `updated_at` DATETIME,
    `sort_order` INT DEFAULT 0 COMMENT '排序'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='部署环境';

-- Idempotent Add Column Procedure
DROP PROCEDURE IF EXISTS AddColumnIfNotExists;
DELIMITER $$
CREATE PROCEDURE AddColumnIfNotExists(
    IN tableName VARCHAR(64),
    IN colName VARCHAR(64),
    IN colDef VARCHAR(255)
)
BEGIN
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = tableName
        AND COLUMN_NAME = colName
    ) THEN
        SET @sql = CONCAT('ALTER TABLE `', tableName, '` ADD COLUMN `', colName, '` ', colDef);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$
DELIMITER ;

-- Apply to target tables
CALL AddColumnIfNotExists('sys_reg_table', 'sort_order', 'INT DEFAULT 0 COMMENT ''排序号''');
CALL AddColumnIfNotExists('sys_reg_element', 'sort_order', 'INT DEFAULT 0 COMMENT ''排序号''');
-- Note: t_deploy_environment might have been created above with sort_order, but if it existed before without it, this ensures it's added.
CALL AddColumnIfNotExists('t_deploy_environment', 'sort_order', 'INT DEFAULT 0 COMMENT ''排序''');

DROP PROCEDURE AddColumnIfNotExists;
