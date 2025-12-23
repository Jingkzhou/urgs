-- 问题登记表
CREATE TABLE IF NOT EXISTS sys_issue (
    id VARCHAR(64) PRIMARY KEY COMMENT '问题ID',
    title VARCHAR(500) NOT NULL COMMENT '问题标题',
    description TEXT COMMENT '问题描述',
    solution TEXT COMMENT '解决方案',
    `system` VARCHAR(100) COMMENT '涉及系统',  -- 修复点：加上了反引号
    occur_time DATETIME COMMENT '发生时间',
    reporter VARCHAR(100) COMMENT '提出人',
    resolve_time DATETIME COMMENT '解决时间',
    handler VARCHAR(100) COMMENT '处理人',
    issue_type VARCHAR(50) COMMENT '问题类型：批量任务处理/报送支持/数据查询',
    status VARCHAR(20) DEFAULT '新建' COMMENT '状态：新建/处理中/完成/遗留',
    work_hours DECIMAL(10,2) DEFAULT 0 COMMENT '工时（小时）',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    create_by VARCHAR(100) COMMENT '创建人',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='生产问题登记表';

-- 添加索引
CREATE INDEX idx_issue_status ON sys_issue(status);
CREATE INDEX idx_issue_type ON sys_issue(issue_type);
CREATE INDEX idx_issue_create_time ON sys_issue(create_time);