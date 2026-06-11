DROP PROCEDURE IF EXISTS ExecuteIdempotent_V77;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V77()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_infrastructure_system_manual'
    ) THEN
        CREATE TABLE `t_infrastructure_system_manual` (
            `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
            `app_system_id` BIGINT NOT NULL COMMENT '关联应用系统ID',
            `title` VARCHAR(200) NOT NULL COMMENT '手册标题',
            `file_name` VARCHAR(255) NOT NULL COMMENT '原始文件名',
            `file_url` VARCHAR(500) NOT NULL COMMENT '文件访问地址',
            `file_size` BIGINT DEFAULT NULL COMMENT '文件大小（字节）',
            `description` TEXT DEFAULT NULL COMMENT '备注说明',
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`),
            KEY `idx_infra_manual_system` (`app_system_id`),
            KEY `idx_infra_manual_created_at` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='基础设施系统运维手册';
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V77();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V77;
