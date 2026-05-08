package com.example.urgs_api.version.dto;

import lombok.Data;

@Data
public class ProductionPackageRequest {
    private Long repoId;
    private Long ssoId;
    private String gitRef;
    private String previousGitRef;
    private Long assetId;
    private String execUser;
    private String description;
    private Long createdBy;
    private Long envId;
}
