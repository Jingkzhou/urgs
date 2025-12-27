package com.example.urgs_api.version.service;

import com.example.urgs_api.version.dto.AppEnvironmentMatrixVO;
import com.example.urgs_api.version.dto.AppBranchStatsVO;
import java.util.List;

public interface AppSystemVersionService {
    List<AppEnvironmentMatrixVO> getEnvironmentMatrix(Long systemId);

    List<AppBranchStatsVO> getBranchGovernance(Long systemId);
}
