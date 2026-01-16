package com.example.urgs_api.version.service;

import com.example.urgs_api.version.dto.AppEnvironmentMatrixVO;
import com.example.urgs_api.version.dto.AppBranchStatsVO;
import java.util.List;

/**
 * 应用系统版本服务接口
 * 定义版本相关的业务操作
 */
public interface AppSystemVersionService {
    /**
     * 获取环境版本矩阵
     * 
     * @param systemId 系统 ID
     * @return 环境版本矩阵列表
     */
    List<AppEnvironmentMatrixVO> getEnvironmentMatrix(Long systemId);

    /**
     * 获取分支治理统计
     * 
     * @param systemId 系统 ID
     * @return 分支统计列表
     */
    List<AppBranchStatsVO> getBranchGovernance(Long systemId);
}
