ALTER TABLE t_version_package ADD COLUMN env_id BIGINT DEFAULT NULL COMMENT '投产环境ID';
ALTER TABLE t_version_package ADD COLUMN exec_user VARCHAR(100) DEFAULT NULL COMMENT '执行用户(鉴权账号)';
