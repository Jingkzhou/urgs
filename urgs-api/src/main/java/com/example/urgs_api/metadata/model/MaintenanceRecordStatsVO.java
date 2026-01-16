package com.example.urgs_api.metadata.model;

import lombok.Data;

@Data
public class MaintenanceRecordStatsVO {
    private Integer totalThisMonth;
    private Integer addCount;
    private Integer updateCount;
    private Integer deleteCount;
    private String trend; // e.g. "+12%"
}
