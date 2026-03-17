-- ----------------------------
-- 工作市场模块数据表
-- ----------------------------

-- 工作表
CREATE TABLE IF NOT EXISTS `sys_work` (
    `id` VARCHAR(64) PRIMARY KEY COMMENT '雪花ID',
    `title` VARCHAR(200) NOT NULL COMMENT '工作标题',
    `description` TEXT COMMENT '详细描述',
    `category` VARCHAR(100) COMMENT '分类标签',
    `priority` VARCHAR(20) DEFAULT 'P2' COMMENT '优先级: P0/P1/P2/P3',
    `total_points` INT DEFAULT 0 COMMENT '总积分(预计总工时)',
    `status` VARCHAR(20) NOT NULL COMMENT '状态: DRAFT/PUBLISHED/IN_PROGRESS/COMPLETED/CANCELLED',
    `publisher_id` VARCHAR(64) NOT NULL COMMENT '发布者',
    `deadline` DATETIME COMMENT '截止日期',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工作主表';

-- 任务表 (工作的子项)
CREATE TABLE IF NOT EXISTS `sys_work_task` (
    `id` VARCHAR(64) PRIMARY KEY COMMENT '雪花ID',
    `work_id` VARCHAR(64) NOT NULL COMMENT '所属工作ID',
    `title` VARCHAR(200) NOT NULL COMMENT '任务标题',
    `description` TEXT COMMENT '任务描述',
    `required_skills` VARCHAR(255) COMMENT '所需技能标签,逗号分隔',
    `points` INT DEFAULT 0 COMMENT '积分(预计工时)',
    `assign_mode` VARCHAR(20) NOT NULL COMMENT '分配模式: OPEN/COMPETE/ASSIGN',
    `status` VARCHAR(20) NOT NULL COMMENT '状态: OPEN/APPLIED/ASSIGNED/IN_PROGRESS/REVIEW/COMPLETED/REJECTED',
    `assignee_id` VARCHAR(64) COMMENT '当前负责人',
    `max_applicants` INT DEFAULT 0 COMMENT '最大申请人数(竞争模式)',
    `deadline` DATETIME COMMENT '任务截止日期',
    `sort_order` INT DEFAULT 0 COMMENT '排序',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX `idx_work_id` (`work_id`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工作任务表';

-- 任务申请表
CREATE TABLE IF NOT EXISTS `sys_task_application` (
    `id` VARCHAR(64) PRIMARY KEY COMMENT '雪花ID',
    `task_id` VARCHAR(64) NOT NULL COMMENT '任务ID',
    `applicant_id` VARCHAR(64) NOT NULL COMMENT '申请者ID',
    `message` TEXT COMMENT '申请说明',
    `status` VARCHAR(20) NOT NULL COMMENT '状态: PENDING/ACCEPTED/REJECTED/WITHDRAWN',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '申请时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '处理时间',
    INDEX `idx_task_id` (`task_id`),
    UNIQUE KEY `uk_task_applicant` (`task_id`, `applicant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='任务申请竞标表';

-- 任务评论表
CREATE TABLE IF NOT EXISTS `sys_task_comment` (
    `id` VARCHAR(64) PRIMARY KEY COMMENT '雪花ID',
    `task_id` VARCHAR(64) NOT NULL COMMENT '任务ID',
    `user_id` VARCHAR(64) NOT NULL COMMENT '评论者ID',
    `content` TEXT NOT NULL COMMENT '评论内容',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX `idx_task_id_time` (`task_id`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='任务评论表';

-- 任务操作日志表
CREATE TABLE IF NOT EXISTS `sys_task_log` (
    `id` VARCHAR(64) PRIMARY KEY COMMENT '雪花ID',
    `task_id` VARCHAR(64) NOT NULL COMMENT '任务ID',
    `operator_id` VARCHAR(64) NOT NULL COMMENT '操作者ID',
    `action` VARCHAR(50) NOT NULL COMMENT '操作类型',
    `detail` VARCHAR(500) COMMENT '操作详情',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX `idx_task_id_time` (`task_id`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='任务操作日志表';
