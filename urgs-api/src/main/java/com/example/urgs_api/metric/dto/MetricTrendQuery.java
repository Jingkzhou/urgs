package com.example.urgs_api.metric.dto;

import lombok.Data;

@Data
public class MetricTrendQuery {
    private String systemId;
    private String typeCode;
    private String startTime;
    private String endTime;
    private String granularity; // HOUR or DAY
}
