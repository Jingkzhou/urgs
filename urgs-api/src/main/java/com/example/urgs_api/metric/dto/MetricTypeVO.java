package com.example.urgs_api.metric.dto;

import lombok.Data;

@Data
public class MetricTypeVO {
    private String typeCode;
    private String typeName;
    private String unit;
    private String color;
    private Integer sortOrder;
}
