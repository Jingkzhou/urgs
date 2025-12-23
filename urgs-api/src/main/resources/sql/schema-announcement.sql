CREATE TABLE IF NOT EXISTS sys_announcement (
    id VARCHAR(32) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    type VARCHAR(50),
    category VARCHAR(50),
    content TEXT,
    attachments TEXT,
    systems TEXT,
    status INT DEFAULT 0 COMMENT '0:Draft, 1:Published',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    create_by VARCHAR(50)
) COMMENT='Announcements and Notices';
