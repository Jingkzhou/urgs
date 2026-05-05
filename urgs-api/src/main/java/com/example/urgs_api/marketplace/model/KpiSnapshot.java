package com.example.urgs_api.marketplace.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("sys_kpi_snapshot")
public class KpiSnapshot {
    @TableId(type = IdType.ASSIGN_ID)
    private String id;

    private String period;
    private String userId;
    private String userName;
    private Integer completedTaskCount;
    private Integer basePoints;
    private Integer finalPoints;
    private Double onTimeRate;
    private Double averageQualityScore;
    private Integer reworkCount;
    private Integer overdueCount;
    private Integer highPriorityTaskCount;
    private Integer activeTaskCount;
    private String status;
    private String generatedBy;
    private LocalDateTime generatedAt;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
