package com.example.urgs_api.metadata.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.metadata.model.MaintenanceRecord;
import com.example.urgs_api.metadata.model.MaintenanceRecordStatsVO;
import com.example.urgs_api.metadata.model.MaintenanceStatsDetailVO;
import com.example.urgs_api.metadata.model.ReqSummaryVO;

import java.util.List;

/**
 * 维护记录服务接口
 */
public interface MaintenanceRecordService extends IService<MaintenanceRecord> {
    /**
     * 获取本月维护记录统计信息
     *
     * @return 统计信息
     */
    MaintenanceRecordStatsVO getStats();

    /**
     * 获取详细统计数据（按系统、操作人、类型分组 + 趋势）
     *
     * @param startDate 开始日期
     * @param endDate   结束日期
     * @return 详细统计
     */
    MaintenanceStatsDetailVO getStatsDetail(String startDate, String endDate);

    /**
     * 获取需求变更汇总列表
     *
     * @param startDate 开始日期
     * @param endDate   结束日期
     * @return 需求汇总列表
     */
    List<ReqSummaryVO> getReqSummary(String startDate, String endDate);
}
