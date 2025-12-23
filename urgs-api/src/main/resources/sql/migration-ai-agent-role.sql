-- AI 智能体与角色关联表
CREATE TABLE IF NOT EXISTS `t_ai_agent_role` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `agent_id` BIGINT NOT NULL COMMENT '智能体ID',
    `role_id` BIGINT NOT NULL COMMENT '角色ID',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    UNIQUE KEY `uk_agent_role` (`agent_id`, `role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI 智能体角色授权关联表';
