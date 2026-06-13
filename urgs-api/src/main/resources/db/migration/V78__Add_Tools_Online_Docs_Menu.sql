-- 工具箱与在线文档菜单权限初始化

DROP PROCEDURE IF EXISTS ExecuteIdempotent_V78;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V78()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (SELECT 1 FROM `sys_function` WHERE `code` = 'tools') THEN
        INSERT INTO `sys_function` (`code`, `name`, `type`, `path`, `parent_id`, `sort_order`, `enabled`)
        VALUES ('tools', '工具', 'menu', '/tools', NULL, 75, 1);
    END IF;

    SET @toolsParentId = (SELECT `id` FROM `sys_function` WHERE `code` = 'tools' LIMIT 1);

    IF NOT EXISTS (SELECT 1 FROM `sys_function` WHERE `code` = 'tools:online-docs') THEN
        INSERT INTO `sys_function` (`code`, `name`, `type`, `path`, `parent_id`, `sort_order`, `enabled`)
        VALUES ('tools:online-docs', '在线文档', 'menu', '/tools/online-docs', @toolsParentId, 10, 1);
    END IF;

    INSERT IGNORE INTO `sys_role_function` (`role_id`, `function_id`)
    SELECT 1, `id` FROM `sys_function` WHERE `code` IN ('tools', 'tools:online-docs');
END$$
DELIMITER ;
CALL ExecuteIdempotent_V78();
DROP PROCEDURE ExecuteIdempotent_V78;
