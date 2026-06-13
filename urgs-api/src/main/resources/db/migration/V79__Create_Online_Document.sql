DROP PROCEDURE IF EXISTS add_online_document_table;

DELIMITER $$
CREATE PROCEDURE add_online_document_table()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'online_document'
    ) THEN
        CREATE TABLE online_document (
            id BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
            user_id BIGINT NOT NULL COMMENT '用户ID',
            title VARCHAR(200) NOT NULL COMMENT '文档标题',
            file_url VARCHAR(500) NOT NULL COMMENT '文件访问地址',
            file_name VARCHAR(255) NOT NULL COMMENT '原始文件名',
            file_size BIGINT DEFAULT NULL COMMENT '文件大小（字节）',
            create_time DATETIME NOT NULL COMMENT '创建时间',
            update_time DATETIME NOT NULL COMMENT '更新时间',
            PRIMARY KEY (id),
            KEY idx_online_document_user_update (user_id, update_time),
            KEY idx_online_document_title (title)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='在线文档';
    END IF;
END$$
DELIMITER ;

CALL add_online_document_table();
DROP PROCEDURE IF EXISTS add_online_document_table;
