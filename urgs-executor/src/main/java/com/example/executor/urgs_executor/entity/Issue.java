package com.example.executor.urgs_executor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("sys_issue")
public class Issue {
    @TableId(type = IdType.ASSIGN_ID)
    private String id;

    private String title;
    private String description;
    @TableField("`system`")
    private String system;
    private LocalDateTime occurTime;
    private String reporter;
    private LocalDateTime resolveTime;
    private String handler;
    private String issueType;
    private String status;
    private BigDecimal workHours;
    private LocalDateTime createTime;
    private String createBy;
    private LocalDateTime updateTime;
}
