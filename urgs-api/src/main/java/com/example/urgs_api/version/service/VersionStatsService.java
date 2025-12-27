package com.example.urgs_api.version.service;

import com.example.urgs_api.version.dto.DeveloperKpiVO;
import java.util.List;
import java.util.Map;

public interface VersionStatsService {
    List<DeveloperKpiVO> getDeveloperKpis(Long systemId);

    Map<String, Object> getQualityTrend(Long userId);
}
