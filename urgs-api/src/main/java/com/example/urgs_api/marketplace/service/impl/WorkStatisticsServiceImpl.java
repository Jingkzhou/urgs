package com.example.urgs_api.marketplace.service.impl;

import com.example.urgs_api.marketplace.dto.WorkStatisticsDTO;
import com.example.urgs_api.marketplace.enums.TaskStatus;
import com.example.urgs_api.marketplace.enums.WorkStatus;
import com.example.urgs_api.marketplace.model.Work;
import com.example.urgs_api.marketplace.model.WorkTask;
import com.example.urgs_api.marketplace.service.WorkService;
import com.example.urgs_api.marketplace.service.WorkStatisticsService;
import com.example.urgs_api.marketplace.service.WorkTaskService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class WorkStatisticsServiceImpl implements WorkStatisticsService {
    private static final String UNASSIGNED = "UNASSIGNED";
    private static final Set<String> ACTIVE_TASK_STATUSES = Set.of(
            TaskStatus.IN_PROGRESS.name(),
            TaskStatus.WAITING_REVIEW.name(),
            TaskStatus.REWORK.name());
    private static final Set<String> CLOSED_TASK_STATUSES = Set.of(
            TaskStatus.COMPLETED.name(),
            TaskStatus.CANCELLED.name());

    @Autowired
    private WorkService workService;

    @Autowired
    private WorkTaskService workTaskService;

    @Override
    public WorkStatisticsDTO getStatistics(String userId, LocalDate startDate, LocalDate endDate) {
        LocalDateTime startAt = startDate.atStartOfDay();
        LocalDateTime endExclusive = endDate.plusDays(1).atStartOfDay();
        LocalDateTime now = LocalDateTime.now();

        List<Work> works = workService.lambdaQuery()
                .eq(Work::getPublisherId, userId)
                .ge(Work::getCreateTime, startAt)
                .lt(Work::getCreateTime, endExclusive)
                .list();
        Map<String, Work> workById = works.stream()
                .collect(Collectors.toMap(Work::getId, work -> work));
        List<WorkTask> tasks = works.isEmpty()
                ? List.of()
                : workTaskService.lambdaQuery()
                        .in(WorkTask::getWorkId, workById.keySet())
                        .list();

        WorkStatisticsDTO statistics = new WorkStatisticsDTO();
        statistics.setStartDate(startDate);
        statistics.setEndDate(endDate);
        statistics.setTotalWorks(works.size());
        statistics.setCompletedWorks((int) works.stream()
                .filter(work -> WorkStatus.COMPLETED.name().equals(normalizeStatus(work.getStatus())))
                .count());

        int completedTasks = (int) tasks.stream()
                .filter(this::isCompletedTask)
                .count();
        int activeTasks = (int) tasks.stream()
                .filter(task -> ACTIVE_TASK_STATUSES.contains(normalizeStatus(task.getStatus())))
                .count();
        int overdueTasks = (int) tasks.stream()
                .filter(task -> isOverdueTask(task, now))
                .count();
        int riskTasks = (int) tasks.stream()
                .filter(task -> Boolean.TRUE.equals(task.getStageRiskReported()))
                .count();
        long effectiveTaskCount = tasks.stream()
                .filter(task -> !TaskStatus.CANCELLED.name().equals(normalizeStatus(task.getStatus())))
                .count();

        statistics.setCompletedTasks(completedTasks);
        statistics.setActiveTasks(activeTasks);
        statistics.setOverdueTasks(overdueTasks);
        statistics.setRiskTasks(riskTasks);
        statistics.setCompletionRate(effectiveTaskCount == 0
                ? 0
                : (int) Math.round(completedTasks * 100.0 / effectiveTaskCount));

        statistics.setWorkStatusDistribution(buildStatusDistribution(
                works.stream().map(Work::getStatus).collect(Collectors.toList()),
                List.of("DRAFT", "PUBLISHED", "ACTIVE", "PAUSED", "ACCEPTANCE", "COMPLETED", "CANCELLED")));
        statistics.setTaskStatusDistribution(buildStatusDistribution(
                tasks.stream().map(WorkTask::getStatus).collect(Collectors.toList()),
                List.of("OPEN", "READY", "IN_PROGRESS", "PAUSED", "WAITING_REVIEW", "REWORK", "COMPLETED", "CANCELLED")));

        Map<String, List<WorkTask>> tasksByWorkId = tasks.stream()
                .collect(Collectors.groupingBy(WorkTask::getWorkId));
        statistics.setProgressDistribution(buildProgressDistribution(works, tasksByWorkId));
        statistics.setCompletionTrend(buildCompletionTrend(tasks, startDate, endDate));
        statistics.setAssigneeWorkloads(buildAssigneeWorkloads(tasks, now));
        statistics.setAttentionItems(buildAttentionItems(tasks, workById, now));
        return statistics;
    }

    private List<WorkStatisticsDTO.GroupCount> buildStatusDistribution(
            List<String> sourceStatuses,
            List<String> statusOrder) {
        Map<String, Integer> counts = new LinkedHashMap<>();
        statusOrder.forEach(status -> counts.put(status, 0));
        sourceStatuses.forEach(status -> {
            String normalized = normalizeStatus(status);
            counts.put(normalized, counts.getOrDefault(normalized, 0) + 1);
        });
        return counts.entrySet().stream()
                .filter(entry -> entry.getValue() > 0)
                .map(entry -> {
                    WorkStatisticsDTO.GroupCount item = new WorkStatisticsDTO.GroupCount();
                    item.setName(entry.getKey());
                    item.setValue(entry.getValue());
                    return item;
                })
                .collect(Collectors.toList());
    }

    private List<WorkStatisticsDTO.GroupCount> buildProgressDistribution(
            List<Work> works,
            Map<String, List<WorkTask>> tasksByWorkId) {
        Map<String, Integer> counts = new LinkedHashMap<>();
        counts.put("未开始", 0);
        counts.put("推进中（1-49%）", 0);
        counts.put("接近完成（50-99%）", 0);
        counts.put("已完成", 0);
        counts.put("已取消", 0);

        works.forEach(work -> {
            if (WorkStatus.CANCELLED.name().equals(normalizeStatus(work.getStatus()))) {
                counts.put("已取消", counts.get("已取消") + 1);
                return;
            }
            List<WorkTask> workTasks = tasksByWorkId.getOrDefault(work.getId(), List.of());
            long effectiveCount = workTasks.stream()
                    .filter(task -> !TaskStatus.CANCELLED.name().equals(normalizeStatus(task.getStatus())))
                    .count();
            long completedCount = workTasks.stream()
                    .filter(this::isCompletedTask)
                    .count();
            int percent = effectiveCount == 0
                    ? 0
                    : (int) Math.round(completedCount * 100.0 / effectiveCount);
            String group = percent == 0
                    ? "未开始"
                    : percent < 50
                            ? "推进中（1-49%）"
                            : percent < 100 ? "接近完成（50-99%）" : "已完成";
            counts.put(group, counts.get(group) + 1);
        });

        return counts.entrySet().stream()
                .map(entry -> {
                    WorkStatisticsDTO.GroupCount item = new WorkStatisticsDTO.GroupCount();
                    item.setName(entry.getKey());
                    item.setValue(entry.getValue());
                    return item;
                })
                .collect(Collectors.toList());
    }

    private List<WorkStatisticsDTO.TrendItem> buildCompletionTrend(
            List<WorkTask> tasks,
            LocalDate startDate,
            LocalDate endDate) {
        Map<LocalDate, Integer> counts = new LinkedHashMap<>();
        for (LocalDate date = startDate; !date.isAfter(endDate); date = date.plusDays(1)) {
            counts.put(date, 0);
        }
        tasks.stream()
                .filter(this::isCompletedTask)
                .map(task -> task.getReviewedAt() != null ? task.getReviewedAt() : task.getUpdateTime())
                .filter(completedAt -> completedAt != null
                        && !completedAt.toLocalDate().isBefore(startDate)
                        && !completedAt.toLocalDate().isAfter(endDate))
                .forEach(completedAt -> counts.computeIfPresent(
                        completedAt.toLocalDate(),
                        (date, count) -> count + 1));

        return counts.entrySet().stream()
                .map(entry -> {
                    WorkStatisticsDTO.TrendItem item = new WorkStatisticsDTO.TrendItem();
                    item.setDate(entry.getKey());
                    item.setCompletedCount(entry.getValue());
                    return item;
                })
                .collect(Collectors.toList());
    }

    private List<WorkStatisticsDTO.AssigneeWorkload> buildAssigneeWorkloads(
            List<WorkTask> tasks,
            LocalDateTime now) {
        return tasks.stream()
                .filter(task -> !TaskStatus.CANCELLED.name().equals(normalizeStatus(task.getStatus())))
                .collect(Collectors.groupingBy(task -> isBlank(task.getAssigneeId())
                        ? UNASSIGNED
                        : task.getAssigneeId()))
                .entrySet().stream()
                .map(entry -> {
                    WorkStatisticsDTO.AssigneeWorkload workload = new WorkStatisticsDTO.AssigneeWorkload();
                    workload.setAssigneeId(entry.getKey());
                    workload.setTotalCount(entry.getValue().size());
                    workload.setCompletedCount((int) entry.getValue().stream()
                            .filter(this::isCompletedTask)
                            .count());
                    workload.setActiveCount((int) entry.getValue().stream()
                            .filter(task -> !CLOSED_TASK_STATUSES.contains(normalizeStatus(task.getStatus())))
                            .count());
                    workload.setOverdueCount((int) entry.getValue().stream()
                            .filter(task -> isOverdueTask(task, now))
                            .count());
                    return workload;
                })
                .sorted(Comparator
                        .comparing(WorkStatisticsDTO.AssigneeWorkload::getTotalCount)
                        .reversed()
                        .thenComparing(WorkStatisticsDTO.AssigneeWorkload::getAssigneeId))
                .limit(8)
                .collect(Collectors.toList());
    }

    private List<WorkStatisticsDTO.AttentionItem> buildAttentionItems(
            List<WorkTask> tasks,
            Map<String, Work> workById,
            LocalDateTime now) {
        return tasks.stream()
                .filter(task -> Boolean.TRUE.equals(task.getStageRiskReported()) || isOverdueTask(task, now))
                .sorted(Comparator
                        .comparing((WorkTask task) -> !Boolean.TRUE.equals(task.getStageRiskReported()))
                        .thenComparing(task -> !isOverdueTask(task, now))
                        .thenComparing(WorkTask::getDeadline, Comparator.nullsLast(Comparator.naturalOrder())))
                .limit(10)
                .map(task -> {
                    Work work = workById.get(task.getWorkId());
                    WorkStatisticsDTO.AttentionItem item = new WorkStatisticsDTO.AttentionItem();
                    item.setWorkId(task.getWorkId());
                    item.setWorkTitle(work == null ? "-" : work.getTitle());
                    item.setTaskId(task.getId());
                    item.setTaskTitle(task.getTitle());
                    item.setAssigneeId(task.getAssigneeId());
                    item.setStatus(task.getStatus());
                    item.setDeadline(task.getDeadline());
                    item.setOverdue(isOverdueTask(task, now));
                    item.setRiskReported(Boolean.TRUE.equals(task.getStageRiskReported()));
                    item.setRiskNote(latestRiskNote(task.getStageRiskNote()));
                    return item;
                })
                .collect(Collectors.toList());
    }

    private boolean isCompletedTask(WorkTask task) {
        return TaskStatus.COMPLETED.name().equals(normalizeStatus(task.getStatus()));
    }

    private boolean isOverdueTask(WorkTask task, LocalDateTime now) {
        return task.getDeadline() != null
                && task.getDeadline().isBefore(now)
                && !CLOSED_TASK_STATUSES.contains(normalizeStatus(task.getStatus()));
    }

    private String normalizeStatus(String status) {
        return status == null ? "UNKNOWN" : status.trim().toUpperCase();
    }

    private String latestRiskNote(String riskNote) {
        if (isBlank(riskNote)) {
            return null;
        }
        String[] lines = riskNote.split("\\R");
        for (int index = lines.length - 1; index >= 0; index--) {
            String line = lines[index].trim();
            if (!line.isEmpty()) {
                return line.length() > 200 ? line.substring(0, 200) + "..." : line;
            }
        }
        return null;
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
