package com.example.urgs_api.ai.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.util.Date;

@Data
@TableName("t_ai_agent_role")
public class AgentRole {
    @TableId(type = IdType.AUTO)
    private Long id;

    @TableField("agent_id")
    private Long agentId;

    @TableField("role_id")
    private Long roleId;

    @TableField("created_at")
    private Date createdAt;
}
