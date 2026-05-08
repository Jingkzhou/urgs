package com.example.urgs_api.version.dto;

import lombok.Data;

@Data
public class OfflineDeploymentResultRequest {
    private Long ssoId;
    private Long envId;
    private Long packageId;
    private String status;
    private Long deployedBy;
    private String logs;
    private String remark;
}
