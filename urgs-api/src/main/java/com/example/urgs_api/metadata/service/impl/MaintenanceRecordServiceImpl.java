package com.example.urgs_api.metadata.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.metadata.mapper.MaintenanceRecordMapper;
import com.example.urgs_api.metadata.model.MaintenanceRecord;
import com.example.urgs_api.metadata.service.MaintenanceRecordService;
import org.springframework.stereotype.Service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.metadata.model.MaintenanceRecordStatsVO;

import java.time.LocalDateTime;
import java.time.temporal.TemporalAdjusters;

@Service
/**
 * 维护记录服务实现类
 */
public class MaintenanceRecordServiceImpl extends ServiceImpl<MaintenanceRecordMapper, MaintenanceRecord>
        implements MaintenanceRecordService {

    @Override
    public MaintenanceRecordStatsVO getStats() {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime firstDayOfMonth = now.with(TemporalAdjusters.firstDayOfMonth()).withHour(0).withMinute(0)
                .withSecond(0).withNano(0);
        LocalDateTime firstDayOfLastMonth = firstDayOfMonth.minusMonths(1);

        MaintenanceRecordStatsVO stats = new MaintenanceRecordStatsVO();

        // This Month Stats
        stats.setTotalThisMonth((int) count(new LambdaQueryWrapper<MaintenanceRecord>()
                .ge(MaintenanceRecord::getTime, firstDayOfMonth)));

        stats.setAddCount((int) count(new LambdaQueryWrapper<MaintenanceRecord>()
                .ge(MaintenanceRecord::getTime, firstDayOfMonth)
                .like(MaintenanceRecord::getModType, "新增")));

        stats.setUpdateCount((int) count(new LambdaQueryWrapper<MaintenanceRecord>()
                .ge(MaintenanceRecord::getTime, firstDayOfMonth)
                .like(MaintenanceRecord::getModType, "修改")));

        stats.setDeleteCount((int) count(new LambdaQueryWrapper<MaintenanceRecord>()
                .ge(MaintenanceRecord::getTime, firstDayOfMonth)
                .like(MaintenanceRecord::getModType, "删除")));

        // Last Month Total for trend
        long totalLastMonth = count(new LambdaQueryWrapper<MaintenanceRecord>()
                .ge(MaintenanceRecord::getTime, firstDayOfLastMonth)
                .lt(MaintenanceRecord::getTime, firstDayOfMonth));

        if (totalLastMonth > 0) {
            double increase = (double) (stats.getTotalThisMonth() - totalLastMonth) / totalLastMonth * 100;
            stats.setTrend(String.format("%+d%%", (int) increase));
        } else {
            stats.setTrend("+100%");
        }

        return stats;
    }
}
