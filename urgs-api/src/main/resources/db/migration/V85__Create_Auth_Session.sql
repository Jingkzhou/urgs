DROP PROCEDURE IF EXISTS ExecuteIdempotent_V85;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V85()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_auth_session'
    ) THEN
        CREATE TABLE `sys_auth_session` (
            `token` VARCHAR(64) NOT NULL COMMENT '登录令牌',
            `user_id` BIGINT NOT NULL COMMENT '用户ID',
            `expires_at` DATETIME NOT NULL COMMENT '过期时间',
            `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`token`),
            KEY `idx_auth_session_user_id` (`user_id`),
            KEY `idx_auth_session_expires_at` (`expires_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='登录会话';
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V85();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V85;
