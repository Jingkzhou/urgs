package com.example.urgs_api.version.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GitCommitDiff {
    private String oldPath;
    private String newPath;
    private String status; // "added", "modified", "removed", "renamed"
    private Boolean newFile;
    private Boolean renamedFile;
    private Boolean deletedFile;
    private Integer additions;
    private Integer deletions;
    private String diff; // The patch/diff content
}
