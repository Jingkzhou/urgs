package com.example.urgs_api.version.dto;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AppBranchStatsVO {
    private String branchName;
    private String author;
    private String lastCommitTime;
    private String status; // ACTIVE, STALE, MERGED
    private Integer behindCount;
    private Integer aheadCount;
}
