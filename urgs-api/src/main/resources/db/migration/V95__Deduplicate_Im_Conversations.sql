DROP PROCEDURE IF EXISTS ExecuteIdempotent_V95;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V95()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'im_conversation'
    ) THEN
        DELETE c
        FROM `im_conversation` c
        JOIN (
            SELECT `user_id`, `peer_id`, COALESCE(`chat_type`, 1) AS normalized_chat_type, MAX(`id`) AS keep_id
            FROM `im_conversation`
            GROUP BY `user_id`, `peer_id`, COALESCE(`chat_type`, 1)
            HAVING COUNT(*) > 1
        ) d
          ON c.`user_id` = d.`user_id`
         AND c.`peer_id` = d.`peer_id`
         AND COALESCE(c.`chat_type`, 1) = d.normalized_chat_type
         AND c.`id` <> d.keep_id;

        UPDATE `im_conversation`
        SET `chat_type` = 1
        WHERE `chat_type` IS NULL;

        IF EXISTS (
            SELECT 1 FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'im_conversation'
              AND INDEX_NAME = 'uk_user_peer_type'
              AND NON_UNIQUE = 1
        ) THEN
            ALTER TABLE `im_conversation`
                DROP INDEX `uk_user_peer_type`;
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'im_conversation'
              AND INDEX_NAME = 'uk_user_peer_type'
        ) THEN
            ALTER TABLE `im_conversation`
                ADD UNIQUE KEY `uk_user_peer_type` (`user_id`, `peer_id`, `chat_type`);
        END IF;
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V95();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V95;
