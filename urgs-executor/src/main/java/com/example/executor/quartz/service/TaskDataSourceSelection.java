package com.example.executor.quartz.service;

import com.example.executor.datasource.ResolvedDataSourceConfig;
import lombok.Data;

@Data
public class TaskDataSourceSelection {

    private Long poolId;
    private String poolName;
    private Long datasourceId;
    private String datasourceName;
    private ResolvedDataSourceConfig config;
}
