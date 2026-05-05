package com.example.urgs_api.marketplace.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.marketplace.dto.TaskMarketDTO;
import com.example.urgs_api.marketplace.dto.TaskReviewDTO;
import com.example.urgs_api.marketplace.dto.TaskSubmissionDTO;
import com.example.urgs_api.marketplace.enums.AssignMode;
import com.example.urgs_api.marketplace.enums.ReviewDecision;
import com.example.urgs_api.marketplace.enums.TaskStatus;
import com.example.urgs_api.marketplace.enums.WorkStatus;
import com.example.urgs_api.marketplace.mapper.WorkTaskMapper;
import com.example.urgs_api.marketplace.model.TaskLog;
import com.example.urgs_api.marketplace.model.Work;
import com.example.urgs_api.marketplace.model.WorkTask;
import com.example.urgs_api.marketplace.service.TaskApplicationService;
import com.example.urgs_api.marketplace.service.WorkService;
import com.example.urgs_api.marketplace.service.WorkTaskService;
import com.example.urgs_api.marketplace.mapper.TaskLogMapper;
import com.example.urgs_api.user.mapper.UserMapper;
import com.example.urgs_api.user.model.User;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.stream.Collectors;

@Service
public class WorkTaskServiceImpl extends ServiceImpl<WorkTaskMapper, WorkTask> implements WorkTaskService {

    @Autowired
    @org.springframework.context.annotation.Lazy
    private WorkService workService;

    @Autowired
    @org.springframework.context.annotation.Lazy
    private TaskApplicationService taskApplicationService;

    @Autowired
    private TaskLogMapper taskLogMapper;

    @Autowired
    private UserMapper userMapper;

    @Override
    public Page<TaskMarketDTO> getMarketTasks(Page<WorkTask> page, String category, String keyword, String status) {
        // Query tasks that are part of PUBLISHED works
        LambdaQueryWrapper<WorkTask> queryWrapper = new LambdaQueryWrapper<>();

        if (StringUtils.hasText(status)) {
            queryWrapper.eq(WorkTask::getStatus, status);
        } else {
            // Default to only show OPEN tasks in the main hall
            queryWrapper.eq(WorkTask::getStatus, TaskStatus.OPEN.name());
        }

        if (StringUtils.hasText(keyword)) {
            queryWrapper.like(WorkTask::getTitle, keyword);
        }

        queryWrapper.orderByDesc(WorkTask::getCreateTime);
        Page<WorkTask> taskPage = this.page(page, queryWrapper);

        Page<TaskMarketDTO> dtoPage = new Page<>();
        BeanUtils.copyProperties(taskPage, dtoPage, "records");

        // Map to DTO and enrich with Work and User info
        dtoPage.setRecords(taskPage.getRecords().stream().map(task -> {
            Work work = workService.getById(task.getWorkId());
            // Show tasks from PUBLISHED or IN_PROGRESS works. Reject DRAFT/CANCELLED.
            if (work == null || WorkStatus.DRAFT.name().equals(work.getStatus())
                    || WorkStatus.CANCELLED.name().equals(work.getStatus())) {
                return null;
            }

            TaskMarketDTO dto = new TaskMarketDTO();
            BeanUtils.copyProperties(task, dto);
            dto.setWorkTitle(work.getTitle());

            if (StringUtils.hasText(category) && !category.equals(work.getCategory())) {
                return null;
            }

            User publisher = userMapper.selectById(work.getPublisherId());
            if (publisher != null) {
                dto.setPublisherName(publisher.getName());
                dto.setPublisherAvatar(publisher.getAvatarUrl());
            }

            // Get application count if COMPETE mode
            if (AssignMode.COMPETE.name().equals(task.getAssignMode())) {
                long count = taskApplicationService.lambdaQuery()
                        .eq(com.example.urgs_api.marketplace.model.TaskApplication::getTaskId, task.getId())
                        .eq(com.example.urgs_api.marketplace.model.TaskApplication::getStatus, "PENDING")
                        .count();
                dto.setApplicationCount((int) count);
            } else {
                dto.setApplicationCount(0);
            }

            return dto;
        }).filter(java.util.Objects::nonNull).collect(Collectors.toList()));

        return dtoPage;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean claimTask(String taskId, String userId) {
        WorkTask task = this.getById(taskId);
        if (task == null || !TaskStatus.OPEN.name().equals(task.getStatus())) {
            throw new IllegalStateException("任务不存在或不可领取");
        }
        if (!AssignMode.OPEN.name().equals(task.getAssignMode())) {
            throw new IllegalStateException("该任务不支持直接领取");
        }

        task.setStatus(TaskStatus.ASSIGNED.name());
        task.setAssigneeId(userId);
        task.setReworkCount(defaultInt(task.getReworkCount()));
        task.setBonusPoints(defaultInt(task.getBonusPoints()));
        task.setPenaltyPoints(defaultInt(task.getPenaltyPoints()));
        task.setFinalPoints(defaultInt(task.getFinalPoints()));
        boolean success = this.updateById(task);

        if (success) {
            logTaskAction(taskId, userId, "CLAIM", "直接领取了任务");
            updateWorkStatusIfNecessary(task.getWorkId());
        }
        return success;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean releaseTask(String taskId, String userId) {
        WorkTask task = this.getById(taskId);
        if (task == null) {
            throw new IllegalArgumentException("任务不存在");
        }
        if (!userId.equals(task.getAssigneeId())) {
            throw new IllegalStateException("只能解除自己承接的任务");
        }
        if (!TaskStatus.ASSIGNED.name().equals(task.getStatus())) {
            throw new IllegalStateException("只有已承接且未开始的任务可以解除承接");
        }

        boolean success = this.lambdaUpdate()
                .eq(WorkTask::getId, taskId)
                .set(WorkTask::getAssigneeId, null)
                .set(WorkTask::getStatus, TaskStatus.OPEN.name())
                .update();

        if (success) {
            logTaskAction(taskId, userId, "RELEASE", "解除承接，任务返回任务大厅");
        }
        return success;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean assignTask(String taskId, String assigneeId, String currentUserId) {
        WorkTask task = this.getById(taskId);
        if (task == null) {
            throw new IllegalArgumentException("任务不存在");
        }

        Work work = workService.getById(task.getWorkId());
        if (!work.getPublisherId().equals(currentUserId)) {
            throw new IllegalStateException("无权指派此任务");
        }

        task.setStatus(TaskStatus.ASSIGNED.name());
        task.setAssigneeId(assigneeId);
        task.setReworkCount(defaultInt(task.getReworkCount()));
        task.setBonusPoints(defaultInt(task.getBonusPoints()));
        task.setPenaltyPoints(defaultInt(task.getPenaltyPoints()));
        task.setFinalPoints(defaultInt(task.getFinalPoints()));
        boolean success = this.updateById(task);

        if (success) {
            User assignee = userMapper.selectById(assigneeId);
            String assigneeName = assignee != null ? assignee.getName() : assigneeId;
            logTaskAction(taskId, currentUserId, "ASSIGN", "将任务指派给: " + assigneeName);
            updateWorkStatusIfNecessary(task.getWorkId());
        }
        return success;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean submitForReview(String taskId, TaskSubmissionDTO dto, String userId) {
        WorkTask task = this.getById(taskId);
        if (task == null) {
            throw new IllegalArgumentException("任务不存在");
        }
        if (!userId.equals(task.getAssigneeId())) {
            throw new IllegalStateException("只能提交自己承接的任务");
        }
        if (!TaskStatus.IN_PROGRESS.name().equals(task.getStatus())
                && !TaskStatus.REJECTED.name().equals(task.getStatus())
                && !TaskStatus.ASSIGNED.name().equals(task.getStatus())) {
            throw new IllegalStateException("当前状态不可提交验收");
        }

        task.setCompletionDescription(dto.getCompletionDescription());
        task.setDeliverables(dto.getDeliverables());
        task.setActualHours(dto.getActualHours());
        task.setImpactScope(dto.getImpactScope());
        task.setDelayReported(Boolean.TRUE.equals(dto.getDelayReported()));
        task.setDelayReason(dto.getDelayReason());
        task.setSubmittedAt(LocalDateTime.now());
        task.setStatus(TaskStatus.REVIEW.name());
        boolean success = this.updateById(task);
        if (success) {
            logTaskAction(taskId, userId, "SUBMIT_REVIEW", "提交验收: " + nullToEmpty(dto.getCompletionDescription()));
            updateWorkStatusIfNecessary(task.getWorkId());
        }
        return success;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean reviewTask(String taskId, TaskReviewDTO dto, String reviewerId) {
        WorkTask task = this.getById(taskId);
        if (task == null) {
            throw new IllegalArgumentException("任务不存在");
        }
        Work work = workService.getById(task.getWorkId());
        if (work == null || !work.getPublisherId().equals(reviewerId)) {
            throw new IllegalStateException("只有需求发布人可以验收任务");
        }

        ReviewDecision decision = ReviewDecision.valueOf(dto.getDecision());
        if (ReviewDecision.APPROVE.equals(decision)) {
            if (dto.getQualityScore() == null || dto.getQualityScore() < 1 || dto.getQualityScore() > 5) {
                throw new IllegalArgumentException("通过验收时质量评分必须在 1-5 分之间");
            }
            task.setQualityScore(dto.getQualityScore());
            task.setReviewComment(dto.getReviewComment());
            task.setReviewerId(reviewerId);
            task.setReviewedAt(LocalDateTime.now());
            task.setBonusPoints(defaultInt(dto.getBonusPoints()));
            task.setPenaltyPoints(defaultInt(dto.getPenaltyPoints()));
            task.setFinalPoints(calculateFinalPoints(task));
            task.setKpiPeriod(YearMonth.from(task.getReviewedAt()).toString());
            task.setStatus(TaskStatus.COMPLETED.name());
            boolean success = this.updateById(task);
            if (success) {
                logTaskAction(taskId, reviewerId, "REVIEW_APPROVE",
                        "验收通过, 质量分: " + task.getQualityScore() + ", 最终积分: " + task.getFinalPoints());
                updateWorkStatusIfNecessary(task.getWorkId());
            }
            return success;
        }

        if (ReviewDecision.REJECT.equals(decision)) {
            task.setReviewComment(dto.getReviewComment());
            task.setReviewerId(reviewerId);
            task.setReviewedAt(LocalDateTime.now());
            task.setReworkCount(defaultInt(task.getReworkCount()) + 1);
            task.setStatus(TaskStatus.REJECTED.name());
            boolean success = this.updateById(task);
            if (success) {
                logTaskAction(taskId, reviewerId, "REVIEW_REJECT", "验收退回: " + nullToEmpty(dto.getReviewComment()));
            }
            return success;
        }

        if (ReviewDecision.CANCEL.equals(decision)) {
            task.setReviewComment(dto.getReviewComment());
            task.setReviewerId(reviewerId);
            task.setReviewedAt(LocalDateTime.now());
            task.setStatus(TaskStatus.CANCELLED.name());
            boolean success = this.updateById(task);
            if (success) {
                logTaskAction(taskId, reviewerId, "REVIEW_CANCEL", "验收取消: " + nullToEmpty(dto.getReviewComment()));
                updateWorkStatusIfNecessary(task.getWorkId());
            }
            return success;
        }

        if (ReviewDecision.TRANSFER.equals(decision)) {
            if (!StringUtils.hasText(dto.getTransferAssigneeId())) {
                throw new IllegalArgumentException("转派任务必须指定新的承接人");
            }
            String oldAssignee = task.getAssigneeId();
            task.setAssigneeId(dto.getTransferAssigneeId());
            task.setStatus(TaskStatus.ASSIGNED.name());
            task.setReviewComment(dto.getReviewComment());
            task.setReviewerId(reviewerId);
            task.setReviewedAt(LocalDateTime.now());
            boolean success = this.updateById(task);
            if (success) {
                logTaskAction(taskId, reviewerId, "REVIEW_TRANSFER",
                        "任务转派: " + oldAssignee + " -> " + dto.getTransferAssigneeId());
            }
            return success;
        }

        return false;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean updateTaskStatus(String taskId, String status, String userId) {
        WorkTask task = this.getById(taskId);
        if (task == null) {
            throw new IllegalArgumentException("任务不存在");
        }
        // Simplified authorization check
        String oldStatus = task.getStatus();
        task.setStatus(status);
        boolean success = this.updateById(task);

        if (success) {
            logTaskAction(taskId, userId, "STATUS_UPDATE", "更新状态: " + oldStatus + " -> " + status);
            updateWorkStatusIfNecessary(task.getWorkId());
        }
        return success;
    }

    @Override
    public void logTaskAction(String taskId, String operatorId, String action, String detail) {
        TaskLog log = new TaskLog();
        log.setTaskId(taskId);
        log.setOperatorId(operatorId);
        log.setAction(action);
        log.setDetail(detail);
        log.setCreateTime(LocalDateTime.now());
        taskLogMapper.insert(log);
    }

    private void updateWorkStatusIfNecessary(String workId) {
        Work work = workService.getById(workId);
        if (work == null)
            return;

        if (WorkStatus.PUBLISHED.name().equals(work.getStatus())) {
            // Once a task goes beyond OPEN, consider work IN_PROGRESS
            work.setStatus(WorkStatus.IN_PROGRESS.name());
            workService.updateById(work);
        } else if (WorkStatus.IN_PROGRESS.name().equals(work.getStatus())) {
            // Check if all tasks are completed
            long totalCount = this.lambdaQuery().eq(WorkTask::getWorkId, workId).count();
            long compCount = this.lambdaQuery().eq(WorkTask::getWorkId, workId)
                    .in(WorkTask::getStatus, TaskStatus.COMPLETED.name(), TaskStatus.CANCELLED.name())
                    .count();
            if (totalCount > 0 && totalCount == compCount) {
                work.setStatus(WorkStatus.COMPLETED.name());
                workService.updateById(work);
            }
        }
    }

    @Override
    public TaskMarketDTO getTaskDetail(String taskId) {
        WorkTask task = this.getById(taskId);
        if (task == null) {
            throw new IllegalArgumentException("任务不存在");
        }

        TaskMarketDTO dto = new TaskMarketDTO();
        BeanUtils.copyProperties(task, dto);

        Work work = workService.getById(task.getWorkId());
        if (work != null) {
            dto.setWorkTitle(work.getTitle());
            User publisher = userMapper.selectById(work.getPublisherId());
            if (publisher != null) {
                dto.setPublisherName(publisher.getName());
                dto.setPublisherAvatar(publisher.getAvatarUrl());
            }
        }

        // Get application count if COMPETE mode
        if (AssignMode.COMPETE.name().equals(task.getAssignMode())) {
            long count = taskApplicationService.lambdaQuery()
                    .eq(com.example.urgs_api.marketplace.model.TaskApplication::getTaskId, task.getId())
                    .eq(com.example.urgs_api.marketplace.model.TaskApplication::getStatus, "PENDING")
                    .count();
            dto.setApplicationCount((int) count);
        } else {
            dto.setApplicationCount(0);
        }

        return dto;
    }

    private int calculateFinalPoints(WorkTask task) {
        int basePoints = defaultInt(task.getPoints());
        double timelyFactor = calculateTimelyFactor(task);
        double qualityFactor = switch (defaultInt(task.getQualityScore())) {
            case 5 -> 1.2;
            case 4 -> 1.0;
            case 3 -> 0.85;
            case 2 -> 0.6;
            default -> 0.0;
        };
        int reworkDeduction = Math.min((int) Math.round(basePoints * defaultInt(task.getReworkCount()) * 0.1),
                (int) Math.round(basePoints * 0.5));
        int calculated = (int) Math.round(basePoints * timelyFactor * qualityFactor)
                - reworkDeduction
                + defaultInt(task.getBonusPoints())
                - defaultInt(task.getPenaltyPoints());
        return Math.max(calculated, 0);
    }

    private double calculateTimelyFactor(WorkTask task) {
        if (task.getDeadline() == null || task.getSubmittedAt() == null || !task.getSubmittedAt().isAfter(task.getDeadline())) {
            return 1.0;
        }
        long delayHours = java.time.Duration.between(task.getDeadline(), task.getSubmittedAt()).toHours();
        if (Boolean.TRUE.equals(task.getDelayReported())) {
            return 0.9;
        }
        if (delayHours <= 72) {
            return 0.7;
        }
        return 0.5;
    }

    private int defaultInt(Integer value) {
        return value == null ? 0 : value;
    }

    private String nullToEmpty(String value) {
        return value == null ? "" : value;
    }
}
