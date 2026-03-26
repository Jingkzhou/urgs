-- 新增 desensitize_type 字段（脱敏字段类型）
DROP PROCEDURE IF EXISTS add_desensitize_type;

DELIMITER $$
CREATE PROCEDURE add_desensitize_type()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'reg_element'
          AND COLUMN_NAME = 'desensitize_type'
    ) THEN
        ALTER TABLE reg_element ADD COLUMN desensitize_type VARCHAR(50) DEFAULT NULL COMMENT '脱敏字段类型(公司名称/姓名/统一社会信用代码/地址/身份证号/电话号/邮箱)';
    END IF;
END $$
DELIMITER ;

CALL add_desensitize_type();
DROP PROCEDURE IF EXISTS add_desensitize_type;
