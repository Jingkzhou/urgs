package com.example.urgs_api.ai.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("ai_agent_tool_call")
public class AiAgentToolCall {
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

    @TableField("tool_name")
    private String toolName;

    @TableField("tool_call_id")
    private String toolCallId;

    @TableField("input_summary")
    private String inputSummary;

    @TableField("output_summary")
    private String outputSummary;

    private String status;

    @TableField("started_at")
    private LocalDateTime startedAt;

    @TableField("finished_at")
    private LocalDateTime finishedAt;

    @TableField("error_message")
    private String errorMessage;
}
