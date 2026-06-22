DROP PROCEDURE IF EXISTS ExecuteIdempotent_V90;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V90()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    DROP TABLE IF EXISTS `regulatory_test_detail`;
    DROP TABLE IF EXISTS `regulatory_test_summary`;

    CREATE TABLE `regulatory_test_summary` (
        `id` BIGINT NOT NULL AUTO_INCREMENT,
        `data_date` DATE NOT NULL,
        `org_name` VARCHAR(128) NOT NULL,
        `org_code` VARCHAR(64) NOT NULL,
        `report_name` VARCHAR(128) NOT NULL,
        `report_code` VARCHAR(64) NOT NULL,
        `metric_name` VARCHAR(128) NOT NULL,
        `metric_code` VARCHAR(64) NOT NULL,
        `metric_value` DECIMAL(18,2) NOT NULL,
        `metric_description` VARCHAR(500) NOT NULL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uk_regulatory_test_summary_scope` (`data_date`, `org_code`, `report_code`, `metric_code`),
        KEY `idx_regulatory_test_summary_metric` (`metric_code`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

    CREATE TABLE `regulatory_test_detail` (
        `id` BIGINT NOT NULL AUTO_INCREMENT,
        `data_date` DATE NOT NULL,
        `org_name` VARCHAR(128) NOT NULL,
        `org_code` VARCHAR(64) NOT NULL,
        `report_name` VARCHAR(128) NOT NULL,
        `report_code` VARCHAR(64) NOT NULL,
        `metric_name` VARCHAR(128) NOT NULL,
        `metric_code` VARCHAR(64) NOT NULL,
        `metric_description` VARCHAR(500) NOT NULL,
        `contract_no` VARCHAR(64) NOT NULL,
        `customer_name` VARCHAR(128) NOT NULL,
        `mobile` VARCHAR(32) NOT NULL,
        `metric_value` DECIMAL(18,2) NOT NULL,
        `record_status` VARCHAR(32) NOT NULL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uk_regulatory_test_detail_contract` (`data_date`, `org_code`, `metric_code`, `contract_no`),
        KEY `idx_regulatory_test_detail_scope` (`data_date`, `org_code`, `report_code`, `metric_code`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

    INSERT INTO `regulatory_test_summary` (
        `data_date`, `org_name`, `org_code`, `report_name`, `report_code`,
        `metric_name`, `metric_code`, `metric_value`, `metric_description`
    ) VALUES
        ('2026-01-31', '总行', '1100', '信贷监管报表', 'RPT_LOAN', '各项贷款余额', 'loan_balance', 2110000.00, '报告期末全部贷款余额'),
        ('2026-01-31', '总行', '1100', '信贷监管报表', 'RPT_LOAN', '不良贷款余额', 'npl_balance', 44000.00, '报告期末不良贷款余额'),
        ('2026-02-28', '总行', '1100', '信贷监管报表', 'RPT_LOAN', '各项贷款余额', 'loan_balance', 2190000.00, '报告期末全部贷款余额'),
        ('2026-02-28', '总行', '1100', '信贷监管报表', 'RPT_LOAN', '不良贷款余额', 'npl_balance', 30000.00, '报告期末不良贷款余额'),
        ('2026-02-28', '分行一', '1200', '信贷监管报表', 'RPT_LOAN', '各项贷款余额', 'loan_balance', 760000.00, '报告期末全部贷款余额'),
        ('2026-02-28', '分行一', '1200', '信贷监管报表', 'RPT_LOAN', '不良贷款余额', 'npl_balance', 18000.00, '报告期末不良贷款余额');

    INSERT INTO `regulatory_test_detail` (
        `data_date`, `org_name`, `org_code`, `report_name`, `report_code`, `metric_name`, `metric_code`, `metric_description`,
        `contract_no`, `customer_name`, `mobile`, `metric_value`, `record_status`
    ) VALUES
        ('2026-02-28', '分行一', '1200', '信贷监管报表', 'RPT_LOAN', '各项贷款余额', 'loan_balance', '报告期末全部贷款余额', 'HT20260006', '孙八', '13400134000', 760000.00, 'overdue'),
        ('2026-01-31', '总行', '1100', '信贷监管报表', 'RPT_LOAN', '各项贷款余额', 'loan_balance', '报告期末全部贷款余额', 'HT20260001', '张三', '13800138000', 450000.00, 'normal'),
        ('2026-01-31', '总行', '1100', '信贷监管报表', 'RPT_LOAN', '各项贷款余额', 'loan_balance', '报告期末全部贷款余额', 'HT20260002', '李四', '13900139000', 380000.00, 'normal'),
        ('2026-01-31', '总行', '1100', '信贷监管报表', 'RPT_LOAN', '各项贷款余额', 'loan_balance', '报告期末全部贷款余额', 'HT20260003', '王五', '13700137000', 220000.00, 'overdue');
END$$
DELIMITER ;
CALL ExecuteIdempotent_V90();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V90;
