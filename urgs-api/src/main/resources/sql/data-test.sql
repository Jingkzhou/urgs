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

-- 测试数据装载脚本，可在本地环境执行（MySQL）
-- 执行前请确认数据库连接为测试库

-- 机构
INSERT IGNORE INTO sys_org (id, name, code, type, type_name, status, parent_id, order_num) VALUES
(1, '吉林银行总行', 'JLB_HEAD', 'HEAD', '总行', 'active', 'root', 1),
(2, '长春分行', 'JLB_CC', 'BRANCH', '一级分行', 'active', '1', 10),
(3, '吉林市分行', 'JLB_JL', 'BRANCH', '一级分行', 'active', '1', 20),
(4, '信息科技部', 'JLB_TECH', 'DEPT', '总行部门', 'active', '1', 30),
(5, '软件开发中心', 'JLB_DEV', 'DEPT', '直属中心', 'active', '4', 40);

-- 角色
INSERT IGNORE INTO sys_role (id, name, code, permission, status, remark, user_count) VALUES
(1, '系统管理员', 'SYS_ADMIN', '全系统数据', 'active', '系统最高权限', 2),
(2, '合规审核员', 'COMP_AUDITOR', '辖内机构数据', 'active', '负责数据审核', 1),
(3, '数据报送员', 'DATA_REPORTER', '本机构数据', 'active', '日常数据填报', 3);

-- 角色权限（示例：给系统管理员全量权限码）
INSERT IGNORE INTO sys_role_permission (role_id, perm_code) VALUES
(1, 'dashboard'),
(1, 'dash:systems'),
(1, 'dash:stats'),
(1, 'dash:notice:view'),
(1, 'sys'),
(1, 'sys:org'),
(1, 'sys:org:add'),
(1, 'sys:org:edit'),
(1, 'sys:org:del'),
(1, 'sys:role'),
(1, 'sys:role:add'),
(1, 'sys:role:edit'),
(1, 'sys:role:del'),
(1, 'sys:user'),
(1, 'sys:user:add'),
(1, 'sys:user:edit'),
(1, 'sys:user:del'),
(1, 'sys:menu'),
(1, 'sys:menu:sync');

-- 用户
INSERT INTO sys_user (id, emp_id, name, org_name, role_name, phone, last_login, status, password, sso_system) VALUES
(1, '001001', '张三', '信息科技部', '系统管理员', '13800000001', '2024-05-20 10:00', 'active', '$2a$10$UiBazf3SxjK683GV5vuEIO93Aoqo9jxYxKcF0ULGfyYR3BL.IxCcy', '反洗钱监测系统,征信报送平台,风险预警驾驶舱,监管报表报送,跨境资金流动,数据质量核查,统一用户认证,安全审计日志,实时风险阻断,外联合规上报'),
(2, '001002', '李四', '长春分行', '数据报送员', '13800000002', '2024-05-19 09:15', 'active', '$2a$10$UiBazf3SxjK683GV5vuEIO93Aoqo9jxYxKcF0ULGfyYR3BL.IxCcy', NULL),
(3, '001003', '王五', '吉林市分行', '合规审核员', '13800000003', '2024-05-18 16:30', 'inactive', '$2a$10$UiBazf3SxjK683GV5vuEIO93Aoqo9jxYxKcF0ULGfyYR3BL.IxCcy', NULL)
ON DUPLICATE KEY UPDATE password = VALUES(password);

-- SSO 配置
INSERT IGNORE INTO sys_system (id, name, protocol, client_id, callback_url, algorithm, network, status) VALUES
(1, '反洗钱监测系统', 'OAuth 2.0', 'AML_SYS_PROD', 'https://aml.jilinbank.com/sso/callback', 'RS256', '内网', 'active'),
(2, '征信报送平台', 'CAS 3.0', 'CREDIT_RPT_V2', 'http://10.20.5.88:8080/cas/validate', 'AES-128', '专线', 'active'),
(3, '风险预警驾驶舱', 'OIDC', 'RISK_DASHBOARD', 'https://risk.jilinbank.com/auth/callback', 'HS256', '内网', 'maintenance'),
(4, '监管报表报送', 'SAML 2.0', 'REG_REPORT_SYS', 'https://rpt.jilinbank.com/saml/acs', 'RSA-SHA256', '内网', 'active'),
(5, '跨境资金流动', 'OAuth 2.0', 'CROSS_BORDER_05', 'https://fx.jilinbank.com/oauth/redirect', 'RSA-SHA256', '互联网', 'maintenance'),
(6, '数据质量核查', 'JWT Token', 'DATA_QUALITY_AUDIT', 'http://10.20.5.66:8080/jwt/verify', 'HMAC-SHA512', '内网', 'active'),
(7, '统一用户认证', 'OIDC', 'IAM_CENTER', 'https://iam.jilinbank.com/oidc/callback', 'RS256', '内网', 'active'),
(8, '安全审计日志', 'OAuth 2.0', 'SEC_AUDIT', 'https://audit.jilinbank.com/oauth/callback', 'HS256', '专线', 'active'),
(9, '实时风险阻断', 'CAS 3.0', 'RISK_BLOCKER', 'http://10.18.9.20:8080/cas/validate', 'AES-256', '内网', 'maintenance'),
(10, '外联合规上报', 'SAML 2.0', 'OUTBOUND_COMPLIANCE', 'https://ext.jilinbank.com/saml/acs', 'RSA-SHA256', '互联网', 'inactive');

-- Task Data
INSERT IGNORE INTO t_task_subject (subject_id, system_id, system_name, status) VALUES 
('SUB001', '1', '反洗钱监测系统', 1),
('SUB002', '2', '征信报送平台', 1),
('SUB003', '3', '风险预警驾驶舱', 1),
('SUB004', '4', '监管报表报送', 1),
('SUB005', '5', '跨境资金流动', 1);

INSERT IGNORE INTO t_task_execution_status (status_id, subject_id, total_count, completed_count, in_progress_count, not_started_count, failed_count, progress_percentage, task_status, start_time, update_time) VALUES
('TES001', 'SUB001', 100, 80, 15, 5, 0, 80.00, 'RUNNING', NOW(), NOW()),
('TES002', 'SUB002', 200, 190, 5, 5, 0, 95.00, 'COMPLETED', NOW(), NOW()),
('TES003', 'SUB003', 50, 10, 20, 20, 0, 20.00, 'RUNNING', NOW(), NOW()),
('TES004', 'SUB004', 300, 300, 0, 0, 0, 100.00, 'COMPLETED', NOW(), NOW()),
('TES005', 'SUB005', 150, 75, 50, 20, 5, 50.00, 'RUNNING', NOW(), NOW());
