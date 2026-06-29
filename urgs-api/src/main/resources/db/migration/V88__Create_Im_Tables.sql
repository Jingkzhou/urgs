DROP PROCEDURE IF EXISTS ExecuteIdempotent_V88;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V88()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'im_user'
    ) THEN
        CREATE TABLE `im_user` (
            `user_id` BIGINT NOT NULL COMMENT '关联主系统用户ID',
            `wx_id` VARCHAR(64) UNIQUE COMMENT 'IM显示账号',
            `avatar_url` VARCHAR(255) COMMENT '头像地址',
            `region` VARCHAR(100) COMMENT '地区',
            `signature` VARCHAR(255) COMMENT '个性签名',
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`user_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM用户扩展信息';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'im_friendship'
    ) THEN
        CREATE TABLE `im_friendship` (
            `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
            `user_id` BIGINT NOT NULL COMMENT '所属用户ID',
            `friend_id` BIGINT NOT NULL COMMENT '好友用户ID',
            `remark` VARCHAR(100) COMMENT '备注名',
            `status` TINYINT DEFAULT 0 COMMENT '0:正常,1:删除,2:拉黑',
            `source` TINYINT COMMENT '来源',
            `tags` JSON COMMENT '标签',
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `uk_user_friend` (`user_id`, `friend_id`),
            KEY `idx_friend_id` (`friend_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM好友关系';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'im_friend_request'
    ) THEN
        CREATE TABLE `im_friend_request` (
            `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
            `sender_id` BIGINT NOT NULL,
            `receiver_id` BIGINT NOT NULL,
            `verify_msg` VARCHAR(255) COMMENT '验证消息',
            `status` TINYINT DEFAULT 0 COMMENT '0:待处理,1:已同意,2:已拒绝,3:已过期',
            `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
            KEY `idx_receiver_status` (`receiver_id`, `status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM好友申请';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'im_group'
    ) THEN
        CREATE TABLE `im_group` (
            `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
            `owner_id` BIGINT NOT NULL,
            `name` VARCHAR(100) NOT NULL,
            `notice` TEXT,
            `avatar_url` VARCHAR(255),
            `invite_mode` TINYINT DEFAULT 0 COMMENT '0:任意成员可邀请,1:仅管理员或群主',
            `member_count` INT DEFAULT 1,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM群聊';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'im_group_member'
    ) THEN
        CREATE TABLE `im_group_member` (
            `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
            `group_id` BIGINT NOT NULL,
            `user_id` BIGINT NOT NULL,
            `role` TINYINT DEFAULT 0 COMMENT '0:成员,1:管理员,2:群主',
            `alias` VARCHAR(100) COMMENT '群昵称',
            `is_muted` BOOLEAN DEFAULT FALSE,
            `is_top` BOOLEAN DEFAULT FALSE,
            `join_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `uk_group_user` (`group_id`, `user_id`),
            KEY `idx_user_group` (`user_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM群成员';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'im_message'
    ) THEN
        CREATE TABLE `im_message` (
            `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
            `conversation_id` VARCHAR(100) NOT NULL COMMENT '会话ID',
            `sender_id` BIGINT NOT NULL,
            `receiver_id` BIGINT COMMENT '私聊接收方',
            `group_id` BIGINT COMMENT '群聊ID',
            `msg_type` TINYINT NOT NULL COMMENT '1:文本,2:图片,3:音频,4:视频,5:撤回,6:系统',
            `content` TEXT COMMENT '消息内容或JSON元数据',
            `refer_msg_id` BIGINT COMMENT '引用消息ID',
            `send_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
            KEY `idx_conversation_time` (`conversation_id`, `send_time`),
            KEY `idx_sender` (`sender_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM消息';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'im_conversation'
    ) THEN
        CREATE TABLE `im_conversation` (
            `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
            `user_id` BIGINT NOT NULL,
            `peer_id` BIGINT NOT NULL COMMENT '好友ID或群ID',
            `chat_type` TINYINT NOT NULL COMMENT '1:私聊,2:群聊',
            `last_msg_id` BIGINT,
            `last_msg_content` TEXT COMMENT '最后一条消息预览',
            `last_msg_time` DATETIME,
            `unread_count` INT DEFAULT 0,
            `is_top` BOOLEAN DEFAULT FALSE,
            `is_hidden` BOOLEAN DEFAULT FALSE,
            `name` VARCHAR(255) COMMENT '会话名称',
            `avatar` VARCHAR(512) COMMENT '会话头像',
            UNIQUE KEY `uk_user_peer_type` (`user_id`, `peer_id`, `chat_type`),
            KEY `idx_user_time` (`user_id`, `last_msg_time`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM会话';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'im_conversation'
    ) THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'im_conversation'
              AND COLUMN_NAME = 'chat_type'
        ) THEN
            ALTER TABLE `im_conversation`
                ADD COLUMN `chat_type` TINYINT NOT NULL DEFAULT 1 COMMENT '1:私聊,2:群聊' AFTER `peer_id`;
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'im_conversation'
              AND COLUMN_NAME = 'name'
        ) THEN
            ALTER TABLE `im_conversation`
                ADD COLUMN `name` VARCHAR(255) COMMENT '会话名称' AFTER `is_hidden`;
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'im_conversation'
              AND COLUMN_NAME = 'avatar'
        ) THEN
            ALTER TABLE `im_conversation`
                ADD COLUMN `avatar` VARCHAR(512) COMMENT '会话头像' AFTER `name`;
        END IF;

        IF EXISTS (
            SELECT 1 FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'im_conversation'
              AND COLUMN_NAME = 'last_msg_content'
              AND DATA_TYPE <> 'text'
        ) THEN
            ALTER TABLE `im_conversation`
                MODIFY COLUMN `last_msg_content` TEXT COMMENT '最后一条消息预览';
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

        IF NOT EXISTS (
            SELECT 1 FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'im_conversation'
              AND INDEX_NAME = 'idx_user_time'
        ) THEN
            ALTER TABLE `im_conversation`
                ADD KEY `idx_user_time` (`user_id`, `last_msg_time`);
        END IF;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'im_group_member'
    ) THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'im_group_member'
              AND INDEX_NAME = 'uk_group_user'
        ) THEN
            ALTER TABLE `im_group_member`
                ADD UNIQUE KEY `uk_group_user` (`group_id`, `user_id`);
        END IF;
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V88();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V88;
