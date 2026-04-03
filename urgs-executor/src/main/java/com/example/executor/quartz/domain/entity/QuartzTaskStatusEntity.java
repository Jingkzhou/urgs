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
    private Date createTime;
    private Date updateTime;
}
