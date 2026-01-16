package com.example.urgs_api.issue.dto;

import lombok.Data;
import java.math.BigDecimal;
import java.util.List;

@Data
public class IssueStatsDTO {
    // 按状态统计
    private List<StatItem> statusStats;

    // 按问题类型统计
    private List<StatItem> typeStats;

    // 按归属系统统计
    private List<StatItem> systemStats;

    // 按处理人统计工时
    private List<HandlerStats> handlerStats;

    // 按时间频度统计趋势
    private List<TrendItem> trend;

    // 总数统计
    private long totalCount;
    private long newCount;
    private long inProgressCount;
    private long completedCount;
    private long leftoverCount;
    private BigDecimal totalWorkHours;

    @Data
    public static class StatItem {
        private String name;
        private long value;

        public StatItem(String name, long value) {
            this.name = name;
            this.value = value;
        }
    }

    @Data
    public static class HandlerStats {
        private String handler;
        private long issueCount;
        private BigDecimal totalWorkHours;

        public HandlerStats(String handler, long issueCount, BigDecimal totalWorkHours) {
            this.handler = handler;
            this.issueCount = issueCount;
            this.totalWorkHours = totalWorkHours;
        }
    }

    @Data
    public static class TrendItem {
        private String period;
        private long count;

        public TrendItem(String period, long count) {
            this.period = period;
            this.count = count;
        }
    }
}
