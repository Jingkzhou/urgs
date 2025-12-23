package com.example.urgs_api.ai.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.util.Date;

@Data
@TableName("t_ai_agent")
public class Agent {
    @TableId(type = IdType.AUTO)
    private Long id;

    private String name;

    private String description;

    @TableField("system_prompt")
    private String systemPrompt;

    // 0: Disabled, 1: Enabled
    private Integer status;

    @TableField("knowledge_base")
    private String knowledgeBase;

    @TableField("rag_instruction")
    private String ragInstruction;

    // JSON string storing list of prompts
    private String prompts;

    @TableField("updated_at")
    private Date updatedAt;
}
