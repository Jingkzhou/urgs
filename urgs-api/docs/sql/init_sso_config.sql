-- 监管系统配置数据初始化
-- 插入21个监管系统到 sys_sso_config 表

INSERT IGNORE INTO sys_sso_config (name, protocol, client_id, callback_url, algorithm, network, status) VALUES
-- 1. 个人银行账户系统
('个人银行账户系统', 'SAML', 'PERSONAL_ACCOUNT', '', 'RS256', '内网', 'active'),
-- 2. 存款保险1.0系统
('存款保险1.0系统', 'SAML', 'DEPOSIT_INSURANCE_1', '', 'RS256', '内网', 'active'),
-- 3. 反洗钱系统
('反洗钱系统', 'SAML', 'AML', '', 'RS256', '内网', 'active'),
-- 4. 利率报备检测
('利率报备检测', 'SAML', 'RATE_REPORT', '', 'RS256', '内网', 'active'),
-- 5. 1104系统
('1104系统', 'SAML', '1104', '', 'RS256', '内网', 'active'),
-- 6. 法人间参系统
('法人间参系统', 'SAML', 'LEGAL_INTER', '', 'RS256', '内网', 'active'),
-- 7. 客户风险系统
('客户风险系统', 'SAML', 'CUSTOMER_RISK', '', 'RS256', '内网', 'active'),
-- 8. EAST5系统
('EAST5系统', 'SAML', 'EAST5', '', 'RS256', '内网', 'active'),
-- 9. 标准化存贷款系统
('标准化存贷款系统', 'SAML', 'STD_DEPOSIT_LOAN', '', 'RS256', '内网', 'active'),
-- 10. 大集中系统 (PBOC)
('大集中系统', 'SAML', 'PBOC', '', 'RS256', '内网', 'active'),
-- 11. 集团并表系统
('集团并表系统', 'SAML', 'GROUP_CONSOLIDATE', '', 'RS256', '内网', 'active'),
-- 12. 金融基础数据系统
('金融基础数据系统', 'SAML', 'FIN_BASIC_DATA', '', 'RS256', '内网', 'active'),
-- 13. 支付统计分析系统
('支付统计分析系统', 'SAML', 'PAYMENT_STAT', '', 'RS256', '内网', 'active'),
-- 14. 存款保险2.0系统
('存款保险2.0系统', 'SAML', 'DEPOSIT_INSURANCE_2', '', 'RS256', '内网', 'active'),
-- 15. 农村支付系统
('农村支付系统', 'SAML', 'RURAL_PAYMENT', '', 'RS256', '内网', 'active'),
-- 16. 审计署系统
('审计署系统', 'SAML', 'AUDIT', '', 'RS256', '内网', 'active'),
-- 17. 人民币利率报备系统
('人民币利率报备系统', 'SAML', 'RMB_RATE_REPORT', '', 'RS256', '内网', 'active'),
-- 18. 非居民涉税
('非居民涉税', 'SAML', 'NON_RESIDENT_TAX', '', 'RS256', '内网', 'active'),
-- 19. 大额现金管理系统
('大额现金管理系统', 'SAML', 'LARGE_CASH', '', 'RS256', '内网', 'active'),
-- 20. 一表通
('一表通', 'SAML', 'ONE_TABLE', '', 'RS256', '内网', 'active'),
-- 21. 跨系统校验
('跨系统校验', 'SAML', 'CROSS_SYSTEM_CHECK', '', 'RS256', '内网', 'active'),
-- CBRC 系统 (银监会报表)
('银监会报表系统', 'SAML', 'CBRC', '', 'RS256', '内网', 'active');
