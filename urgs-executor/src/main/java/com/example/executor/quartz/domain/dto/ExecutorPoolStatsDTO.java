package com.example.executor.quartz.domain.dto;

import java.util.List;

public record ExecutorPoolStatsDTO(
        int activeCount,
        int poolSize,
        int maximumPoolSize,
        int queueSize,
        int queueCapacity,
        long completedTaskCount,
        List<String> runningTaskKeys,
        List<String> queuedTaskKeys
) {
    public ExecutorPoolStatsDTO {
        runningTaskKeys = runningTaskKeys == null ? List.of() : List.copyOf(runningTaskKeys);
        queuedTaskKeys = queuedTaskKeys == null ? List.of() : List.copyOf(queuedTaskKeys);
    }
}
