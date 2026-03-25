package com.example.urgs_api.ops.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DockerContainerStatsDTO {
    private String containerId;
    private String containerName;
    private String cpuPercent;
    private String memUsage;
    private String memLimit;
    private String netIO;
    private String blockIO;
}
