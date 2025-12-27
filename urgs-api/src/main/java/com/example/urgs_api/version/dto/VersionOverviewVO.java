package com.example.urgs_api.version.dto;

import lombok.Data;
import java.util.List;

@Data
public class VersionOverviewVO {
    private Long totalApps;
    private Long totalReleases;
    private Long thisMonthReleases;
    private Long pendingReleases;
    private Double successRate;
    private List<RecentReleaseVO> recentReleases;

    @Data
    public static class RecentReleaseVO {
        private Long id;
        private String appName;
        private String version;
        private String releaseDate;
        private String status;
    }
}
