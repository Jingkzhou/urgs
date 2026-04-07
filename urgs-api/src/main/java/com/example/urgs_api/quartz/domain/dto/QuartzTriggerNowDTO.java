package com.example.urgs_api.quartz.domain.dto;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;

@Data
public class QuartzTriggerNowDTO {

    @NotNull(message = "planId 不能为空")
    private Long planId;

    @NotBlank(message = "dataDate 不能为空")
    private String dataDate;
}
