package com.example.executor.quartz.domain.dto;

import lombok.Data;

@Data
public class ExecutorStopTaskDTO {
    private Long planId;
    private String dataDate;
}
