package com.example.urgs_api.metric.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("t_metric_type")
public class MetricType {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String systemId;
    private String typeCode;
    private String typeName;
    private String unit;
    private String color;
    private Integer sortOrder;
    private Integer status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
