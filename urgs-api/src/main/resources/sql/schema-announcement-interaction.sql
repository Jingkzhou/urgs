CREATE TABLE IF NOT EXISTS sys_announcement_read (
    id VARCHAR(32) PRIMARY KEY,
    announcement_id VARCHAR(32) NOT NULL,
    user_id VARCHAR(50) NOT NULL,
    read_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_announcement_user (announcement_id, user_id)
) COMMENT='Announcement Read Status';

CREATE TABLE IF NOT EXISTS sys_announcement_comment (
    id VARCHAR(32) PRIMARY KEY,
    announcement_id VARCHAR(32) NOT NULL,
    user_id VARCHAR(50) NOT NULL,
    content TEXT,
    parent_id VARCHAR(32) DEFAULT NULL COMMENT 'Parent comment ID for replies',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_announcement (announcement_id)
) COMMENT='Announcement Comments';
