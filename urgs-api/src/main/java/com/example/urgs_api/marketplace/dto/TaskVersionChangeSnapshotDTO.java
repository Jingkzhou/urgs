package com.example.urgs_api.marketplace.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class TaskVersionChangeSnapshotDTO {
    private Long id;
    private String taskId;
    private String workId;
    private String requirementNumber;
    private String assigneeId;
    private String reviewerId;
    private Long repoId;
    private String repoName;
    private Long prNumber;
    private String prTitle;
    private String prUrl;
    private String sourceBranch;
    private String targetBranch;
    private String state;
    private Boolean merged;
    private String mergedAt;
    private String matchSource;
    private Integer commitCount;
    private Integer fileCount;
    private Integer additions;
    private Integer deletions;
    private String snapshotJson;
    private LocalDateTime createdAt;
}
