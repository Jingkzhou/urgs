package com.example.urgs_api.marketplace.dto;

import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Data
public class WorkStatisticsDTO {
    private LocalDate startDate;
    private LocalDate endDate;
    private Integer totalWorks;
    private Integer completedWorks;
    private Integer completedTasks;
    private Integer activeTasks;
    private Integer overdueTasks;
    private Integer riskTasks;
    private Integer completionRate;
    private List<GroupCount> workStatusDistribution = new ArrayList<>();
    private List<GroupCount> taskStatusDistribution = new ArrayList<>();
    private List<GroupCount> progressDistribution = new ArrayList<>();
    private List<TrendItem> completionTrend = new ArrayList<>();
    private List<AssigneeWorkload> assigneeWorkloads = new ArrayList<>();
    private List<AttentionItem> attentionItems = new ArrayList<>();

    @Data
    public static class GroupCount {
        private String name;
        private Integer value;
    }

    @Data
    public static class TrendItem {
        private LocalDate date;
        private Integer completedCount;
    }

    @Data
    public static class AssigneeWorkload {
        private String assigneeId;
        private Integer totalCount;
        private Integer completedCount;
        private Integer activeCount;
        private Integer overdueCount;
    }

    @Data
    public static class AttentionItem {
        private String workId;
        private String workTitle;
        private String taskId;
        private String taskTitle;
        private String assigneeId;
        private String status;
        private LocalDateTime deadline;
        private Boolean overdue;
        private Boolean riskReported;
        private String riskNote;
    }
}
