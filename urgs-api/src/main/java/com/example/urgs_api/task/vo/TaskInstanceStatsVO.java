package com.example.urgs_api.task.vo;

import lombok.Data;

@Data
public class TaskInstanceStatsVO {
    private long total;
    private long success;
    private long failed;
    private long running;
    private long waiting;
    private double successRate;
}
