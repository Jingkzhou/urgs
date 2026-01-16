-- V20__Create_Lineage_Analysis_Record_Table.sql

CREATE TABLE IF NOT EXISTS `t_lineage_analysis_record` (
    `id` VARCHAR(64) NOT NULL COMMENT '主键ID',
    `repo_id` BIGINT NOT NULL COMMENT 'Git仓库ID',
    `ref` VARCHAR(255) DEFAULT NULL COMMENT 'Git引用(分支/标签)',
    `commit_sha` VARCHAR(64) DEFAULT NULL COMMENT 'Git提交SHA',
    `paths` TEXT COMMENT '分析路径列表(JSON)',
    `version_id` VARCHAR(64) DEFAULT NULL COMMENT '分析生成的版本ID',
    `default_user` VARCHAR(255) DEFAULT NULL COMMENT '默认Schema用户',
    `language` VARCHAR(50) DEFAULT 'oracle' COMMENT 'SQL方言',
    `status` VARCHAR(20) DEFAULT 'PENDING' COMMENT '状态: PENDING, RUNNING, SUCCESS, FAILED',
    `error` TEXT COMMENT '错误信息',
    `start_time` DATETIME DEFAULT NULL COMMENT '开始时间',
    `end_time` DATETIME DEFAULT NULL COMMENT '结束时间',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_repo_status` (`repo_id`, `status`),
    KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='血缘分析记录表';
