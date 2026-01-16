package com.example.urgs_api.version.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GitPullRequest {
    private String id;
    private Long number;
    private String title;
    private String state; // open, closed, merged, locked
    private String body;
    private String htmlUrl;

    private String headRef; // source branch
    private String headSha;
    private String baseRef; // target branch
    private String baseSha;

    // User info
    private String authorName;
    private String authorAvatar;

    // Dates
    private String createdAt;
    private String updatedAt;
    private String closedAt;
    private String mergedAt;

    // Stats
    private Integer comments;
    private Integer reviewComments;
    private Integer commits;
    private Integer additions;
    private Integer deletions;
    private Integer changedFiles;

    private List<Label> labels;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Label {
        private String name;
        private String color;
        private String description;
    }
}
