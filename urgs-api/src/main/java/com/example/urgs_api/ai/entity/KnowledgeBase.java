package com.example.urgs_api.ai.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.util.Date;

@Data
@TableName("t_ai_knowledge_base")
public class KnowledgeBase {
    @TableId(type = IdType.AUTO)
    private Long id;

    private String name;

    private String description;

    @TableField("collection_name")
    private String collectionName;

    @TableField("embedding_model")
    private String embeddingModel;

    @TableField("enrich_prompt")
    private String enrichPrompt;

    @TableField("provider")
    private String provider; // LOCAL, DIFY

    @TableField("external_id")
    private String externalId;

    @TableField("external_url")
    private String externalUrl;

    @TableField("external_api_key")
    private String externalApiKey;

    @TableField("created_at")
    private Date createdAt;
}
