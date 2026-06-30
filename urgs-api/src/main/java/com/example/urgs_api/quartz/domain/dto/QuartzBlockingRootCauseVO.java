package com.example.urgs_api.quartz.domain.dto;

import lombok.Data;

import java.util.List;

@Data
public class QuartzBlockingRootCauseVO {

    private QuartzDependencyImpactItemVO root;

    private Long pathCount;

    private Integer level;

    private List<QuartzDependencyImpactItemVO> representativePath;
}
