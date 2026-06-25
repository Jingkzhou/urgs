package com.example.urgs_api.quartz.domain.dto;

import com.example.urgs_api.quartz.support.domain.PageParamDTO;
import lombok.Data;

@Data
public class QuartzDependencyImpactQueryDTO extends PageParamDTO {

    private Long statusId;

    private Long planId;

    private String dataDate;

    private String keyword;

    private String status;

    private Boolean impactedOnly;
}
