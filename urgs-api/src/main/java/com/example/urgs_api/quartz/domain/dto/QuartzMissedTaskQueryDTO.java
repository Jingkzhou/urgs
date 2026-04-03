package com.example.urgs_api.quartz.domain.dto;

import lombok.Data;
import com.example.urgs_api.quartz.support.domain.PageParamDTO;

import javax.validation.constraints.NotNull;

@Data
public class QuartzMissedTaskQueryDTO extends PageParamDTO {

    @NotNull(message = "开始日期不能为空")
    private String startDate;

    @NotNull(message = "结束日期不能为空")
    private String endDate;

    private String taskName;

    private String taskSystem;

    private String theme;
}
