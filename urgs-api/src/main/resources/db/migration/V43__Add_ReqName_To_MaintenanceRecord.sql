-- V43: 为维护记录表添加需求名称字段
DROP PROCEDURE IF EXISTS upgrade_v43_add_req_name;

DELIMITER $$
CREATE PROCEDURE upgrade_v43_add_req_name()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'maintenance_record'
          AND COLUMN_NAME = 'req_name'
    ) THEN
        ALTER TABLE maintenance_record ADD COLUMN req_name VARCHAR(255) DEFAULT NULL COMMENT '需求名称' AFTER req_id;
    END IF;
END $$
DELIMITER ;

CALL upgrade_v43_add_req_name();
DROP PROCEDURE IF EXISTS upgrade_v43_add_req_name;
