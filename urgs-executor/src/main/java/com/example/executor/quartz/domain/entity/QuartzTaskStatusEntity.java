package com.example.executor.quartz.domain.entity;

import lombok.Data;

import java.util.Date;

@Data
public class QuartzTaskStatusEntity {

    private Long id;
    private Long planId;
    private String dataDate;
    private Integer status;
    private Date beginTime;
    private Date endTime;
    private String msg;
    private Long executePoolId;
    private String executePoolName;
    private Long executeDatasourceId;
    private String executeDatasourceName;
    private Date createTime;
    private Date updateTime;
}
