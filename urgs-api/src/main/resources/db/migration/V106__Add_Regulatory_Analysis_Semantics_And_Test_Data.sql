DROP PROCEDURE IF EXISTS ExecuteIdempotent_V106;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V106()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'reg_element_query_config'
          AND COLUMN_NAME = 'analysis_config_json'
    ) THEN
        ALTER TABLE `reg_element_query_config`
            ADD COLUMN `analysis_config_json` LONGTEXT NULL
            COMMENT '指标分析语义JSON，包含聚合、频率、单位、缩放、可加性、对比基准和维度字段ID'
            AFTER `detail_max_rows`;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'regulatory_test_summary'
    ) THEN
        IF NOT EXISTS (
            SELECT 1
            FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'regulatory_test_summary'
              AND COLUMN_NAME = 'product_type'
        ) THEN
            ALTER TABLE `regulatory_test_summary`
                ADD COLUMN `product_type` VARCHAR(32) NOT NULL DEFAULT 'ALL'
                COMMENT '产品类型，用于监管指标维度贡献测试'
                AFTER `metric_code`;
        END IF;

        IF EXISTS (
            SELECT 1
            FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'regulatory_test_summary'
              AND INDEX_NAME = 'uk_regulatory_test_summary_scope'
        ) THEN
            ALTER TABLE `regulatory_test_summary`
                DROP INDEX `uk_regulatory_test_summary_scope`;
        END IF;

        IF NOT EXISTS (
            SELECT 1
            FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'regulatory_test_summary'
              AND INDEX_NAME = 'uk_regulatory_test_summary_scope_product'
        ) THEN
            ALTER TABLE `regulatory_test_summary`
                ADD UNIQUE KEY `uk_regulatory_test_summary_scope_product`
                    (`data_date`, `org_code`, `report_code`, `metric_code`, `product_type`);
        END IF;

        DELETE FROM `regulatory_test_summary`
        WHERE `report_code` = 'RPT_LOAN'
          AND `metric_code` IN ('loan_balance', 'npl_balance')
          AND `org_code` IN ('1100', '1200');

        INSERT INTO `regulatory_test_summary` (
            `data_date`, `org_name`, `org_code`, `report_name`, `report_code`,
            `metric_name`, `metric_code`, `product_type`, `metric_value`, `metric_description`
        ) VALUES
            ('2025-02-28', '总行', '1100', '信贷监管报表', 'RPT_LOAN', '各项贷款余额', 'loan_balance', '零售贷款', 820000.00, '报告期末全部贷款余额'),
            ('2025-02-28', '总行', '1100', '信贷监管报表', 'RPT_LOAN', '各项贷款余额', 'loan_balance', '公司贷款', 1080000.00, '报告期末全部贷款余额'),
            ('2025-02-28', '总行', '1100', '信贷监管报表', 'RPT_LOAN', '不良贷款余额', 'npl_balance', '零售贷款', 17000.00, '报告期末不良贷款余额'),
            ('2025-02-28', '总行', '1100', '信贷监管报表', 'RPT_LOAN', '不良贷款余额', 'npl_balance', '公司贷款', 25000.00, '报告期末不良贷款余额'),
            ('2026-01-31', '总行', '1100', '信贷监管报表', 'RPT_LOAN', '各项贷款余额', 'loan_balance', '零售贷款', 910000.00, '报告期末全部贷款余额'),
            ('2026-01-31', '总行', '1100', '信贷监管报表', 'RPT_LOAN', '各项贷款余额', 'loan_balance', '公司贷款', 1200000.00, '报告期末全部贷款余额'),
            ('2026-01-31', '总行', '1100', '信贷监管报表', 'RPT_LOAN', '不良贷款余额', 'npl_balance', '零售贷款', 18000.00, '报告期末不良贷款余额'),
            ('2026-01-31', '总行', '1100', '信贷监管报表', 'RPT_LOAN', '不良贷款余额', 'npl_balance', '公司贷款', 26000.00, '报告期末不良贷款余额'),
            ('2026-02-28', '总行', '1100', '信贷监管报表', 'RPT_LOAN', '各项贷款余额', 'loan_balance', '零售贷款', 950000.00, '报告期末全部贷款余额'),
            ('2026-02-28', '总行', '1100', '信贷监管报表', 'RPT_LOAN', '各项贷款余额', 'loan_balance', '公司贷款', 1240000.00, '报告期末全部贷款余额'),
            ('2026-02-28', '总行', '1100', '信贷监管报表', 'RPT_LOAN', '不良贷款余额', 'npl_balance', '零售贷款', 12000.00, '报告期末不良贷款余额'),
            ('2026-02-28', '总行', '1100', '信贷监管报表', 'RPT_LOAN', '不良贷款余额', 'npl_balance', '公司贷款', 18000.00, '报告期末不良贷款余额'),
            ('2025-02-28', '分行一', '1200', '信贷监管报表', 'RPT_LOAN', '各项贷款余额', 'loan_balance', '零售贷款', 400000.00, '报告期末全部贷款余额'),
            ('2025-02-28', '分行一', '1200', '信贷监管报表', 'RPT_LOAN', '各项贷款余额', 'loan_balance', '公司贷款', 250000.00, '报告期末全部贷款余额'),
            ('2025-02-28', '分行一', '1200', '信贷监管报表', 'RPT_LOAN', '不良贷款余额', 'npl_balance', '零售贷款', 6000.00, '报告期末不良贷款余额'),
            ('2025-02-28', '分行一', '1200', '信贷监管报表', 'RPT_LOAN', '不良贷款余额', 'npl_balance', '公司贷款', 9000.00, '报告期末不良贷款余额'),
            ('2026-01-31', '分行一', '1200', '信贷监管报表', 'RPT_LOAN', '各项贷款余额', 'loan_balance', '零售贷款', 430000.00, '报告期末全部贷款余额'),
            ('2026-01-31', '分行一', '1200', '信贷监管报表', 'RPT_LOAN', '各项贷款余额', 'loan_balance', '公司贷款', 270000.00, '报告期末全部贷款余额'),
            ('2026-01-31', '分行一', '1200', '信贷监管报表', 'RPT_LOAN', '不良贷款余额', 'npl_balance', '零售贷款', 7000.00, '报告期末不良贷款余额'),
            ('2026-01-31', '分行一', '1200', '信贷监管报表', 'RPT_LOAN', '不良贷款余额', 'npl_balance', '公司贷款', 10000.00, '报告期末不良贷款余额'),
            ('2026-02-28', '分行一', '1200', '信贷监管报表', 'RPT_LOAN', '各项贷款余额', 'loan_balance', '零售贷款', 470000.00, '报告期末全部贷款余额'),
            ('2026-02-28', '分行一', '1200', '信贷监管报表', 'RPT_LOAN', '各项贷款余额', 'loan_balance', '公司贷款', 290000.00, '报告期末全部贷款余额'),
            ('2026-02-28', '分行一', '1200', '信贷监管报表', 'RPT_LOAN', '不良贷款余额', 'npl_balance', '零售贷款', 7000.00, '报告期末不良贷款余额'),
            ('2026-02-28', '分行一', '1200', '信贷监管报表', 'RPT_LOAN', '不良贷款余额', 'npl_balance', '公司贷款', 11000.00, '报告期末不良贷款余额');
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V106();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V106;
