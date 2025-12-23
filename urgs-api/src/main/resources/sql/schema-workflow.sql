-- 1. 任务依赖关系表 (DAG 核心表)
CREATE TABLE IF NOT EXISTS `sys_job_dependency` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `workflow_id` bigint(20) NOT NULL COMMENT '工作流 ID',
  `parent_job_name` varchar(100) NOT NULL COMMENT '父任务名称',
  `child_job_name` varchar(100) NOT NULL COMMENT '子任务名称',
  `project_id` bigint(20) DEFAULT NULL COMMENT '项目 ID',
  PRIMARY KEY (`id`),
  KEY `idx_parent` (`parent_job_name`), -- 用于父任务完成后，查找后续子任务
  KEY `idx_child` (`child_job_name`)    -- 用于检查当前任务的所有父任务是否已完成
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工作流任务依赖关系表';

-- 2. 任务执行日志表 (用于依赖汇聚检查)
CREATE TABLE IF NOT EXISTS `sys_job_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(100) NOT NULL COMMENT '任务名称',
  `batch_id` varchar(50) NOT NULL COMMENT '批次 ID (例如 20231128100000)',
  `status` int(1) NOT NULL COMMENT '状态 (0:失败, 1:成功)',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_check` (`job_name`, `batch_id`) -- 高频查询，用于检查前置依赖的汇聚情况
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='任务执行日志表';