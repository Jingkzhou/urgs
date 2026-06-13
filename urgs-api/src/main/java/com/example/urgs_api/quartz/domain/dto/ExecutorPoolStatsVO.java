package com.example.urgs_api.quartz.domain.dto;

import java.util.List;

public record ExecutorPoolStatsVO(
        int activeCount,
        int poolSize,
        int maximumPoolSize,
        int queueSize,
        int queueCapacity,
        long completedTaskCount,
        List<String> runningTaskKeys,
        List<String> queuedTaskKeys
) {
    public ExecutorPoolStatsVO {
        runningTaskKeys = runningTaskKeys == null ? List.of() : List.copyOf(runningTaskKeys);
        queuedTaskKeys = queuedTaskKeys == null ? List.of() : List.copyOf(queuedTaskKeys);
    }
}
