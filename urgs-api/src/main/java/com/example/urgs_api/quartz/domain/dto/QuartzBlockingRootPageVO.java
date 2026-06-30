package com.example.urgs_api.quartz.domain.dto;

import lombok.Data;

import java.util.List;

@Data
public class QuartzBlockingRootPageVO {

    private Long pageNum;

    private Long pageSize;

    private Long total;

    private Long pages;

    private List<QuartzBlockingRootCauseVO> list;

    private Integer blockingNodeCount;

    private Integer maxLevel;

    private Integer failedRootCount;

    private Boolean truncated;
}
