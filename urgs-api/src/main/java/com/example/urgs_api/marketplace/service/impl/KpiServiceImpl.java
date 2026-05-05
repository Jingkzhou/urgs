package com.example.urgs_api.marketplace.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.marketplace.dto.KpiDetailDTO;
import com.example.urgs_api.marketplace.dto.KpiSummaryDTO;
import com.example.urgs_api.marketplace.dto.TeamKpiDTO;
import com.example.urgs_api.marketplace.enums.TaskStatus;
import com.example.urgs_api.marketplace.enums.WorkStatus;
import com.example.urgs_api.marketplace.model.Work;
import com.example.urgs_api.marketplace.model.WorkTask;
import com.example.urgs_api.marketplace.service.KpiService;
import com.example.urgs_api.marketplace.service.WorkService;
import com.example.urgs_api.marketplace.service.WorkTaskService;
import com.example.urgs_api.user.mapper.UserMapper;
import com.example.urgs_api.user.model.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
public class KpiServiceImpl implements KpiService {

    @Autowired
    private WorkTaskService workTaskService;

    @Autowired
    private WorkService workService;

    @Autowired
    private UserMapper userMapper;

    @Override
    public KpiSummaryDTO getUserSummary(String userId, LocalDate startDate, LocalDate endDate) {
        List<WorkTask> completedTasks = completedTasks(startDate, endDate).stream()
                .filter(task -> userId.equals(task.getAssigneeId()))
                .toList();
        return buildSummary(userId, completedTasks);
    }

    @Override
    public List<KpiDetailDTO> getUserDetails(String userId, LocalDate startDate, LocalDate endDate) {
        return completedTasks(startDate, endDate).stream()
                .filter(task -> !StringUtils.hasText(userId) || userId.equals(task.getAssigneeId()))
                .map(this::buildDetail)
                .collect(Collectors.toList());
    }

    @Override
    public TeamKpiDTO getTeamKpi(LocalDate startDate, LocalDate endDate) {
        List<WorkTask> completedTasks = completedTasks(startDate, endDate);
        TeamKpiDTO dto = new TeamKpiDTO();
        dto.setTotalWorks(Math.toIntExact(workService.count()));
        dto.setCompletedWorks(Math.toIntExact(workService.lambdaQuery().eq(Work::getStatus, WorkStatus.COMPLETED.name()).count()));
        dto.setInProgressTasks(Math.toIntExact(workTaskService.lambdaQuery()
                .in(WorkTask::getStatus, TaskStatus.ASSIGNED.name(), TaskStatus.IN_PROGRESS.name(), TaskStatus.REVIEW.name())
                .count()));
        dto.setOverdueTasks(Math.toIntExact(workTaskService.lambdaQuery()
                .ne(WorkTask::getStatus, TaskStatus.COMPLETED.name())
                .lt(WorkTask::getDeadline, LocalDateTime.now())
                .count()));
        dto.setTotalPointPool(workService.list().stream().mapToInt(work -> defaultInt(work.getTotalPoints())).sum());
        dto.setSettledPoints(completedTasks.stream().mapToInt(task -> defaultInt(task.getFinalPoints())).sum());
        dto.setRankings(getLeaderboard("overall", startDate, endDate));
        return dto;
    }

    @Override
    public List<KpiSummaryDTO> getLeaderboard(String dimension, LocalDate startDate, LocalDate endDate) {
        Map<String, List<WorkTask>> byUser = completedTasks(startDate, endDate).stream()
                .filter(task -> StringUtils.hasText(task.getAssigneeId()))
                .collect(Collectors.groupingBy(WorkTask::getAssigneeId));

        Comparator<KpiSummaryDTO> comparator = switch (dimension == null ? "overall" : dimension) {
            case "quality" -> Comparator.comparing(KpiSummaryDTO::getAverageQualityScore, Comparator.nullsLast(Double::compareTo));
            case "ontime" -> Comparator.comparing(KpiSummaryDTO::getOnTimeRate, Comparator.nullsLast(Double::compareTo));
            case "rework" -> Comparator.comparing(KpiSummaryDTO::getReworkCount);
            default -> Comparator.comparing(KpiSummaryDTO::getFinalPoints, Comparator.nullsLast(Integer::compareTo));
        };

        return byUser.entrySet().stream()
                .map(entry -> buildSummary(entry.getKey(), entry.getValue()))
                .sorted(comparator.reversed())
                .collect(Collectors.toList());
    }

    private List<WorkTask> completedTasks(LocalDate startDate, LocalDate endDate) {
        LambdaQueryWrapper<WorkTask> wrapper = new LambdaQueryWrapper<WorkTask>()
                .eq(WorkTask::getStatus, TaskStatus.COMPLETED.name())
                .isNotNull(WorkTask::getReviewedAt)
                .orderByDesc(WorkTask::getReviewedAt);
        if (startDate != null) {
            wrapper.ge(WorkTask::getReviewedAt, startDate.atStartOfDay());
        }
        if (endDate != null) {
            wrapper.le(WorkTask::getReviewedAt, endDate.atTime(LocalTime.MAX));
        }
        return workTaskService.list(wrapper);
    }

    private KpiSummaryDTO buildSummary(String userId, List<WorkTask> tasks) {
        KpiSummaryDTO dto = new KpiSummaryDTO();
        dto.setUserId(userId);
        User user = userMapper.selectById(userId);
        dto.setUserName(user != null ? user.getName() : userId);
        dto.setCompletedTaskCount(tasks.size());
        dto.setBasePoints(tasks.stream().mapToInt(task -> defaultInt(task.getPoints())).sum());
        dto.setFinalPoints(tasks.stream().mapToInt(task -> defaultInt(task.getFinalPoints())).sum());
        dto.setReworkCount(tasks.stream().mapToInt(task -> defaultInt(task.getReworkCount())).sum());
        dto.setOverdueCount((int) tasks.stream().filter(task -> !isOnTime(task)).count());
        dto.setOnTimeRate(tasks.isEmpty() ? 0D : roundRate(tasks.stream().filter(this::isOnTime).count(), tasks.size()));
        dto.setAverageQualityScore(tasks.isEmpty() ? 0D : round(tasks.stream()
                .map(WorkTask::getQualityScore)
                .filter(Objects::nonNull)
                .mapToInt(Integer::intValue)
                .average()
                .orElse(0D)));
        dto.setHighPriorityTaskCount((int) tasks.stream().filter(this::isHighPriority).count());
        dto.setActiveTaskCount(Math.toIntExact(workTaskService.lambdaQuery()
                .eq(WorkTask::getAssigneeId, userId)
                .in(WorkTask::getStatus, TaskStatus.ASSIGNED.name(), TaskStatus.IN_PROGRESS.name(), TaskStatus.REVIEW.name())
                .count()));
        return dto;
    }

    private KpiDetailDTO buildDetail(WorkTask task) {
        Work work = workService.getById(task.getWorkId());
        KpiDetailDTO dto = new KpiDetailDTO();
        dto.setTaskId(task.getId());
        dto.setTaskTitle(task.getTitle());
        dto.setWorkId(task.getWorkId());
        dto.setWorkTitle(work != null ? work.getTitle() : null);
        dto.setRequirementNumber(work != null ? work.getRequirementNumber() : null);
        dto.setAssigneeId(task.getAssigneeId());
        User assignee = StringUtils.hasText(task.getAssigneeId()) ? userMapper.selectById(task.getAssigneeId()) : null;
        dto.setAssigneeName(assignee != null ? assignee.getName() : task.getAssigneeId());
        dto.setBasePoints(defaultInt(task.getPoints()));
        dto.setFinalPoints(defaultInt(task.getFinalPoints()));
        dto.setQualityScore(task.getQualityScore());
        dto.setReworkCount(defaultInt(task.getReworkCount()));
        dto.setOnTime(isOnTime(task));
        dto.setActualHours(task.getActualHours());
        dto.setReviewerId(task.getReviewerId());
        dto.setReviewComment(task.getReviewComment());
        dto.setReviewedAt(task.getReviewedAt());
        return dto;
    }

    private boolean isHighPriority(WorkTask task) {
        Work work = workService.getById(task.getWorkId());
        return work != null && ("P0".equals(work.getPriority()) || "P1".equals(work.getPriority()));
    }

    private boolean isOnTime(WorkTask task) {
        return task.getDeadline() == null || task.getSubmittedAt() == null || !task.getSubmittedAt().isAfter(task.getDeadline());
    }

    private Double roundRate(long numerator, long denominator) {
        return round(denominator == 0 ? 0D : numerator * 100D / denominator);
    }

    private Double round(double value) {
        return Math.round(value * 100D) / 100D;
    }

    private int defaultInt(Integer value) {
        return value == null ? 0 : value;
    }
}
