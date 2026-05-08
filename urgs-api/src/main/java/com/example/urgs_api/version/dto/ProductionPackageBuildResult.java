package com.example.urgs_api.version.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class ProductionPackageBuildResult {
    private Long packageId;
    private String packageName;
    private Long packageSize;
    private String deployCommand;
    private String rollbackCommand;
    private ProductionPackageGateResult gateResult;
}
