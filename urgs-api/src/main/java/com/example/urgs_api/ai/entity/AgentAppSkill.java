package com.example.urgs_api.ai.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

@Data
@TableName("t_ai_agent_app_skill")
public class AgentAppSkill {
    @TableId(type = IdType.AUTO)
    private Long id;

    @TableField("app_code")
    private String appCode;

    private String name;

    private String code;

    private String description;

    private String instruction;

    private Integer status;

    @TableField("sort_order")
    private Integer sortOrder;

    @TableField("created_at")
    private Date createdAt;

    @TableField("updated_at")
    private Date updatedAt;
}
