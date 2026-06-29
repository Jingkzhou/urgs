package com.example.urgs_api.metadata.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.metadata.mapper.MaintenanceRecordMapper;
import com.example.urgs_api.metadata.model.MaintenanceRecord;
import com.example.urgs_api.metadata.model.MaintenanceRecordStatsVO;
import com.example.urgs_api.metadata.model.MaintenanceStatsDetailVO;
import com.example.urgs_api.metadata.model.MaintenanceStatsDetailVO.GroupCount;
import com.example.urgs_api.metadata.model.MaintenanceStatsDetailVO.TrendItem;
import com.example.urgs_api.metadata.model.ReqSummaryVO;
import com.example.urgs_api.metadata.service.MaintenanceRecordService;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
/**
 * 维护记录服务实现类
 */
public class MaintenanceRecordServiceImpl extends ServiceImpl<MaintenanceRecordMapper, MaintenanceRecord>
        implements MaintenanceRecordService {

    @Override
    public MaintenanceRecordStatsVO getStats(String startDate, String endDate) {
        LocalDateTime rangeStart;
        LocalDateTime rangeEnd;
        if (StringUtils.hasText(startDate) && StringUtils.hasText(endDate)) {
            rangeStart = LocalDate.parse(startDate).atStartOfDay();
            rangeEnd = LocalDate.parse(endDate).atTime(23, 59, 59);
        } else {
            LocalDateTime now = LocalDateTime.now();
            rangeStart = now.with(TemporalAdjusters.firstDayOfMonth()).withHour(0).withMinute(0)
                    .withSecond(0).withNano(0);
            rangeEnd = now;
        }

        long rangeDays = java.time.temporal.ChronoUnit.DAYS.between(
                rangeStart.toLocalDate(),
                rangeEnd.toLocalDate()) + 1;
        LocalDateTime previousRangeStart = rangeStart.minusDays(rangeDays);
        LocalDateTime previousRangeEnd = rangeStart.minusNanos(1);

        MaintenanceRecordStatsVO stats = new MaintenanceRecordStatsVO();

        // 当前筛选范围统计
        stats.setTotalThisMonth((int) count(new LambdaQueryWrapper<MaintenanceRecord>()
                .ge(MaintenanceRecord::getTime, rangeStart)
                .le(MaintenanceRecord::getTime, rangeEnd)));

        // Add: CREATE or contains "新增"
        stats.setAddCount((int) count(new LambdaQueryWrapper<MaintenanceRecord>()
                .ge(MaintenanceRecord::getTime, rangeStart)
                .le(MaintenanceRecord::getTime, rangeEnd)
                .and(w -> w.eq(MaintenanceRecord::getModType, "CREATE").or()
                        .like(MaintenanceRecord::getModType, "新增"))));

        // Update: UPDATE or contains "修改"
        stats.setUpdateCount((int) count(new LambdaQueryWrapper<MaintenanceRecord>()
                .ge(MaintenanceRecord::getTime, rangeStart)
                .le(MaintenanceRecord::getTime, rangeEnd)
                .and(w -> w.eq(MaintenanceRecord::getModType, "UPDATE").or()
                        .like(MaintenanceRecord::getModType, "修改"))));

        // Delete: DELETE or contains "删除"
        stats.setDeleteCount((int) count(new LambdaQueryWrapper<MaintenanceRecord>()
                .ge(MaintenanceRecord::getTime, rangeStart)
                .le(MaintenanceRecord::getTime, rangeEnd)
                .and(w -> w.eq(MaintenanceRecord::getModType, "DELETE").or()
                        .like(MaintenanceRecord::getModType, "删除"))));

        // 与前一个等长时间范围比较
        long previousRangeTotal = count(new LambdaQueryWrapper<MaintenanceRecord>()
                .ge(MaintenanceRecord::getTime, previousRangeStart)
                .le(MaintenanceRecord::getTime, previousRangeEnd));

        if (previousRangeTotal > 0) {
            double increase = (double) (stats.getTotalThisMonth() - previousRangeTotal) / previousRangeTotal * 100;
            stats.setTrend(String.format("%+d%%", (int) increase));
        } else {
            stats.setTrend(stats.getTotalThisMonth() > 0 ? "+100%" : "0%");
        }

        return stats;
    }

    @Override
    public MaintenanceStatsDetailVO getStatsDetail(String startDate, String endDate) {
        // 解析日期范围，默认本月
        LocalDateTime start;
        LocalDateTime end;
        if (StringUtils.hasText(startDate) && StringUtils.hasText(endDate)) {
            start = LocalDate.parse(startDate).atStartOfDay();
            end = LocalDate.parse(endDate).atTime(23, 59, 59);
        } else {
            LocalDateTime now = LocalDateTime.now();
            start = now.with(TemporalAdjusters.firstDayOfMonth()).withHour(0).withMinute(0).withSecond(0).withNano(0);
            end = now;
        }

        // 查询范围内所有记录
        List<MaintenanceRecord> records = list(new LambdaQueryWrapper<MaintenanceRecord>()
                .ge(MaintenanceRecord::getTime, start)
                .le(MaintenanceRecord::getTime, end)
                .orderByAsc(MaintenanceRecord::getTime));

        MaintenanceStatsDetailVO vo = new MaintenanceStatsDetailVO();

        // 总数
        vo.setTotalCount(records.size());

        // 按变更类型统计
        int addCount = 0;
        int updateCount = 0;
        int deleteCount = 0;
        for (MaintenanceRecord r : records) {
            String modType = r.getModType() != null ? r.getModType() : "";
            if (modType.equals("CREATE") || modType.contains("新增")) {
                addCount++;
            } else if (modType.equals("UPDATE") || modType.contains("修改")) {
                updateCount++;
            } else if (modType.equals("DELETE") || modType.contains("删除")) {
                deleteCount++;
            }
        }
        vo.setAddCount(addCount);
        vo.setUpdateCount(updateCount);
        vo.setDeleteCount(deleteCount);

        // 按系统分组统计
        Map<String, Long> systemMap = records.stream()
                .collect(Collectors.groupingBy(
                        r -> StringUtils.hasText(r.getSystemCode()) ? r.getSystemCode() : "未分配系统",
                        Collectors.counting()));
        List<GroupCount> systemStats = systemMap.entrySet().stream()
                .map(e -> new GroupCount(e.getKey(), e.getValue().intValue()))
                .sorted((a, b) -> b.getValue() - a.getValue())
                .collect(Collectors.toList());
        vo.setSystemStats(systemStats);

        // 按操作人分组统计
        Map<String, Long> operatorMap = records.stream()
                .collect(Collectors.groupingBy(
                        r -> StringUtils.hasText(r.getOperator()) ? r.getOperator() : "未知",
                        Collectors.counting()));
        List<GroupCount> operatorStats = operatorMap.entrySet().stream()
                .map(e -> new GroupCount(e.getKey(), e.getValue().intValue()))
                .sorted((a, b) -> b.getValue() - a.getValue())
                .collect(Collectors.toList());
        vo.setOperatorStats(operatorStats);

        // 按变更类型分组统计
        Map<String, Long> modTypeMap = records.stream()
                .collect(Collectors.groupingBy(
                        r -> StringUtils.hasText(r.getModType()) ? r.getModType() : "其他",
                        Collectors.counting()));
        List<GroupCount> modTypeStats = modTypeMap.entrySet().stream()
                .map(e -> new GroupCount(e.getKey(), e.getValue().intValue()))
                .sorted((a, b) -> b.getValue() - a.getValue())
                .collect(Collectors.toList());
        vo.setModTypeStats(modTypeStats);

        // 每日趋势
        DateTimeFormatter dayFmt = DateTimeFormatter.ofPattern("MM-dd");
        Map<String, int[]> trendMap = new LinkedHashMap<>();

        // 初始化日期范围内的每一天
        LocalDate startDay = start.toLocalDate();
        LocalDate endDay = end.toLocalDate();
        for (LocalDate d = startDay; !d.isAfter(endDay); d = d.plusDays(1)) {
            trendMap.put(d.format(dayFmt), new int[3]); // [add, update, delete]
        }

        for (MaintenanceRecord r : records) {
            if (r.getTime() != null) {
                String day = r.getTime().format(dayFmt);
                int[] counts = trendMap.get(day);
                if (counts != null) {
                    String modType = r.getModType() != null ? r.getModType() : "";
                    if (modType.equals("CREATE") || modType.contains("新增")) {
                        counts[0]++;
                    } else if (modType.equals("UPDATE") || modType.contains("修改")) {
                        counts[1]++;
                    } else if (modType.equals("DELETE") || modType.contains("删除")) {
                        counts[2]++;
                    }
                }
            }
        }

        List<TrendItem> trend = new ArrayList<>();
        for (Map.Entry<String, int[]> entry : trendMap.entrySet()) {
            int[] counts = entry.getValue();
            trend.add(new TrendItem(entry.getKey(), counts[0], counts[1], counts[2]));
        }
        vo.setTrend(trend);

        return vo;
    }

    @Override
    public List<ReqSummaryVO> getReqSummary(String startDate, String endDate) {
        // 默认本月
        if (!StringUtils.hasText(startDate) || !StringUtils.hasText(endDate)) {
            LocalDateTime now = LocalDateTime.now();
            LocalDateTime firstDay = now.with(TemporalAdjusters.firstDayOfMonth())
                    .withHour(0).withMinute(0).withSecond(0).withNano(0);
            startDate = firstDay.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            endDate = now.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        } else {
            // 补全时间部分
            startDate = startDate + " 00:00:00";
            endDate = endDate + " 23:59:59";
        }

        return baseMapper.selectReqSummary(startDate, endDate);
    }
}
