package com.example.urgs_api.version.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class GitProjectVO {
    private String id; // Project ID (String for compatibility)
    private String name; // Project Name
    private String pathWithNamespace; // full_path (e.g. group/project)
    private String description;
    private String webUrl; // HTML URL
    private String cloneUrl; // HTTP Clone URL
    private String sshUrl; // SSH Clone URL
    private String defaultBranch;
    private String visibility; // private, public
    private String lastActivityAt;
}
