package com.example.urgs_api.knowledge.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 知识文档实体类
 */
@Data
@TableName("knowledge_document")
public class KnowledgeDocument {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 用户ID */
    private Long userId;

    /** 所属文件夹ID（NULL为根目录） */
    private Long folderId;

    /** 文档标题（文件名） */
    private String title;

    /** 空间类型: private(私人)/shared(共享) */
    private String scope = "private";

    /** 来源文档ID（从共享空间复制时记录原始ID） */
    private Long sourceDocId;

    /** 文件路径（type=file） */
    private String fileUrl;

    /** 原始文件名 */
    private String fileName;

    /** 文件大小（字节） */
    private Long fileSize;

    /** 是否收藏：0否 1是 */
    private Integer isFavorite;

    /** 查看次数 */
    private Integer viewCount;

    /** 创建时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;
}
