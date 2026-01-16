package com.example.urgs_api.version.service;

import com.example.urgs_api.version.dto.DeveloperKpiVO;
import com.example.urgs_api.version.dto.VersionOverviewVO;
import java.util.List;
import java.util.Map;

/**
 * 版本统计服务接口
 * 提供开发人员绩效、质量趋势及版本概览统计
 */
public interface VersionStatsService {
    /**
     * 获取开发人员 KPI 统计
     * 
     * @param systemId 系统 ID
     * @return 开发人员 KPI 列表
     */
    List<DeveloperKpiVO> getDeveloperKpis(Long systemId);

    /**
     * 获取质量趋势数据
     * 
     * @param userId 用户 ID
     * @return 质量趋势 Map 数据
     */
    Map<String, Object> getQualityTrend(Long userId);

    /**
     * 获取版本概览统计
     * 
     * @return 版本概览 VO
     */
    VersionOverviewVO getOverviewStats();
}
