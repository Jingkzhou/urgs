DROP PROCEDURE IF EXISTS ExecuteIdempotent_V57;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V57()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    CREATE TABLE IF NOT EXISTS `sys_marketplace_point_rule` (
        `id` VARCHAR(64) NOT NULL COMMENT '主键ID',
        `task_type` VARCHAR(64) NOT NULL COMMENT '任务类型',
        `difficulty` VARCHAR(32) NOT NULL COMMENT '任务难度',
        `suggested_points` INT NOT NULL DEFAULT 0 COMMENT '建议积分',
        `description` TEXT COMMENT '规则说明',
        `enabled` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否启用',
        `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
        `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
        PRIMARY KEY (`id`),
        UNIQUE KEY `uk_point_rule_type_difficulty` (`task_type`, `difficulty`),
        KEY `idx_point_rule_enabled` (`enabled`, `task_type`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工作市场积分建议规则表';

    CREATE TABLE IF NOT EXISTS `sys_kpi_snapshot` (
        `id` VARCHAR(64) NOT NULL COMMENT '主键ID',
        `period` VARCHAR(16) NOT NULL COMMENT 'KPI周期YYYY-MM',
        `user_id` VARCHAR(64) NOT NULL COMMENT '用户ID',
        `user_name` VARCHAR(128) DEFAULT NULL COMMENT '用户名称',
        `completed_task_count` INT DEFAULT 0 COMMENT '完成任务数',
        `base_points` INT DEFAULT 0 COMMENT '基础积分',
        `final_points` INT DEFAULT 0 COMMENT '最终积分',
        `on_time_rate` DECIMAL(8,2) DEFAULT 0 COMMENT '准时率',
        `average_quality_score` DECIMAL(4,2) DEFAULT 0 COMMENT '平均质量分',
        `rework_count` INT DEFAULT 0 COMMENT '返工次数',
        `overdue_count` INT DEFAULT 0 COMMENT '逾期次数',
        `high_priority_task_count` INT DEFAULT 0 COMMENT '高优先级任务数',
        `active_task_count` INT DEFAULT 0 COMMENT '生成时进行中负载',
        `status` VARCHAR(32) DEFAULT 'LOCKED' COMMENT '快照状态',
        `generated_by` VARCHAR(64) DEFAULT NULL COMMENT '生成人ID',
        `generated_at` DATETIME DEFAULT NULL COMMENT '生成时间',
        `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
        `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
        PRIMARY KEY (`id`),
        UNIQUE KEY `uk_kpi_snapshot_period_user` (`period`, `user_id`),
        KEY `idx_kpi_snapshot_period_points` (`period`, `final_points`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工作市场KPI月度结算快照表';

    IF NOT EXISTS (SELECT 1 FROM `sys_marketplace_point_rule` WHERE `task_type` = '开发' AND `difficulty` = '简单') THEN
        INSERT INTO `sys_marketplace_point_rule` (`id`, `task_type`, `difficulty`, `suggested_points`, `description`)
        VALUES ('RULE_DEV_SIMPLE', '开发', '简单', 5, '小范围代码修改、简单页面或接口调整');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM `sys_marketplace_point_rule` WHERE `task_type` = '开发' AND `difficulty` = '中等') THEN
        INSERT INTO `sys_marketplace_point_rule` (`id`, `task_type`, `difficulty`, `suggested_points`, `description`)
        VALUES ('RULE_DEV_MEDIUM', '开发', '中等', 10, '常规功能开发、跨前后端联调或复杂表单流程');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM `sys_marketplace_point_rule` WHERE `task_type` = '开发' AND `difficulty` = '复杂') THEN
        INSERT INTO `sys_marketplace_point_rule` (`id`, `task_type`, `difficulty`, `suggested_points`, `description`)
        VALUES ('RULE_DEV_COMPLEX', '开发', '复杂', 20, '复杂模块、关键链路、跨系统集成或高风险改造');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM `sys_marketplace_point_rule` WHERE `task_type` = '测试' AND `difficulty` = '简单') THEN
        INSERT INTO `sys_marketplace_point_rule` (`id`, `task_type`, `difficulty`, `suggested_points`, `description`)
        VALUES ('RULE_TEST_SIMPLE', '测试', '简单', 3, '单点验证、回归截图或简单测试用例补充');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM `sys_marketplace_point_rule` WHERE `task_type` = '测试' AND `difficulty` = '中等') THEN
        INSERT INTO `sys_marketplace_point_rule` (`id`, `task_type`, `difficulty`, `suggested_points`, `description`)
        VALUES ('RULE_TEST_MEDIUM', '测试', '中等', 8, '完整流程验证、接口联调验证或缺陷复测');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM `sys_marketplace_point_rule` WHERE `task_type` = '测试' AND `difficulty` = '复杂') THEN
        INSERT INTO `sys_marketplace_point_rule` (`id`, `task_type`, `difficulty`, `suggested_points`, `description`)
        VALUES ('RULE_TEST_COMPLEX', '测试', '复杂', 15, '关键业务回归、自动化测试或多系统验证');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM `sys_marketplace_point_rule` WHERE `task_type` = '数据' AND `difficulty` = '简单') THEN
        INSERT INTO `sys_marketplace_point_rule` (`id`, `task_type`, `difficulty`, `suggested_points`, `description`)
        VALUES ('RULE_DATA_SIMPLE', '数据', '简单', 5, '简单SQL、数据核查或小范围数据修正');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM `sys_marketplace_point_rule` WHERE `task_type` = '数据' AND `difficulty` = '中等') THEN
        INSERT INTO `sys_marketplace_point_rule` (`id`, `task_type`, `difficulty`, `suggested_points`, `description`)
        VALUES ('RULE_DATA_MEDIUM', '数据', '中等', 12, '复杂SQL、指标口径开发或数据链路排查');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM `sys_marketplace_point_rule` WHERE `task_type` = '数据' AND `difficulty` = '复杂') THEN
        INSERT INTO `sys_marketplace_point_rule` (`id`, `task_type`, `difficulty`, `suggested_points`, `description`)
        VALUES ('RULE_DATA_COMPLEX', '数据', '复杂', 24, '复杂数据模型、跨源血缘分析或高风险数据修复');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM `sys_marketplace_point_rule` WHERE `task_type` = '文档' AND `difficulty` = '简单') THEN
        INSERT INTO `sys_marketplace_point_rule` (`id`, `task_type`, `difficulty`, `suggested_points`, `description`)
        VALUES ('RULE_DOC_SIMPLE', '文档', '简单', 3, '简单说明、变更记录或操作截图整理');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM `sys_marketplace_point_rule` WHERE `task_type` = '文档' AND `difficulty` = '中等') THEN
        INSERT INTO `sys_marketplace_point_rule` (`id`, `task_type`, `difficulty`, `suggested_points`, `description`)
        VALUES ('RULE_DOC_MEDIUM', '文档', '中等', 6, '技术方案、验收文档或上线说明');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM `sys_marketplace_point_rule` WHERE `task_type` = '文档' AND `difficulty` = '复杂') THEN
        INSERT INTO `sys_marketplace_point_rule` (`id`, `task_type`, `difficulty`, `suggested_points`, `description`)
        VALUES ('RULE_DOC_COMPLEX', '文档', '复杂', 10, '体系化方案、复盘材料或跨团队标准文档');
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V57();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V57;
