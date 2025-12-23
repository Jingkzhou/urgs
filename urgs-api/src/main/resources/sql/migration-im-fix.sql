-- Expand last_msg_content to support longer messages (Long Text)
ALTER TABLE im_conversation MODIFY COLUMN last_msg_content TEXT COMMENT 'Preview of last message';
