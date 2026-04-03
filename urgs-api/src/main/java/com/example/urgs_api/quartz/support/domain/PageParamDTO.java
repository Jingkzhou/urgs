package com.example.urgs_api.quartz.support.domain;

import lombok.Data;

@Data
public class PageParamDTO {
    private Integer pageNum = 1;
    private Integer pageSize = 10;
}
