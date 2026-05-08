package com.example.urgs_api.version.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductionPackageGateResult {
    private Long repoId;
    private String gitRef;
    private String previousGitRef;
    private String packageType;
    private String specPath;
    private String status;
    private String summary;
    private String deployCommand;
    private String rollbackCommand;
    private ReleaseSpec.DatabaseSpec database;
    @Builder.Default
    private List<GateItem> gates = new ArrayList<>();
    @Builder.Default
    private List<String> includedFiles = new ArrayList<>();
    @Builder.Default
    private List<String> backupTables = new ArrayList<>();
    private ChangeSummary changeSummary;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GateItem {
        private String key;
        private String label;
        private String status;
        private String message;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ChangeSummary {
        @Builder.Default
        private List<String> sqlFiles = new ArrayList<>();
        @Builder.Default
        private List<String> procedureFiles = new ArrayList<>();
        @Builder.Default
        private List<String> backupFiles = new ArrayList<>();
        @Builder.Default
        private List<String> rollbackFiles = new ArrayList<>();
        @Builder.Default
        private List<String> otherFiles = new ArrayList<>();
    }
}
