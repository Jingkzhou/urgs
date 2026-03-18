-- ============================================================
-- 指标走势测试数据 seed-metric-data.sql
-- 使用方式: 连接到数据库后直接执行本脚本
-- 注意: 脚本会先检查 sys_system 中是否存在演示系统，
--       若不存在则自动创建，然后灌入指标类型和30天模拟数据
-- ============================================================

-- ===== 1. 确保演示系统存在 =====
INSERT IGNORE INTO sys_system (name, protocol, client_id, status, icon)
VALUES
    ('核心银行', 'HTTPS', 'CORE_BANK',   'active', 'bank'),
    ('信贷系统', 'HTTPS', 'CREDIT_SYS',  'active', 'credit-card'),
    ('支付中心', 'HTTPS', 'PAY_CENTER',   'active', 'wallet');

-- ===== 2. 指标类型定义 =====
-- 核心银行
INSERT IGNORE INTO t_metric_type (system_id, type_code, type_name, unit, color, sort_order, status) VALUES
    ('CORE_BANK', 'txn_volume',    '交易量',   '笔',  '#ef4444', 1, 1),
    ('CORE_BANK', 'success_rate',  '成功率',   '%',   '#10b981', 2, 1),
    ('CORE_BANK', 'avg_latency',   '平均耗时', 'ms',  '#3b82f6', 3, 1),
    ('CORE_BANK', 'active_users',  '活跃用户', '人',  '#f59e0b', 4, 1);

-- 信贷系统
INSERT IGNORE INTO t_metric_type (system_id, type_code, type_name, unit, color, sort_order, status) VALUES
    ('CREDIT_SYS', 'loan_count',    '放款笔数', '笔',   '#8b5cf6', 1, 1),
    ('CREDIT_SYS', 'loan_amount',   '放款金额', '万元', '#ec4899', 2, 1),
    ('CREDIT_SYS', 'approval_rate', '审批通过率', '%',  '#10b981', 3, 1),
    ('CREDIT_SYS', 'overdue_rate',  '逾期率',   '%',   '#ef4444', 4, 1);

-- 支付中心
INSERT IGNORE INTO t_metric_type (system_id, type_code, type_name, unit, color, sort_order, status) VALUES
    ('PAY_CENTER', 'pay_volume',   '支付笔数', '笔',  '#6366f1', 1, 1),
    ('PAY_CENTER', 'pay_amount',   '支付金额', '万元', '#f97316', 2, 1),
    ('PAY_CENTER', 'pay_latency',  '支付耗时', 'ms',  '#3b82f6', 3, 1),
    ('PAY_CENTER', 'channel_count','渠道在线',  '个',  '#14b8a6', 4, 1);

-- ===== 3. 生成30天模拟数据（存储过程） =====
DROP PROCEDURE IF EXISTS SeedMetricData;
DELIMITER $$
CREATE PROCEDURE SeedMetricData()
BEGIN
    DECLARE v_day INT DEFAULT 0;
    DECLARE v_hour INT;
    DECLARE v_date DATE;
    DECLARE v_datetime DATETIME;
    DECLARE v_rand DOUBLE;

    -- 清理旧的测试数据（仅清理演示系统的数据）
    DELETE FROM t_metric_data WHERE system_id IN ('CORE_BANK', 'CREDIT_SYS', 'PAY_CENTER');

    -- 循环30天
    WHILE v_day < 30 DO
        SET v_date = DATE_SUB(CURDATE(), INTERVAL (29 - v_day) DAY);
        SET v_hour = 0;

        -- 每天24小时
        WHILE v_hour < 24 DO
            SET v_datetime = ADDTIME(v_date, SEC_TO_TIME(v_hour * 3600));
            SET v_rand = RAND();

            -- ==================== 核心银行 ====================

            -- 交易量: 白天高峰(8-18点) 800-2000笔, 夜间 100-500笔
            INSERT INTO t_metric_data (system_id, type_code, metric_value, metric_time) VALUES
            ('CORE_BANK', 'txn_volume',
                CASE
                    WHEN v_hour BETWEEN 8 AND 18 THEN ROUND(800 + v_rand * 1200 + IF(v_hour BETWEEN 10 AND 14, 500, 0), 0)
                    WHEN v_hour BETWEEN 6 AND 7 THEN ROUND(300 + v_rand * 400, 0)
                    ELSE ROUND(100 + v_rand * 400, 0)
                END,
                v_datetime);

            -- 成功率: 正常 98.5-99.9%, 偶尔低谷
            INSERT INTO t_metric_data (system_id, type_code, metric_value, metric_time) VALUES
            ('CORE_BANK', 'success_rate',
                CASE
                    WHEN v_rand < 0.05 THEN ROUND(95 + RAND() * 3, 2)
                    ELSE ROUND(98.5 + RAND() * 1.4, 2)
                END,
                v_datetime);

            -- 平均耗时: 白天 80-200ms, 夜间 30-80ms
            INSERT INTO t_metric_data (system_id, type_code, metric_value, metric_time) VALUES
            ('CORE_BANK', 'avg_latency',
                CASE
                    WHEN v_hour BETWEEN 9 AND 17 THEN ROUND(80 + v_rand * 120 + IF(v_hour BETWEEN 11 AND 13, 50, 0), 1)
                    ELSE ROUND(30 + v_rand * 50, 1)
                END,
                v_datetime);

            -- 活跃用户: 白天 200-800, 夜间 10-50
            INSERT INTO t_metric_data (system_id, type_code, metric_value, metric_time) VALUES
            ('CORE_BANK', 'active_users',
                CASE
                    WHEN v_hour BETWEEN 8 AND 20 THEN ROUND(200 + v_rand * 600 + IF(v_hour BETWEEN 9 AND 11, 300, 0), 0)
                    ELSE ROUND(10 + v_rand * 40, 0)
                END,
                v_datetime);

            -- ==================== 信贷系统 ====================

            -- 放款笔数: 工作时间 20-80笔, 其他时间 0-5笔
            INSERT INTO t_metric_data (system_id, type_code, metric_value, metric_time) VALUES
            ('CREDIT_SYS', 'loan_count',
                CASE
                    WHEN v_hour BETWEEN 9 AND 17 THEN ROUND(20 + v_rand * 60, 0)
                    ELSE ROUND(v_rand * 5, 0)
                END,
                v_datetime);

            -- 放款金额: 与笔数相关, 单笔 5-50万
            INSERT INTO t_metric_data (system_id, type_code, metric_value, metric_time) VALUES
            ('CREDIT_SYS', 'loan_amount',
                CASE
                    WHEN v_hour BETWEEN 9 AND 17 THEN ROUND((20 + v_rand * 60) * (5 + RAND() * 45), 2)
                    ELSE ROUND(v_rand * 5 * (5 + RAND() * 20), 2)
                END,
                v_datetime);

            -- 审批通过率: 60-85%
            INSERT INTO t_metric_data (system_id, type_code, metric_value, metric_time) VALUES
            ('CREDIT_SYS', 'approval_rate',
                ROUND(60 + v_rand * 25, 2),
                v_datetime);

            -- 逾期率: 1.2-3.5%
            INSERT INTO t_metric_data (system_id, type_code, metric_value, metric_time) VALUES
            ('CREDIT_SYS', 'overdue_rate',
                ROUND(1.2 + v_rand * 2.3, 2),
                v_datetime);

            -- ==================== 支付中心 ====================

            -- 支付笔数: 白天 500-3000, 夜间 50-300
            INSERT INTO t_metric_data (system_id, type_code, metric_value, metric_time) VALUES
            ('PAY_CENTER', 'pay_volume',
                CASE
                    WHEN v_hour BETWEEN 8 AND 22 THEN ROUND(500 + v_rand * 2500 + IF(v_hour BETWEEN 11 AND 13, 800, 0) + IF(v_hour BETWEEN 19 AND 21, 600, 0), 0)
                    ELSE ROUND(50 + v_rand * 250, 0)
                END,
                v_datetime);

            -- 支付金额: 单笔平均 0.3-2万
            INSERT INTO t_metric_data (system_id, type_code, metric_value, metric_time) VALUES
            ('PAY_CENTER', 'pay_amount',
                CASE
                    WHEN v_hour BETWEEN 8 AND 22 THEN ROUND((500 + v_rand * 2500) * (0.3 + RAND() * 1.7), 2)
                    ELSE ROUND((50 + v_rand * 250) * (0.3 + RAND() * 1), 2)
                END,
                v_datetime);

            -- 支付耗时: 50-300ms
            INSERT INTO t_metric_data (system_id, type_code, metric_value, metric_time) VALUES
            ('PAY_CENTER', 'pay_latency',
                CASE
                    WHEN v_hour BETWEEN 10 AND 14 THEN ROUND(120 + v_rand * 180, 1)
                    ELSE ROUND(50 + v_rand * 100, 1)
                END,
                v_datetime);

            -- 渠道在线: 8-12个渠道
            INSERT INTO t_metric_data (system_id, type_code, metric_value, metric_time) VALUES
            ('PAY_CENTER', 'channel_count',
                CASE
                    WHEN v_rand < 0.03 THEN ROUND(6 + RAND() * 2, 0)
                    ELSE ROUND(10 + RAND() * 2, 0)
                END,
                v_datetime);

            SET v_hour = v_hour + 1;
        END WHILE;

        SET v_day = v_day + 1;
    END WHILE;
END$$
DELIMITER ;

-- 执行并清理
CALL SeedMetricData();
DROP PROCEDURE SeedMetricData;

-- ===== 4. 数据验证 =====
SELECT '=== 指标类型 ===' AS info;
SELECT system_id, type_code, type_name, unit, color FROM t_metric_type ORDER BY system_id, sort_order;

SELECT '=== 数据量统计 ===' AS info;
SELECT system_id, type_code, COUNT(*) AS rows_count,
       MIN(metric_time) AS earliest, MAX(metric_time) AS latest
FROM t_metric_data
GROUP BY system_id, type_code
ORDER BY system_id, type_code;
