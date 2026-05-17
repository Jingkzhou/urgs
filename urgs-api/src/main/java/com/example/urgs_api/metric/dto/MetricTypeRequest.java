package com.example.urgs_api.metric.dto;

import lombok.Data;

@Data
public class MetricTypeRequest {
    private String systemId;
    private String typeCode;
    private String typeName;
    private String unit;
    private String color;
    private String defaultChartType;
    private String supportedChartTypes;
    private Integer sortOrder;
    private Integer status;
}
