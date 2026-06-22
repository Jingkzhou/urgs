DROP PROCEDURE IF EXISTS ExecuteIdempotent_V89;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V89()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    CREATE TABLE IF NOT EXISTS `regulatory_test_summary` (
        `id` BIGINT NOT NULL AUTO_INCREMENT,
        `stat_date` DATE NOT NULL,
        `org_code` VARCHAR(64) NOT NULL,
        `product_type` VARCHAR(32) NOT NULL,
        `loan_balance` DECIMAL(18,2) NOT NULL,
        `npl_balance` DECIMAL(18,2) NOT NULL,
        `deposit_balance` DECIMAL(18,2) NOT NULL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uk_regulatory_test_summary_scope` (`stat_date`, `org_code`, `product_type`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='监管查询 Skill 测试汇总数据';

    CREATE TABLE IF NOT EXISTS `regulatory_test_detail` (
        `id` BIGINT NOT NULL AUTO_INCREMENT,
        `stat_date` DATE NOT NULL,
        `org_code` VARCHAR(64) NOT NULL,
        `product_type` VARCHAR(32) NOT NULL,
        `contract_no` VARCHAR(64) NOT NULL,
        `customer_name` VARCHAR(128) NOT NULL,
        `mobile` VARCHAR(32) NOT NULL,
        `loan_balance` DECIMAL(18,2) NOT NULL,
        `loan_status` VARCHAR(32) NOT NULL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uk_regulatory_test_detail_contract` (`contract_no`),
        KEY `idx_regulatory_test_detail_scope` (`stat_date`, `org_code`, `product_type`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='监管查询 Skill 测试明细数据';

    INSERT INTO `regulatory_test_summary` (
        `stat_date`, `org_code`, `product_type`, `loan_balance`, `npl_balance`, `deposit_balance`
    ) VALUES
        ('2026-01-31', '1100', 'corporate', 1250000.00, 32000.00, 2100000.00),
        ('2026-01-31', '1100', 'retail', 860000.00, 12000.00, 2100000.00),
        ('2026-02-28', '1100', 'corporate', 1280000.00, 30000.00, 2180000.00),
        ('2026-02-28', '1200', 'corporate', 760000.00, 18000.00, 1350000.00)
    ON DUPLICATE KEY UPDATE
        `loan_balance` = VALUES(`loan_balance`),
        `npl_balance` = VALUES(`npl_balance`),
        `deposit_balance` = VALUES(`deposit_balance`);

    INSERT INTO `regulatory_test_detail` (
        `stat_date`, `org_code`, `product_type`, `contract_no`, `customer_name`, `mobile`, `loan_balance`, `loan_status`
    ) VALUES
        ('2026-01-31', '1100', 'corporate', 'HT20260001', '张三', '13800138000', 450000.00, 'normal'),
        ('2026-01-31', '1100', 'corporate', 'HT20260002', '李四', '13900139000', 380000.00, 'normal'),
        ('2026-01-31', '1100', 'corporate', 'HT20260003', '王五', '13700137000', 220000.00, 'overdue'),
        ('2026-01-31', '1100', 'retail', 'HT20260004', '赵六', '13600136000', 180000.00, 'normal'),
        ('2026-02-28', '1100', 'corporate', 'HT20260005', '钱七', '13500135000', 230000.00, 'normal'),
        ('2026-02-28', '1200', 'corporate', 'HT20260006', '孙八', '13400134000', 760000.00, 'overdue')
    ON DUPLICATE KEY UPDATE
        `stat_date` = VALUES(`stat_date`),
        `org_code` = VALUES(`org_code`),
        `product_type` = VALUES(`product_type`),
        `customer_name` = VALUES(`customer_name`),
        `mobile` = VALUES(`mobile`),
        `loan_balance` = VALUES(`loan_balance`),
        `loan_status` = VALUES(`loan_status`);
END$$
DELIMITER ;
CALL ExecuteIdempotent_V89();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V89;
