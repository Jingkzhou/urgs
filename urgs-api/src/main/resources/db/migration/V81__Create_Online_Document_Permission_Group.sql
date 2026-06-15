DROP PROCEDURE IF EXISTS add_online_document_permission_group_tables;

DELIMITER $$
CREATE PROCEDURE add_online_document_permission_group_tables()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'online_document_permission_group'
    ) THEN
        CREATE TABLE online_document_permission_group (
            id BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
            owner_user_id BIGINT NOT NULL COMMENT '组所有者用户ID',
            name VARCHAR(100) NOT NULL COMMENT '组名称',
            description VARCHAR(500) DEFAULT NULL COMMENT '组描述',
            create_time DATETIME NOT NULL COMMENT '创建时间',
            update_time DATETIME NOT NULL COMMENT '更新时间',
            PRIMARY KEY (id),
            KEY idx_online_doc_perm_group_owner (owner_user_id, update_time),
            UNIQUE KEY uk_online_doc_perm_group_owner_name (owner_user_id, name)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='在线文档常用授权组';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'online_document_permission_group_member'
    ) THEN
        CREATE TABLE online_document_permission_group_member (
            id BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
            group_id BIGINT NOT NULL COMMENT '授权组ID',
            user_id BIGINT NOT NULL COMMENT '组成员用户ID',
            create_time DATETIME NOT NULL COMMENT '创建时间',
            PRIMARY KEY (id),
            UNIQUE KEY uk_online_doc_perm_group_member (group_id, user_id),
            KEY idx_online_doc_perm_group_member_user (user_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='在线文档常用授权组成员';
    END IF;
END$$
DELIMITER ;

CALL add_online_document_permission_group_tables();
DROP PROCEDURE IF EXISTS add_online_document_permission_group_tables;
