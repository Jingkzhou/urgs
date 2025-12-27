package com.example.urgs_api.task.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import java.time.LocalDateTime;

@TableName("sys_task")
public class Task {
    @TableId(type = IdType.ASSIGN_ID) // Use MyBatis Plus ID generator or manual assignment
    private String id;

    private String name;
    private String type;
    private String content; // JSON content
    private Long systemId; // Associated System ID
    private LocalDateTime createTime;
    private LocalDateTime updateTime;

    private String cronExpression;
    private String dataDateRule;
    private Integer status; // 1: Enable, 0: Disable
    private LocalDateTime lastTriggerTime;
    private Integer priority;

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public Long getSystemId() {
        return systemId;
    }

    public void setSystemId(Long systemId) {
        this.systemId = systemId;
    }

    public String getCronExpression() {
        return cronExpression;
    }

    public void setCronExpression(String cronExpression) {
        this.cronExpression = cronExpression;
    }

    public String getDataDateRule() {
        return dataDateRule;
    }

    public void setDataDateRule(String dataDateRule) {
        this.dataDateRule = dataDateRule;
    }

    public Integer getStatus() {
        return status;
    }

    public void setStatus(Integer status) {
        this.status = status;
    }

    public LocalDateTime getLastTriggerTime() {
        return lastTriggerTime;
    }

    public void setLastTriggerTime(LocalDateTime lastTriggerTime) {
        this.lastTriggerTime = lastTriggerTime;
    }

    public Integer getPriority() {
        return priority;
    }

    public void setPriority(Integer priority) {
        this.priority = priority;
    }

    public LocalDateTime getCreateTime() {
        return createTime;
    }

    public void setCreateTime(LocalDateTime createTime) {
        this.createTime = createTime;
    }

    public LocalDateTime getUpdateTime() {
        return updateTime;
    }

    public void setUpdateTime(LocalDateTime updateTime) {
        this.updateTime = updateTime;
    }
}
