package com.example.urgs_api.quartz.domain.dto;

import lombok.Data;

import java.util.List;

@Data
public class ExecutorPoolStatsVO {

    private int activeCount;
    private int poolSize;
    private int maximumPoolSize;
    private int queueSize;
    private int queueCapacity;
    private long completedTaskCount;
    private List<String> runningTaskKeys;
}
