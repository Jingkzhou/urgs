package com.example.urgs_api.marketplace.service.impl;

import com.example.urgs_api.marketplace.dto.WorkStatisticsDTO;
import com.example.urgs_api.marketplace.enums.TaskStatus;
import com.example.urgs_api.marketplace.enums.WorkStatus;
import com.example.urgs_api.marketplace.model.Work;
import com.example.urgs_api.marketplace.model.WorkTask;
import com.example.urgs_api.marketplace.service.WorkService;
import com.example.urgs_api.marketplace.service.WorkStatisticsService;
import com.example.urgs_api.marketplace.service.WorkTaskService;
import com.example.urgs_api.system.model.SysSystem;
import com.example.urgs_api.system.service.SysSystemService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
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

    @Autowired
    private SysSystemService sysSystemService;

    @Override
    public WorkStatisticsDTO getStatistics(String publisherId, LocalDate startDate, LocalDate endDate) {
        LocalDateTime startAt = startDate.atStartOfDay();
        LocalDateTime endExclusive = endDate.plusDays(1).atStartOfDay();
        LocalDateTime now = LocalDateTime.now();

        var workQuery = workService.lambdaQuery();
        if (publisherId != null) {
            workQuery.eq(Work::getPublisherId, publisherId);
        }
        List<Work> works = workQuery
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
        statistics.setSystemTaskStats(buildSystemTaskStats(works, tasksByWorkId, now));
        statistics.setWorkTrend(buildWorkTrend(works, startDate, endDate));
        statistics.setAssigneeWorkloads(buildAssigneeWorkloads(tasks, now));
        statistics.setAttentionItems(buildAttentionItems(tasks, workById, now));
        return statistics;
    }

    @Override
    public List<WorkStatisticsDTO.CalendarTaskItem> getIncompleteCalendarTasks(
            String publisherId,
            LocalDate startDate,
            LocalDate endDate) {
        LocalDateTime startAt = startDate.atStartOfDay();
        LocalDateTime endExclusive = endDate.plusDays(1).atStartOfDay();
        List<WorkTask> tasks = workTaskService.lambdaQuery()
                .isNotNull(WorkTask::getDeadline)
                .ge(WorkTask::getDeadline, startAt)
                .lt(WorkTask::getDeadline, endExclusive)
                .list();
        if (tasks.isEmpty()) {
            return List.of();
        }

        Set<String> workIds = tasks.stream()
                .map(WorkTask::getWorkId)
                .filter(workId -> !isBlank(workId))
                .collect(Collectors.toSet());
        if (workIds.isEmpty()) {
            return List.of();
        }
        var workQuery = workService.lambdaQuery().in(Work::getId, workIds);
        if (publisherId != null) {
            workQuery.eq(Work::getPublisherId, publisherId);
        }
        Map<String, Work> workById = workQuery.list().stream()
                .collect(Collectors.toMap(Work::getId, work -> work));

        return tasks.stream()
                .filter(task -> !CLOSED_TASK_STATUSES.contains(normalizeStatus(task.getStatus())))
                .filter(task -> workById.containsKey(task.getWorkId()))
                .sorted(Comparator
                        .comparing(WorkTask::getDeadline)
                        .thenComparing(WorkTask::getTitle, Comparator.nullsLast(Comparator.naturalOrder())))
                .map(task -> {
                    Work work = workById.get(task.getWorkId());
                    WorkStatisticsDTO.CalendarTaskItem item = new WorkStatisticsDTO.CalendarTaskItem();
                    item.setWorkId(task.getWorkId());
                    item.setWorkTitle(work.getTitle());
                    item.setTaskId(task.getId());
                    item.setTaskTitle(task.getTitle());
                    item.setAssigneeId(task.getAssigneeId());
                    item.setStatus(task.getStatus());
                    item.setDeadline(task.getDeadline());
                    return item;
                })
                .collect(Collectors.toList());
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

    private List<WorkStatisticsDTO.SystemTaskStats> buildSystemTaskStats(
            List<Work> works,
            Map<String, List<WorkTask>> tasksByWorkId,
            LocalDateTime now) {
        Set<Long> systemIds = tasksByWorkId.values().stream()
                .flatMap(List::stream)
                .filter(task -> task.getInvolvedSystemIds() != null)
                .flatMap(task -> task.getInvolvedSystemIds().stream())
                .filter(id -> id != null)
                .collect(Collectors.toSet());
        Map<Long, String> systemNames = systemIds.isEmpty()
                ? Map.of()
                : sysSystemService.listByIds(systemIds).stream()
                        .collect(Collectors.toMap(
                                SysSystem::getId,
                                system -> isBlank(system.getName()) ? "系统 #" + system.getId() : system.getName(),
                                (left, right) -> left));
        Map<String, SystemTaskAccumulator> statsBySystem = new LinkedHashMap<>();
        works.forEach(work -> {
            List<WorkTask> workTasks = tasksByWorkId.getOrDefault(work.getId(), List.of());
            Set<String> involvedSystems = workTasks.stream()
                    .flatMap(task -> resolveTaskSystems(task, work, systemNames).stream())
                    .collect(Collectors.toCollection(LinkedHashSet::new));
            if (involvedSystems.isEmpty()) {
                involvedSystems.add(resolveOwningSystem(work));
            }

            String requirementKey = isBlank(work.getRequirementNumber())
                    ? "WORK:" + work.getId()
                    : "REQ:" + work.getRequirementNumber().trim();
            involvedSystems.forEach(systemName -> statsBySystem
                    .computeIfAbsent(systemName, key -> new SystemTaskAccumulator())
                    .requirementKeys.add(requirementKey));

            workTasks.stream()
                    .filter(task -> !TaskStatus.CANCELLED.name().equals(normalizeStatus(task.getStatus())))
                    .forEach(task -> resolveTaskSystems(task, work, systemNames).forEach(systemName -> {
                        SystemTaskAccumulator accumulator = statsBySystem
                                .computeIfAbsent(systemName, key -> new SystemTaskAccumulator());
                        accumulator.totalTaskCount++;
                        if (isCompletedTask(task)) {
                            accumulator.completedTaskCount++;
                        }
                        if (isOverdueTask(task, now)) {
                            accumulator.overdueTaskCount++;
                        }
                    }));
        });

        return statsBySystem.entrySet().stream()
                .map(entry -> {
                    SystemTaskAccumulator accumulator = entry.getValue();
                    WorkStatisticsDTO.SystemTaskStats item = new WorkStatisticsDTO.SystemTaskStats();
                    item.setSystemName(entry.getKey());
                    item.setRequirementCount(accumulator.requirementKeys.size());
                    item.setTotalTaskCount(accumulator.totalTaskCount);
                    item.setCompletedTaskCount(accumulator.completedTaskCount);
                    item.setOverdueTaskCount(accumulator.overdueTaskCount);
                    item.setCompletionRate(accumulator.totalTaskCount == 0
                            ? 0
                            : (int) Math.round(accumulator.completedTaskCount * 100.0 / accumulator.totalTaskCount));
                    return item;
                })
                .sorted(Comparator
                        .comparing(WorkStatisticsDTO.SystemTaskStats::getTotalTaskCount)
                        .reversed()
                        .thenComparing(WorkStatisticsDTO.SystemTaskStats::getSystemName))
                .collect(Collectors.toList());
    }

    private Set<String> resolveTaskSystems(
            WorkTask task,
            Work work,
            Map<Long, String> systemNames) {
        if (task.getInvolvedSystemIds() == null || task.getInvolvedSystemIds().isEmpty()) {
            return Set.of(resolveOwningSystem(work));
        }
        Set<String> resolvedSystems = task.getInvolvedSystemIds().stream()
                .filter(id -> id != null)
                .map(id -> systemNames.getOrDefault(id, "系统 #" + id))
                .collect(Collectors.toCollection(LinkedHashSet::new));
        return resolvedSystems.isEmpty() ? Set.of(resolveOwningSystem(work)) : resolvedSystems;
    }

    private String resolveOwningSystem(Work work) {
        return isBlank(work.getOwningSystem()) ? "未指定系统" : work.getOwningSystem().trim();
    }

    private List<WorkStatisticsDTO.TrendItem> buildWorkTrend(
            List<Work> works,
            LocalDate startDate,
            LocalDate endDate) {
        Map<LocalDate, Integer> completedCounts = new LinkedHashMap<>();
        Map<LocalDate, Integer> createdCounts = new LinkedHashMap<>();
        for (LocalDate date = startDate; !date.isAfter(endDate); date = date.plusDays(1)) {
            completedCounts.put(date, 0);
            createdCounts.put(date, 0);
        }
        works.stream()
                .filter(work -> WorkStatus.COMPLETED.name().equals(normalizeStatus(work.getStatus())))
                .map(Work::getDeadline)
                .filter(deadline -> deadline != null
                        && !deadline.toLocalDate().isBefore(startDate)
                        && !deadline.toLocalDate().isAfter(endDate))
                .forEach(deadline -> completedCounts.computeIfPresent(
                        deadline.toLocalDate(),
                        (date, count) -> count + 1));
        works.stream()
                .map(Work::getCreateTime)
                .filter(createdAt -> createdAt != null
                        && !createdAt.toLocalDate().isBefore(startDate)
                        && !createdAt.toLocalDate().isAfter(endDate))
                .forEach(createdAt -> createdCounts.computeIfPresent(
                        createdAt.toLocalDate(),
                        (date, count) -> count + 1));

        return completedCounts.entrySet().stream()
                .map(entry -> {
                    WorkStatisticsDTO.TrendItem item = new WorkStatisticsDTO.TrendItem();
                    item.setDate(entry.getKey());
                    item.setCreatedWorkCount(createdCounts.getOrDefault(entry.getKey(), 0));
                    item.setCompletedWorkCount(entry.getValue());
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
                    workload.setPausedCount((int) entry.getValue().stream()
                            .filter(task -> TaskStatus.PAUSED.name().equals(normalizeStatus(task.getStatus())))
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

    private static class SystemTaskAccumulator {
        private final Set<String> requirementKeys = new LinkedHashSet<>();
        private int totalTaskCount;
        private int completedTaskCount;
        private int overdueTaskCount;
    }
}
