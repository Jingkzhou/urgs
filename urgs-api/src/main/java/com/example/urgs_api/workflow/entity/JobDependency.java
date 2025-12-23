package com.example.urgs_api.workflow.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName("sys_job_dependency")
public class JobDependency {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long workflowId;
    private String parentJobName;
    private String childJobName;
    private Long projectId;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getWorkflowId() {
        return workflowId;
    }

    public void setWorkflowId(Long workflowId) {
        this.workflowId = workflowId;
    }

    public String getParentJobName() {
        return parentJobName;
    }

    public void setParentJobName(String parentJobName) {
        this.parentJobName = parentJobName;
    }

    public String getChildJobName() {
        return childJobName;
    }

    public void setChildJobName(String childJobName) {
        this.childJobName = childJobName;
    }

    public Long getProjectId() {
        return projectId;
    }

    public void setProjectId(Long projectId) {
        this.projectId = projectId;
    }
}
