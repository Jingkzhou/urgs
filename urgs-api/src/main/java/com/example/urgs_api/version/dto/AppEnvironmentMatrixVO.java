package com.example.urgs_api.version.dto;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AppEnvironmentMatrixVO {
    private String envName; // SIT, UAT, PROD
    private String version; // v1.2.0
    private String status; // SUCCESS, PENDING
    private String deployTime;
    private Integer commitLag; // Commits behind main/prod
    private String branch; // develop, release/v1.2, master
}
