package com.example.executor.quartz.domain.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class ExecutorStopTaskResultDTO {
    private boolean foundRunningTask;
    private boolean cancelled;
    private String taskKey;
}
