package com.example.urgs_api.quartz.support.domain;

import lombok.Data;

import java.util.Date;

@Data
public class BaseEntity {
    private Long id;
    private Date createTime;
    private Date updateTime;
}
