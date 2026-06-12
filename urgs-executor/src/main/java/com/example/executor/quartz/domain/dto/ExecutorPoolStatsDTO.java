package com.example.executor.quartz.domain.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.util.List;

@Data
@AllArgsConstructor
public class ExecutorPoolStatsDTO {

    private int activeCount;
    private int poolSize;
    private int maximumPoolSize;
    private int queueSize;
    private int queueCapacity;
    private long completedTaskCount;
    private List<String> runningTaskKeys;
}
