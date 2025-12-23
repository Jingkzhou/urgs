-- 任务主题表
CREATE TABLE IF NOT EXISTS t_task_subject (
    subject_id VARCHAR(50) PRIMARY KEY COMMENT '主题ID',
    system_id VARCHAR(50) NOT NULL COMMENT '系统ID',
    system_name VARCHAR(100) NOT NULL COMMENT '系统名称',
    status INT DEFAULT 1 COMMENT '状态 1:启用 0:停用',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
);

-- 任务执行状态表
CREATE TABLE IF NOT EXISTS t_task_execution_status (
    status_id VARCHAR(50) PRIMARY KEY COMMENT '状态ID',
    subject_id VARCHAR(50) NOT NULL COMMENT '关联主题ID',
    total_count INT DEFAULT 0 COMMENT '总任务数',
    completed_count INT DEFAULT 0 COMMENT '完成数',
    in_progress_count INT DEFAULT 0 COMMENT '进行中数',
    not_started_count INT DEFAULT 0 COMMENT '未开始数',
    failed_count INT DEFAULT 0 COMMENT '失败数',
    progress_percentage DECIMAL(5, 2) DEFAULT 0.00 COMMENT '进度百分比',
    task_status VARCHAR(20) COMMENT '任务状态',
    start_time DATETIME COMMENT '开始时间',
    update_time DATETIME COMMENT '更新时间',
    FOREIGN KEY (subject_id) REFERENCES t_task_subject(subject_id)
);
