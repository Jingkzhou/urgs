DROP PROCEDURE IF EXISTS add_online_document_permission_table;

DELIMITER $$
CREATE PROCEDURE add_online_document_permission_table()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'online_document_permission'
    ) THEN
        CREATE TABLE online_document_permission (
            id BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
            document_id BIGINT NOT NULL COMMENT '文档ID',
            user_id BIGINT NOT NULL COMMENT '被授权用户ID',
            create_by BIGINT NOT NULL COMMENT '授权人ID',
            create_time DATETIME NOT NULL COMMENT '授权时间',
            PRIMARY KEY (id),
            UNIQUE KEY uk_online_document_permission_user (document_id, user_id),
            KEY idx_online_document_permission_user (user_id),
            KEY idx_online_document_permission_document (document_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='在线文档授权';
    END IF;
END$$
DELIMITER ;

CALL add_online_document_permission_table();
DROP PROCEDURE IF EXISTS add_online_document_permission_table;
