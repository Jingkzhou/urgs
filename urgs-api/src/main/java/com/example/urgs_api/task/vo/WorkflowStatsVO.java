package com.example.urgs_api.task.vo;

import lombok.Data;

@Data
public class WorkflowStatsVO {
    private String workflowName;
    private long total;
    private long success;
    private long failed;
}
