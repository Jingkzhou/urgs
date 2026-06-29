DROP PROCEDURE IF EXISTS ExecuteIdempotent_V89;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V89()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'im_message'
          AND COLUMN_NAME = 'msg_type'
    ) THEN
        ALTER TABLE `im_message`
            MODIFY COLUMN `msg_type` TINYINT NOT NULL COMMENT '1:文本,2:图片,3:音频,4:视频,5:撤回,6:系统,7:文件';
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V89();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V89;
