package com.example.urgs_api.knowledge.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 知识文件夹实体类
 */
@Data
@TableName("knowledge_folder")
public class KnowledgeFolder {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 用户ID */
    private Long userId;

    /** 父文件夹ID（NULL为根目录） */
    private Long parentId;

    /** 文件夹名称 */
    private String name;

    /** 空间类型: private(私人)/shared(共享) */
    private String scope = "private";

    /** 排序 */
    private Integer sortOrder;

    /** 创建时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;
}
