package com.example.urgs_api.metric.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("t_metric_data")
public class MetricData {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String systemId;
    private String typeCode;
    private BigDecimal metricValue;
    private LocalDateTime metricTime;
    private LocalDateTime createdAt;
}
