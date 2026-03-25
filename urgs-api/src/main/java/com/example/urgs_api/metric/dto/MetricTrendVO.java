package com.example.urgs_api.metric.dto;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class MetricTrendVO {
    private String timeLabel;
    private BigDecimal avgValue;
    private BigDecimal maxValue;
    private BigDecimal minValue;
}
