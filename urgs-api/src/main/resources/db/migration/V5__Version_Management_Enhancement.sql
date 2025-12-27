-- Add email and gitlab_username to sys_user
ALTER TABLE sys_user ADD COLUMN email VARCHAR(100) COMMENT 'Git邮箱';
ALTER TABLE sys_user ADD COLUMN gitlab_username VARCHAR(100) COMMENT 'GitLab账号';

-- Create table for AI Code Review
CREATE TABLE ver_ai_code_review (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    repo_id BIGINT NOT NULL COMMENT '仓库ID',
    commit_sha VARCHAR(64) NOT NULL COMMENT 'Commit SHA',
    branch VARCHAR(100) COMMENT '分支名',
    developer_email VARCHAR(100) COMMENT '开发者邮箱',
    developer_id BIGINT COMMENT '关联的系统用户ID',
    score INT COMMENT '代码评分(0-100)',
    summary VARCHAR(2000) COMMENT '简要总结',
    content TEXT COMMENT '完整AI分析内容',
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' COMMENT '状态: PENDING, COMPLETED, FAILED',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_repo_commit (repo_id, commit_sha),
    INDEX idx_developer (developer_id)
) COMMENT='AI代码走查记录表';
