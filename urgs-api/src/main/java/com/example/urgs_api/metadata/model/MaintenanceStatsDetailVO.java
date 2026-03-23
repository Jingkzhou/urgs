package com.example.urgs_api.metadata.model;

import lombok.Data;

import java.util.List;

/**
 * 维护记录详细统计 VO
 * 包含按系统、操作人、变更类型分组的统计数据及每日趋势
 */
@Data
public class MaintenanceStatsDetailVO {

    /** 按系统分组统计 */
    private List<GroupCount> systemStats;

    /** 按操作人分组统计 */
    private List<GroupCount> operatorStats;

    /** 按变更类型分组统计 */
    private List<GroupCount> modTypeStats;

    /** 每日变更趋势 */
    private List<TrendItem> trend;

    /** 总变更数 */
    private Integer totalCount;

    /** 新增数 */
    private Integer addCount;

    /** 修改数 */
    private Integer updateCount;

    /** 删除数 */
    private Integer deleteCount;

    @Data
    public static class GroupCount {
        private String name;
        private Integer value;

        public GroupCount() {}

        public GroupCount(String name, Integer value) {
            this.name = name;
            this.value = value;
        }
    }

    @Data
    public static class TrendItem {
        private String period;
        private Integer addCount;
        private Integer updateCount;
        private Integer deleteCount;

        public TrendItem() {}

        public TrendItem(String period, Integer addCount, Integer updateCount, Integer deleteCount) {
            this.period = period;
            this.addCount = addCount;
            this.updateCount = updateCount;
            this.deleteCount = deleteCount;
        }
    }
}
