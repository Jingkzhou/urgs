package com.example.urgs_api.ai.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.util.Date;

@Data
@TableName("t_ai_knowledge_file")
public class KnowledgeFile {
    @TableId(type = IdType.AUTO)
    private Long id;

    @TableField("kb_id")
    private Long kbId;

    @TableField("file_name")
    private String fileName;

    @TableField("file_size")
    private Long fileSize;

    /**
     * 状态: UPLOADED, VECTORIZING, COMPLETED, FAILED
     */
    private String status;

    @TableField("upload_time")
    private Date uploadTime;

    @TableField("vector_time")
    private Date vectorTime;

    @TableField("chunk_count")
    private Integer chunkCount;

    @TableField("token_count")
    private Integer tokenCount;

    @TableField("error_message")
    private String errorMessage;

    @TableField("hit_count")
    private Integer hitCount;

    @TableField("priority")
    private Integer priority;

    @TableField("is_deleted")
    private Integer isDeleted;
}
