package com.example.urgs_api.ops.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DockerLogDTO {
    private String id;
    private String timestamp;
    private String level;
    private String message;
    private String source;
}
