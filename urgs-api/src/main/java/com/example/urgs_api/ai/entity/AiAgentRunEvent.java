package com.example.urgs_api.ai.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("ai_agent_run_event")
public class AiAgentRunEvent {
    @TableId(type = IdType.AUTO)
    private Long id;

    @TableField("run_id")
    private String runId;

    @TableField("session_id")
    private String sessionId;

    @TableField("agent_id")
    private Long agentId;

    @TableField("agent_code")
    private String agentCode;

    @TableField("event_type")
    private String eventType;

    private String title;

    private String content;

    private String payload;

    private String status;

    @TableField("create_time")
    private LocalDateTime createTime;
}
