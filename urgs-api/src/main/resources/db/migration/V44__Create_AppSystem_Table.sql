-- 创建应用系统表
CREATE TABLE IF NOT EXISTS t_app_system (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100)  NOT NULL COMMENT '应用名称',
    code        VARCHAR(50)   NOT NULL COMMENT '应用编码',
    description VARCHAR(500)  NULL     COMMENT '应用描述',
    owner_id    BIGINT        NULL     COMMENT '负责人ID',
    team        VARCHAR(100)  NULL     COMMENT '开发团队',
    status      VARCHAR(20)   NULL     DEFAULT 'active' COMMENT '状态',
    created_at  DATETIME      NULL     COMMENT '创建时间',
    updated_at  DATETIME      NULL     COMMENT '更新时间',
    CONSTRAINT uk_app_system_code UNIQUE (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='应用系统表';
