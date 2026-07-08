DROP PROCEDURE IF EXISTS ExecuteIdempotent_V102;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V102()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_task_version_change_snapshot'
    ) THEN
        CREATE TABLE `sys_task_version_change_snapshot` (
            `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
            `task_id` VARCHAR(64) NOT NULL COMMENT '任务ID',
            `work_id` VARCHAR(64) DEFAULT NULL COMMENT '工作ID',
            `requirement_number` VARCHAR(100) DEFAULT NULL COMMENT '需求编号',
            `assignee_id` VARCHAR(64) DEFAULT NULL COMMENT '任务承接人ID',
            `reviewer_id` VARCHAR(64) DEFAULT NULL COMMENT '审核人ID',
            `repo_id` BIGINT DEFAULT NULL COMMENT 'Git仓库ID',
            `repo_name` VARCHAR(300) DEFAULT NULL COMMENT 'Git仓库名称',
            `pr_number` BIGINT DEFAULT NULL COMMENT '合并请求编号',
            `pr_title` VARCHAR(500) DEFAULT NULL COMMENT '合并请求标题',
            `pr_url` VARCHAR(1000) DEFAULT NULL COMMENT '合并请求地址',
            `source_branch` VARCHAR(300) DEFAULT NULL COMMENT '来源分支',
            `target_branch` VARCHAR(100) DEFAULT NULL COMMENT '目标分支',
            `state` VARCHAR(50) DEFAULT NULL COMMENT '合并请求状态',
            `merged` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否已合并',
            `merged_at` VARCHAR(64) DEFAULT NULL COMMENT '合并时间',
            `match_source` VARCHAR(50) DEFAULT NULL COMMENT '匹配依据',
            `commit_count` INT NOT NULL DEFAULT 0 COMMENT '提交数量',
            `file_count` INT NOT NULL DEFAULT 0 COMMENT '文件变更数量',
            `additions` INT NOT NULL DEFAULT 0 COMMENT '新增行数',
            `deletions` INT NOT NULL DEFAULT 0 COMMENT '删除行数',
            `snapshot_json` LONGTEXT NOT NULL COMMENT '审批通过时的PR提交和文件差异JSON快照',
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='任务版本变更快照';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_task_version_change_snapshot'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_task_version_change_snapshot'
          AND INDEX_NAME = 'uk_task_version_snapshot_pr'
    ) THEN
        ALTER TABLE `sys_task_version_change_snapshot`
            ADD UNIQUE KEY `uk_task_version_snapshot_pr` (`task_id`, `repo_id`, `pr_number`);
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_task_version_change_snapshot'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_task_version_change_snapshot'
          AND INDEX_NAME = 'idx_task_version_snapshot_work'
    ) THEN
        ALTER TABLE `sys_task_version_change_snapshot`
            ADD KEY `idx_task_version_snapshot_work` (`work_id`);
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_task_version_change_snapshot'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_task_version_change_snapshot'
          AND INDEX_NAME = 'idx_task_version_snapshot_requirement'
    ) THEN
        ALTER TABLE `sys_task_version_change_snapshot`
            ADD KEY `idx_task_version_snapshot_requirement` (`requirement_number`);
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V102();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V102;
