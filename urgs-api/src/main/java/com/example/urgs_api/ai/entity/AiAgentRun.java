package com.example.urgs_api.ai.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("ai_agent_run")
public class AiAgentRun {
    @TableId(type = IdType.INPUT)
    private String id;

    @TableField("session_id")
    private String sessionId;

    @TableField("user_id")
    private String userId;

    @TableField("agent_id")
    private Long agentId;

    @TableField("agent_code")
    private String agentCode;

    @TableField("agent_name")
    private String agentName;

    private String status;

    @TableField("user_prompt")
    private String userPrompt;

    @TableField("router_intent")
    private String routerIntent;

    @TableField("router_confidence")
    private Double routerConfidence;

    @TableField("start_time")
    private LocalDateTime startTime;

    @TableField("end_time")
    private LocalDateTime endTime;

    @TableField("error_message")
    private String errorMessage;
}
