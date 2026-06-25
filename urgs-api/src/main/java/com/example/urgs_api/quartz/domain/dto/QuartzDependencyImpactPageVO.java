package com.example.urgs_api.quartz.domain.dto;

import lombok.Data;

import java.util.List;

@Data
public class QuartzDependencyImpactPageVO {

    private Long pageNum;

    private Long pageSize;

    private Long total;

    private Long pages;

    private List<QuartzDependencyImpactItemVO> list;

    private Integer maxLevel;

    private Integer waitingCount;

    private Integer runningCount;

    private Integer successCount;

    private Integer failedCount;

    private Integer missingCount;

    private Integer impactedCount;
}
