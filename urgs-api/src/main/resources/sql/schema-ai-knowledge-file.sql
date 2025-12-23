-- 知识库文件表
CREATE TABLE IF NOT EXISTS `t_ai_knowledge_file` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `kb_id` BIGINT NOT NULL COMMENT '知识库ID',
    `file_name` VARCHAR(255) NOT NULL COMMENT '文件名',
    `file_size` BIGINT DEFAULT 0 COMMENT '文件大小',
    `status` VARCHAR(50) DEFAULT 'UPLOADED' COMMENT '状态: UPLOADED, VECTORIZING, COMPLETED, FAILED',
    `upload_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '上传时间',
    `vector_time` DATETIME COMMENT '向量化完成时间',
    `chunk_count` INTEGER DEFAULT 0 COMMENT '分片数量',
    `token_count` INTEGER DEFAULT 0 COMMENT '消耗Token数',
    `error_message` TEXT COMMENT '错误消息',
    `is_deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除',
    INDEX `idx_kb_id` (`kb_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
