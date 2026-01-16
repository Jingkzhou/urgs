package com.example.urgs_api.metadata.dto;

import lombok.Data;
import java.util.List;

@Data
public class StartEngineRequest {
    private Long repoId;
    private String ref;
    private List<String> paths;
    private String user;
    private String language;
}
