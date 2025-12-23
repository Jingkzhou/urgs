package com.example.urgs_api.ai.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * AI 聊天会话实体
 */
@Data
@TableName("ai_chat_session")
public class AiChatSession {

    @TableId(type = IdType.INPUT)
    private String id;

    private String userId;

    private String title;

    @com.baomidou.mybatisplus.annotation.TableField("agent_id")
    private Long agentId;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;

    @com.baomidou.mybatisplus.annotation.TableLogic
    private Integer isDeleted;

    /**
     * Session Context Summary
     */
    private String summary;
}
