DROP PROCEDURE IF EXISTS ExecuteIdempotent_V101;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V101()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_user_git_identity'
    ) THEN
        CREATE TABLE `sys_user_git_identity` (
            `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
            `user_id` BIGINT NOT NULL COMMENT 'URGS用户ID',
            `platform` VARCHAR(20) NOT NULL DEFAULT 'GITLAB' COMMENT 'Git平台',
            `git_username` VARCHAR(100) DEFAULT NULL COMMENT 'Git用户名',
            `git_email` VARCHAR(200) DEFAULT NULL COMMENT 'Git提交邮箱',
            `git_user_id` VARCHAR(100) DEFAULT NULL COMMENT 'Git平台用户ID',
            `enabled` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否启用',
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户Git身份绑定';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_user_git_identity'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_user_git_identity'
          AND INDEX_NAME = 'uk_user_git_identity_user_platform'
    ) THEN
        ALTER TABLE `sys_user_git_identity`
            ADD UNIQUE KEY `uk_user_git_identity_user_platform` (`user_id`, `platform`);
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_user_git_identity'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_user_git_identity'
          AND INDEX_NAME = 'idx_user_git_identity_username'
    ) THEN
        ALTER TABLE `sys_user_git_identity`
            ADD KEY `idx_user_git_identity_username` (`git_username`);
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_user_git_identity'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_user_git_identity'
          AND INDEX_NAME = 'idx_user_git_identity_email'
    ) THEN
        ALTER TABLE `sys_user_git_identity`
            ADD KEY `idx_user_git_identity_email` (`git_email`);
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V101();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V101;
