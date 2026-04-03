package com.example.urgs_api.quartz.domain.dto;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;
import lombok.Data;

import javax.validation.constraints.NotEmpty;
import java.util.List;

@Data
@ApiModel("批量强制通过任务实例请求")
public class QuartzBatchForcePassDTO {

    @NotEmpty(message = "请选择需要强制通过的实例")
    @ApiModelProperty("任务实例ID列表")
    private List<Long> statusIds;
}
