package com.example.urgs_api.metadata.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.metadata.model.MaintenanceRecord;

import com.example.urgs_api.metadata.model.MaintenanceRecordStatsVO;

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
}
