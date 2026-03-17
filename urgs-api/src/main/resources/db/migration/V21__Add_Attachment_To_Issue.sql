DROP PROCEDURE IF EXISTS ExecuteIdempotent_V21;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V21()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

-- Add attachment columns to sys_issue
ALTER TABLE `sys_issue` ADD COLUMN `attachment_path` VARCHAR(500) COMMENT '附件存储路径';
ALTER TABLE `sys_issue` ADD COLUMN `attachment_name` VARCHAR(255) COMMENT '附件原始名称';


END$$
DELIMITER ;
CALL ExecuteIdempotent_V21();
DROP PROCEDURE ExecuteIdempotent_V21;
