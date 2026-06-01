DROP PROCEDURE IF EXISTS ExecuteIdempotent_V73;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V73()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    CREATE TABLE IF NOT EXISTS `t_ai_agent_app_skill` (
        `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
        `app_code` VARCHAR(64) NOT NULL COMMENT 'Agent App CLI编码',
        `name` VARCHAR(128) NOT NULL COMMENT '技能名称',
        `code` VARCHAR(128) NOT NULL COMMENT '技能编码',
        `description` VARCHAR(512) DEFAULT NULL COMMENT '技能描述',
        `instruction` TEXT DEFAULT NULL COMMENT '技能调用指令',
        `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态：0 禁用，1 启用',
        `sort_order` INT NOT NULL DEFAULT 0 COMMENT '排序号',
        `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
        `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
        PRIMARY KEY (`id`),
        UNIQUE KEY `uk_agent_app_skill_app_code` (`app_code`, `code`),
        KEY `idx_agent_app_skill_status` (`app_code`, `status`, `sort_order`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Agent App技能表';
END$$
DELIMITER ;
CALL ExecuteIdempotent_V73();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V73;
