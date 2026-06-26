package com.example.executor.quartz.domain.entity;

import lombok.Data;

@Data
public class DataSourcePoolMemberEntity {

    private Long poolId;
    private String poolName;
    private String strategy;
    private Long datasourceId;
    private String datasourceName;
    private Integer enabled;
    private Integer weight;
    private Integer maxConcurrency;
    private Integer sortNo;
    private Integer runningCount;
}
