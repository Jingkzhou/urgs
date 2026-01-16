-- 个人知识文档管理模块表结构
-- 包含：文件夹表、文档表、标签表、文档标签关联表

-- 1. 知识文件夹表
CREATE TABLE IF NOT EXISTS `knowledge_folder` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `parent_id` BIGINT DEFAULT NULL COMMENT '父文件夹ID（NULL为根目录）',
    `name` VARCHAR(100) NOT NULL COMMENT '文件夹名称',
    `sort_order` INT DEFAULT 0 COMMENT '排序',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='知识文件夹表';

-- 2. 知识文档表
CREATE TABLE IF NOT EXISTS `knowledge_document` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `folder_id` BIGINT DEFAULT NULL COMMENT '所属文件夹ID（NULL为根目录）',
    `title` VARCHAR(200) NOT NULL COMMENT '文档标题',
    `doc_type` VARCHAR(20) NOT NULL DEFAULT 'markdown' COMMENT '类型：markdown/file',
    `content` TEXT COMMENT 'Markdown 内容（type=markdown）',
    `file_url` VARCHAR(500) COMMENT '文件路径（type=file）',
    `file_name` VARCHAR(255) COMMENT '原始文件名',
    `file_size` BIGINT COMMENT '文件大小（字节）',
    `is_favorite` TINYINT DEFAULT 0 COMMENT '是否收藏：0否 1是',
    `view_count` INT DEFAULT 0 COMMENT '查看次数',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_folder_id` (`folder_id`),
    INDEX `idx_doc_type` (`doc_type`),
    INDEX `idx_is_favorite` (`is_favorite`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='知识文档表';

-- 3. 知识标签表
CREATE TABLE IF NOT EXISTS `knowledge_tag` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `name` VARCHAR(50) NOT NULL COMMENT '标签名称',
    `color` VARCHAR(20) DEFAULT '#1890ff' COMMENT '标签颜色',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX `idx_user_id` (`user_id`),
    UNIQUE KEY `uk_user_name` (`user_id`, `name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='知识标签表';

-- 4. 文档标签关联表
CREATE TABLE IF NOT EXISTS `knowledge_document_tag` (
    `document_id` BIGINT NOT NULL COMMENT '文档ID',
    `tag_id` BIGINT NOT NULL COMMENT '标签ID',
    PRIMARY KEY (`document_id`, `tag_id`),
    INDEX `idx_tag_id` (`tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文档标签关联表';
