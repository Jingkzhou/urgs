package com.example.urgs_api.task.vo;

import lombok.Data;

@Data
public class WorkflowStatsVO {
    private String workflowName;
    private long total;
    private long completed;
    private long running;
    private long waiting;
    private long failed;
}
