CREATE TABLE IF NOT EXISTS metadata_regulatory_asset (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    name VARCHAR(255) NOT NULL COMMENT '资产名称',
    code VARCHAR(100) NOT NULL COMMENT '资产代码/标识',
    system_code VARCHAR(100) COMMENT '所属系统代码 (关联 sys_sso_config.clientId)',
    type VARCHAR(50) COMMENT '资产类型 (如: 报表, 指标)',
    description TEXT COMMENT '描述',
    owner VARCHAR(100) COMMENT '责任人',
    status INT DEFAULT 1 COMMENT '状态 (1: 启用, 0: 停用)',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_name (name),
    INDEX idx_code (code),
    INDEX idx_system_code (system_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='监管指标资产表';
