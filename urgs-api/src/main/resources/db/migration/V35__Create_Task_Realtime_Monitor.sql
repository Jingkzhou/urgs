-- 新增实时任务监控明细表
CREATE TABLE IF NOT EXISTS t_task_realtime_monitor (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    system_code VARCHAR(50) NOT NULL COMMENT '对应系统表的 AppID (client_id)',
    task_name VARCHAR(200) NOT NULL COMMENT '任务名称',
    task_status VARCHAR(20) NOT NULL COMMENT '状态: RUNNING, SUCCESS, FAILED',
    start_time DATETIME COMMENT '任务开始时间',
    end_time DATETIME COMMENT '任务完成时间',
    data_date DATE NOT NULL COMMENT '数据日期 (业务日期)'
) COMMENT='实时任务监控明细表';

-- 初始测试数据 (当日数据，用于验证态势图联动)
INSERT INTO t_task_realtime_monitor (system_code, task_name, task_status, start_time, data_date) VALUES 
('PERSONAL_ACCOUNT', '每日账户核对', 'SUCCESS', NOW(), CURRENT_DATE),
('PERSONAL_ACCOUNT', '流水下载', 'RUNNING', NOW(), CURRENT_DATE),
('AML', '大额交易上报', 'FAILED', NOW(), CURRENT_DATE),
('AML', '黑名单同步', 'SUCCESS', NOW(), CURRENT_DATE),
('RATE_REPORT', '利率波动监测', 'RUNNING', NOW(), CURRENT_DATE);
