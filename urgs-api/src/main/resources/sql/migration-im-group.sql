ALTER TABLE im_conversation ADD COLUMN chat_type INT DEFAULT 1 COMMENT '1: Private, 2: Group';
ALTER TABLE im_conversation ADD COLUMN name VARCHAR(255) COMMENT 'Conversation Name (Group)';
ALTER TABLE im_conversation ADD COLUMN avatar VARCHAR(512) COMMENT 'Conversation Avatar';
