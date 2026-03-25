package com.example.urgs_api.ops.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DockerOperationResultDTO {
    private boolean success;
    private String containerId;
    private String operation;
    private String message;
}
