-- 1. 新增 is_desensitized 字段（是否脱敏，0=否，1=是）
DROP PROCEDURE IF EXISTS add_is_desensitized;
DELIMITER //
CREATE PROCEDURE add_is_desensitized()
BEGIN
    DECLARE CONTINUE HANDLER FOR 1060 BEGIN END;
    ALTER TABLE reg_element ADD COLUMN is_desensitized INT DEFAULT 0 COMMENT '是否脱敏(0否1是)';
END //
DELIMITER ;
CALL add_is_desensitized();
DROP PROCEDURE IF EXISTS add_is_desensitized;

-- 2. 将 length 字段从 INT 改为 VARCHAR(50)
ALTER TABLE reg_element MODIFY COLUMN `length` VARCHAR(50) DEFAULT NULL COMMENT '字段长度';
