package com.example.urgs_api.quartz.domain.dto;

import lombok.Data;

import java.util.List;

@Data
public class QuartzBlockingPathPageVO {

    private Long pageNum;

    private Long pageSize;

    private Long total;

    private Long pages;

    private List<List<QuartzDependencyImpactItemVO>> list;
}
