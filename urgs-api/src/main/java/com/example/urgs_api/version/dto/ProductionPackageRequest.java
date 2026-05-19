package com.example.urgs_api.version.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class ProductionPackageRequest {
    private Long repoId;
    private Long ssoId;
    private String gitRef;
    private String previousGitRef;
    private String requirementNumber;
    private String description;
    private Long createdBy;
    private Long envId;
}
