package com.example.urgs_api.knowledge.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 知识标签实体类
 */
@Data
@TableName("knowledge_tag")
public class KnowledgeTag {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 用户ID */
    private Long userId;

    /** 标签名称 */
    private String name;

    /** 标签颜色 */
    private String color;

    /** 创建时间 */
    private LocalDateTime createTime;
}
