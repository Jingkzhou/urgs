package com.example.urgs_api.quartz.domain.dto;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;
import lombok.Data;

import javax.validation.constraints.NotEmpty;
import java.util.List;

@Data
@ApiModel("批量执行任务实例请求")
public class QuartzBatchExecuteDTO {

    @NotEmpty(message = "请选择需要批量执行的实例")
    @ApiModelProperty("任务实例ID列表")
    private List<Long> statusIds;

    @ApiModelProperty("是否沿数据依赖级联重跑下游")
    private Boolean withDataDownstream;
}
