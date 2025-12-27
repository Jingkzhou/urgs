package com.example.urgs_api.version.service.impl;

import com.example.urgs_api.version.dto.AppEnvironmentMatrixVO;
import com.example.urgs_api.version.dto.AppBranchStatsVO;
import com.example.urgs_api.version.service.AppSystemVersionService;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

@Service
public class AppSystemVersionServiceImpl implements AppSystemVersionService {

    @Override
    public List<AppEnvironmentMatrixVO> getEnvironmentMatrix(Long systemId) {
        // Mock data logic for prototype
        List<AppEnvironmentMatrixVO> matrix = new ArrayList<>();

        // SIT
        matrix.add(AppEnvironmentMatrixVO.builder()
                .envName("SIT")
                .version("v2.1.0-RC3")
                .status("SUCCESS")
                // .plotTime("2025-12-26 14:30") // Removed undefined field
                .deployTime("2025-12-26 14:30")
                .commitLag(0)
                .branch("develop")
                .build());

        // UAT
        matrix.add(AppEnvironmentMatrixVO.builder()
                .envName("UAT")
                .version("v2.1.0-RC1")
                .status("SUCCESS")
                .deployTime("2025-12-24 10:00")
                .commitLag(12)
                .branch("release/v2.1.0")
                .build());

        // PROD
        matrix.add(AppEnvironmentMatrixVO.builder()
                .envName("PROD")
                .version("v2.0.5")
                .status("SUCCESS")
                .deployTime("2025-12-10 22:00")
                .commitLag(45)
                .branch("master")
                .build());

        return matrix;
    }

    @Override
    public List<AppBranchStatsVO> getBranchGovernance(Long systemId) {
        // Mock data logic
        return Arrays.asList(
                AppBranchStatsVO.builder()
                        .branchName("feat/user-kpi")
                        .author("Wang Xiao")
                        .lastCommitTime("2 hours ago")
                        .status("ACTIVE")
                        .behindCount(2)
                        .aheadCount(5)
                        .build(),
                AppBranchStatsVO.builder()
                        .branchName("fix/login-bug")
                        .author("Li Lei")
                        .lastCommitTime("3 days ago")
                        .status("ACTIVE")
                        .behindCount(0)
                        .aheadCount(1)
                        .build(),
                AppBranchStatsVO.builder()
                        .branchName("feat/old-payment")
                        .author("Zhang San")
                        .lastCommitTime("3 months ago")
                        .status("STALE")
                        .behindCount(100)
                        .aheadCount(3)
                        .build());
    }
}
