package com.example.urgs_api.version.dto;

import lombok.Data;
import java.util.List;

@Data
public class GitImportRequest {
    private Long systemId;
    private List<GitProjectVO> projects;
}
