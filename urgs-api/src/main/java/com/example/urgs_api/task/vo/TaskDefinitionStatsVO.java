package com.example.urgs_api.task.vo;

import lombok.Data;

@Data
public class TaskDefinitionStatsVO {
    private long total;
    private long enabled;
    private long disabled;
    private long systems;
    private long workflows;
}
