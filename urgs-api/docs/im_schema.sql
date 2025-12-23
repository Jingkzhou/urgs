-- IM System Schema

-- 1. Users (Extended)
-- Ideally we extend the existing user table, but for IM specifics/separation:
CREATE TABLE IF NOT EXISTS `im_user` (
  `user_id` BIGINT NOT NULL COMMENT 'Links to main system user ID',
  `wx_id` VARCHAR(64) UNIQUE COMMENT 'WeChat ID, unique, modifiable once',
  `avatar_url` VARCHAR(255) COMMENT 'Avatar URL',
  `region` VARCHAR(100) COMMENT 'Region',
  `signature` VARCHAR(255) COMMENT 'Personal signature',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM User Extended Info';

-- 2. Friendship
CREATE TABLE IF NOT EXISTS `im_friendship` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `user_id` BIGINT NOT NULL COMMENT 'Owner ID',
  `friend_id` BIGINT NOT NULL COMMENT 'Friend ID',
  `remark` VARCHAR(100) COMMENT 'Remark name',
  `status` TINYINT DEFAULT 0 COMMENT '0:Normal, 1:Deleted, 2:Blocked',
  `source` TINYINT COMMENT 'Source: Search, QRCode, Group, Card',
  `tags` JSON COMMENT 'Tags like Family, Colleague',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_user_friend` (`user_id`, `friend_id`),
  INDEX `idx_friend_id` (`friend_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Friendship Relations';

-- 3. Friend Requests
CREATE TABLE IF NOT EXISTS `im_friend_request` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `sender_id` BIGINT NOT NULL,
  `receiver_id` BIGINT NOT NULL,
  `verify_msg` VARCHAR(255) COMMENT 'Verification message',
  `status` TINYINT DEFAULT 0 COMMENT '0:Pending, 1:Accepted, 2:Rejected, 3:Expired',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_receiver_status` (`receiver_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Friend Requests';

-- 4. Groups
CREATE TABLE IF NOT EXISTS `im_group` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `owner_id` BIGINT NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `notice` TEXT,
  `avatar_url` VARCHAR(255),
  `invite_mode` TINYINT DEFAULT 0 COMMENT '0:Any, 1:Admin/Owner only',
  `member_count` INT DEFAULT 1,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Chat Groups';

-- 5. Group Members
CREATE TABLE IF NOT EXISTS `im_group_member` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `group_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL,
  `role` TINYINT DEFAULT 0 COMMENT '0:Member, 1:Admin, 2:Owner',
  `alias` VARCHAR(100) COMMENT 'Group nickname',
  `is_muted` BOOLEAN DEFAULT FALSE,
  `is_top` BOOLEAN DEFAULT FALSE,
  `join_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_group_user` (`group_id`, `user_id`),
  INDEX `idx_user_group` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Group Members';

-- 6. Messages
CREATE TABLE IF NOT EXISTS `im_message` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `conversation_id` VARCHAR(100) NOT NULL COMMENT 'Derived ID for query optimization',
  `sender_id` BIGINT NOT NULL,
  `receiver_id` BIGINT COMMENT 'Null if group chat',
  `group_id` BIGINT COMMENT 'Null if private chat',
  `msg_type` TINYINT NOT NULL COMMENT '1:Text, 2:Image, 3:Audio, 4:Video, 5:Recall, 6:System',
  `content` TEXT COMMENT 'Content or JSON metadata',
  `refer_msg_id` BIGINT COMMENT 'Reply functionality',
  `send_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_conversation_time` (`conversation_id`, `send_time`),
  INDEX `idx_sender` (`sender_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Chat Messages';

-- 7. Conversations (Inbox/Sessions)
CREATE TABLE IF NOT EXISTS `im_conversation` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `user_id` BIGINT NOT NULL,
  `peer_id` BIGINT NOT NULL COMMENT 'Friend ID or Group ID',
  `chat_type` TINYINT NOT NULL COMMENT '1:Private, 2:Group',
  `last_msg_id` BIGINT,
  `last_msg_content` VARCHAR(255) COMMENT 'Preview text',
  `last_msg_time` DATETIME,
  `unread_count` INT DEFAULT 0,
  `is_top` BOOLEAN DEFAULT FALSE,
  `is_hidden` BOOLEAN DEFAULT FALSE,
  UNIQUE KEY `uk_user_peer_type` (`user_id`, `peer_id`, `chat_type`),
  INDEX `idx_user_time` (`user_id`, `last_msg_time` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='User Sessions/Inbox';
