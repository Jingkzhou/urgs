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

    @TableField("agent_code")
    private String agentCode;

    private String name;

    @TableField("agent_type")
    private String agentType;

    private String description;

    @TableField("system_prompt")
    private String systemPrompt;

    // 0: Disabled, 1: Enabled
    private Integer status;

    @TableField("build_mode")
    private String buildMode;

    @TableField("knowledge_base")
    private String knowledgeBase;

    @TableField("rag_instruction")
    private String ragInstruction;

    // JSON string storing list of prompts
    private String prompts;

    @TableField("dify_api_key")
    private String difyApiKey;

    @TableField("dify_api_base")
    private String difyApiBase;

    @TableField("agent_app_tools")
    private String agentAppTools;

    @TableField("capability_tags")
    private String capabilityTags;

    @TableField("routing_examples")
    private String routingExamples;

    @TableField("memory_files")
    private String memoryFiles;

    @TableField("skill_dirs")
    private String skillDirs;

    @TableField("tool_allowlist")
    private String toolAllowlist;

    @TableField("policy_config")
    private String policyConfig;

    @TableField("model_config")
    private String modelConfig;

    @TableField("sort_order")
    private Integer sortOrder;

    @TableField("updated_at")
    private Date updatedAt;
}
