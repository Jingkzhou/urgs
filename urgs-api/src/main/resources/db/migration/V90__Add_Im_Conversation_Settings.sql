DROP PROCEDURE IF EXISTS ExecuteIdempotent_V90;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V90()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'im_conversation'
    ) THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'im_conversation'
              AND COLUMN_NAME = 'is_muted'
        ) THEN
            ALTER TABLE `im_conversation`
                ADD COLUMN `is_muted` BOOLEAN NOT NULL DEFAULT FALSE COMMENT '是否消息免打扰' AFTER `is_top`;
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'im_conversation'
              AND COLUMN_NAME = 'cleared_before_msg_id'
        ) THEN
            ALTER TABLE `im_conversation`
                ADD COLUMN `cleared_before_msg_id` BIGINT DEFAULT NULL COMMENT '当前用户已清空到的消息ID' AFTER `is_hidden`;
        END IF;
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V90();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V90;
