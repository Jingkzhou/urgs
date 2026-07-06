package com.example.urgs_api.marketplace.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.marketplace.dto.TaskAuditLogDTO;
import com.example.urgs_api.marketplace.dto.TaskMarketDTO;
import com.example.urgs_api.marketplace.dto.TaskReviewDTO;
import com.example.urgs_api.marketplace.dto.TaskReviewHistoryDTO;
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
import com.example.urgs_api.metadata.model.MaintenanceRecord;
import com.example.urgs_api.metadata.service.MaintenanceRecordService;
import com.example.urgs_api.user.mapper.UserMapper;
import com.example.urgs_api.user.model.User;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class WorkTaskServiceImpl extends ServiceImpl<WorkTaskMapper, WorkTask> implements WorkTaskService {
    private static final String TASK_ROLE_MAIN = "MAIN";
    private static final String TASK_ROLE_SUB = "SUB";
    private static final String STAGE_REQUIREMENT = "REQUIREMENT";
    private static final String STAGE_DEVELOPMENT = "DEVELOPMENT";
    private static final String STAGE_TESTING = "TESTING";
    private static final String STAGE_ASSET_REVIEW = "ASSET_REVIEW";
    private static final String STAGE_LAUNCH = "LAUNCH";
    private static final int TASK_LOG_DETAIL_MAX_LENGTH = 500;
    private static final List<String> REVIEW_ACTIONS = List.of(
            "ASSET_REVIEW_APPROVE",
            "ASSET_REVIEW_REJECT",
            "ASSET_REVIEW_CANCEL",
            "REVIEW_APPROVE",
            "REVIEW_REJECT",
            "REVIEW_CANCEL",
            "REVIEW_TRANSFER");
    private static final DateTimeFormatter RISK_NOTE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

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

    @Autowired
    private MaintenanceRecordService maintenanceRecordService;

    @Autowired
    private ObjectMapper objectMapper;

    @Override
    public Page<TaskMarketDTO> getMarketTasks(Page<WorkTask> page, String keyword, String status) {
        // Query tasks that are part of PUBLISHED works
        LambdaQueryWrapper<WorkTask> queryWrapper = new LambdaQueryWrapper<>();

        if ("OPEN".equals(status) || "AVAILABLE".equals(status)) {
            queryWrapper.eq(WorkTask::getStatus, TaskStatus.OPEN.name());
        } else if (StringUtils.hasText(status)) {
            queryWrapper.eq(WorkTask::getStatus, status);
        } else {
            queryWrapper.eq(WorkTask::getStatus, TaskStatus.OPEN.name());
        }
        queryWrapper.eq(WorkTask::getTaskRole, TASK_ROLE_SUB);

        if (StringUtils.hasText(keyword)) {
            queryWrapper.like(WorkTask::getTitle, keyword);
        }

        queryWrapper.orderByDesc(WorkTask::getCreateTime);
        Page<WorkTask> taskPage = this.page(page, queryWrapper);

        Page<TaskMarketDTO> dtoPage = new Page<>();
        BeanUtils.copyProperties(taskPage, dtoPage, "records");

        dtoPage.setRecords(taskPage.getRecords().stream().map(task -> {
            Work work = workService.getById(task.getWorkId());
            // 已发布或进行中的工作可以进入任务市场；草稿和已取消工作不可见。
            if (work == null || WorkStatus.DRAFT.name().equals(work.getStatus())
                    || WorkStatus.CANCELLED.name().equals(work.getStatus())) {
                return null;
            }

            return buildTaskMarketDTO(task, work);
        }).filter(java.util.Objects::nonNull).collect(Collectors.toList()));

        return dtoPage;
    }

    @Override
    public Page<TaskMarketDTO> getMyTasks(
            Page<WorkTask> page,
            String userId,
            boolean archived,
            String status,
            boolean overdue,
            LocalDateTime deadlineStart,
            LocalDateTime deadlineEnd) {
        LambdaQueryWrapper<WorkTask> query = new LambdaQueryWrapper<WorkTask>()
                .eq(WorkTask::getAssigneeId, userId);
        if (archived) {
            query.eq(WorkTask::getStatus, TaskStatus.COMPLETED.name());
        } else {
            query.ne(WorkTask::getStatus, TaskStatus.COMPLETED.name());
        }
        if (StringUtils.hasText(status)) {
            query.eq(WorkTask::getStatus, status.trim().toUpperCase());
        }
        if (overdue) {
            query.in(WorkTask::getStatus,
                    TaskStatus.READY.name(),
                    TaskStatus.IN_PROGRESS.name(),
                    TaskStatus.WAITING_REVIEW.name(),
                    TaskStatus.REWORK.name(),
                    TaskStatus.PAUSED.name())
                    .lt(WorkTask::getDeadline, LocalDateTime.now());
        }
        if (deadlineStart != null) {
            query.ge(WorkTask::getDeadline, deadlineStart);
        }
        if (deadlineEnd != null) {
            query.le(WorkTask::getDeadline, deadlineEnd);
        }
        if (archived) {
            query.orderByDesc(WorkTask::getStageUpdatedAt)
                    .orderByDesc(WorkTask::getReviewedAt);
        } else {
            query.orderByDesc(WorkTask::getStageUpdatedAt)
                    .orderByDesc(WorkTask::getCreateTime);
        }
        Page<WorkTask> taskPage = this.page(page, query);

        Page<TaskMarketDTO> dtoPage = new Page<>();
        BeanUtils.copyProperties(taskPage, dtoPage, "records");
        dtoPage.setRecords(taskPage.getRecords().stream()
                .map(task -> buildTaskMarketDTO(task, workService.getById(task.getWorkId())))
                .collect(Collectors.toList()));
        return dtoPage;
    }

    @Override
    public Page<TaskMarketDTO> getAssigneeTasks(
            Page<WorkTask> page,
            String userId,
            String status,
            LocalDateTime deadlineStart,
            LocalDateTime deadlineEnd) {
        LambdaQueryWrapper<WorkTask> query = new LambdaQueryWrapper<WorkTask>()
                .eq(WorkTask::getAssigneeId, userId);
        if (StringUtils.hasText(status)) {
            query.eq(WorkTask::getStatus, status.trim().toUpperCase());
        }
        if (deadlineStart != null) {
            query.ge(WorkTask::getDeadline, deadlineStart);
        }
        if (deadlineEnd != null) {
            query.le(WorkTask::getDeadline, deadlineEnd);
        }
        query.last("ORDER BY "
                + "CASE WHEN status IN ('COMPLETED', 'CANCELLED') THEN 1 ELSE 0 END ASC, "
                + "CASE WHEN status NOT IN ('COMPLETED', 'CANCELLED') AND deadline < NOW() THEN 0 ELSE 1 END ASC, "
                + "CASE WHEN status NOT IN ('COMPLETED', 'CANCELLED') AND deadline IS NULL THEN 1 ELSE 0 END ASC, "
                + "CASE WHEN status NOT IN ('COMPLETED', 'CANCELLED') THEN deadline END ASC, "
                + "update_time DESC, create_time DESC");

        Page<WorkTask> taskPage = this.page(page, query);
        Page<TaskMarketDTO> dtoPage = new Page<>();
        BeanUtils.copyProperties(taskPage, dtoPage, "records");
        dtoPage.setRecords(taskPage.getRecords().stream()
                .map(task -> buildTaskMarketDTO(task, workService.getById(task.getWorkId())))
                .collect(Collectors.toList()));
        return dtoPage;
    }

    @Override
    public Page<TaskMarketDTO> getReviewTasks(Page<WorkTask> page, String publisherId, boolean history) {
        List<String> workIds = workService.lambdaQuery()
                .eq(Work::getPublisherId, publisherId)
                .list()
                .stream()
                .map(Work::getId)
                .toList();

        Page<TaskMarketDTO> dtoPage = new Page<>(page.getCurrent(), page.getSize());
        if (workIds.isEmpty()) {
            return dtoPage;
        }

        LambdaQueryWrapper<WorkTask> query = new LambdaQueryWrapper<WorkTask>()
                .in(WorkTask::getWorkId, workIds);
        if (history) {
            query.isNotNull(WorkTask::getReviewedAt)
                    .orderByDesc(WorkTask::getReviewedAt);
        } else {
            query.eq(WorkTask::getStatus, TaskStatus.WAITING_REVIEW.name())
                    .orderByDesc(WorkTask::getSubmittedAt);
        }

        Page<WorkTask> taskPage = this.page(page, query);
        BeanUtils.copyProperties(taskPage, dtoPage, "records");
        dtoPage.setRecords(taskPage.getRecords().stream()
                .map(task -> buildTaskMarketDTO(task, workService.getById(task.getWorkId())))
                .collect(Collectors.toList()));
        return dtoPage;
    }

    @Override
    public Page<TaskReviewHistoryDTO> getReviewHistory(Page<TaskReviewHistoryDTO> page, String publisherId) {
        List<Work> works = workService.lambdaQuery()
                .eq(Work::getPublisherId, publisherId)
                .list();
        Page<TaskReviewHistoryDTO> resultPage = new Page<>(page.getCurrent(), page.getSize());
        if (works.isEmpty()) {
            return resultPage;
        }

        Map<String, Work> workMap = works.stream()
                .collect(Collectors.toMap(Work::getId, Function.identity()));
        List<WorkTask> tasks = this.lambdaQuery()
                .in(WorkTask::getWorkId, workMap.keySet())
                .list();
        if (tasks.isEmpty()) {
            return resultPage;
        }

        Map<String, WorkTask> taskMap = tasks.stream()
                .collect(Collectors.toMap(WorkTask::getId, Function.identity()));
        Page<TaskLog> logPage = new Page<>(page.getCurrent(), page.getSize());
        Page<TaskLog> reviewLogPage = taskLogMapper.selectPage(logPage, new LambdaQueryWrapper<TaskLog>()
                .in(TaskLog::getTaskId, taskMap.keySet())
                .in(TaskLog::getAction, REVIEW_ACTIONS)
                .orderByDesc(TaskLog::getCreateTime));

        List<String> reviewerIds = reviewLogPage.getRecords().stream()
                .map(TaskLog::getOperatorId)
                .filter(StringUtils::hasText)
                .distinct()
                .toList();
        Map<String, User> reviewerMap = reviewerIds.isEmpty()
                ? Collections.emptyMap()
                : userMapper.selectBatchIds(reviewerIds).stream()
                        .collect(Collectors.toMap(user -> user.getId().toString(), Function.identity()));

        BeanUtils.copyProperties(reviewLogPage, resultPage, "records");
        resultPage.setRecords(reviewLogPage.getRecords().stream()
                .map(log -> buildReviewHistoryDTO(log, taskMap, workMap, reviewerMap))
                .collect(Collectors.toList()));
        return resultPage;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean claimTask(String taskId, String userId) {
        WorkTask task = this.getById(taskId);
        if (task == null || !TaskStatus.OPEN.name().equals(task.getStatus())) {
            throw new IllegalStateException("任务不存在或不可领取");
        }
        ensureWorkOperable(task);
        if (!AssignMode.OPEN.name().equals(task.getAssignMode())) {
            throw new IllegalStateException("该任务不支持直接领取");
        }
        if (TASK_ROLE_MAIN.equals(task.getTaskRole())) {
            throw new IllegalStateException("主任务不支持直接领取");
        }

        task.setStatus(TaskStatus.READY.name());
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
        ensureWorkOperable(task);
        if (!userId.equals(task.getAssigneeId())) {
            throw new IllegalStateException("只能解除自己承接的任务");
        }
        if (!TaskStatus.READY.name().equals(task.getStatus())) {
            throw new IllegalStateException("只有已承接且未开始的任务可以解除承接");
        }
        if (TASK_ROLE_MAIN.equals(task.getTaskRole())) {
            throw new IllegalStateException("主任务不支持解除承接");
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
        ensureWorkOperable(task);

        Work work = workService.getById(task.getWorkId());
        if (!work.getPublisherId().equals(currentUserId)) {
            throw new IllegalStateException("无权指派此任务");
        }

        task.setStatus(TaskStatus.READY.name());
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
        ensureWorkOperable(task);
        if (!userId.equals(task.getAssigneeId())) {
            throw new IllegalStateException("只能提交自己承接的任务");
        }
        if (!TaskStatus.IN_PROGRESS.name().equals(task.getStatus())
                && !TaskStatus.REWORK.name().equals(task.getStatus())
                && !TaskStatus.READY.name().equals(task.getStatus())) {
            throw new IllegalStateException("当前状态不可提交验收");
        }
        if (!STAGE_LAUNCH.equals(resolveStage(task))) {
            throw new IllegalStateException("请先完成需求、开发、测试、资产同步审核并进入上线阶段后再提交验收");
        }
        if (TASK_ROLE_MAIN.equals(task.getTaskRole()) && !areAllSubTasksClosed(task.getWorkId())) {
            throw new IllegalStateException("请先完成所有子任务后再提交主任务验收");
        }

        task.setCompletionDescription(dto.getCompletionDescription());
        task.setDeliverables(dto.getDeliverables());
        task.setActualHours(dto.getActualHours());
        task.setImpactScope(dto.getImpactScope());
        task.setDelayReported(Boolean.TRUE.equals(dto.getDelayReported()));
        task.setDelayReason(dto.getDelayReason());
        task.setSubmittedAt(LocalDateTime.now());
        task.setStatus(TaskStatus.WAITING_REVIEW.name());
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
        ensureWorkOperable(task);
        Work work = workService.getById(task.getWorkId());
        if (work == null || !work.getPublisherId().equals(reviewerId)) {
            throw new IllegalStateException("只有需求发布人可以验收任务");
        }

        ReviewDecision decision = ReviewDecision.valueOf(dto.getDecision());
        if (ReviewDecision.APPROVE.equals(decision)) {
            if (isAssetReview(task)) {
                List<MaintenanceRecord> maintenanceRecords = getAssetMaintenanceRecords(work, task, true);
                LocalDateTime now = LocalDateTime.now();
                task.setCurrentStage(STAGE_LAUNCH);
                task.setStageUpdatedAt(now);
                task.setStatus(TaskStatus.IN_PROGRESS.name());
                task.setReviewComment(buildAssetReviewComment(task.getReviewComment(), dto.getReviewComment()));
                task.setAssetMaintenanceSnapshot(serializeAssetMaintenanceRecords(maintenanceRecords));
                task.setReviewerId(reviewerId);
                task.setReviewedAt(now);
                boolean success = this.updateById(task);
                if (success) {
                    logTaskAction(taskId, reviewerId, "ASSET_REVIEW_APPROVE",
                            buildReviewLogDetail(
                                    "资产同步审核通过，进入上线阶段，共固化 " + maintenanceRecords.size() + " 条资产变更",
                                    dto.getReviewComment()));
                    updateWorkStatusIfNecessary(task.getWorkId());
                }
                return success;
            }
            if (TASK_ROLE_MAIN.equals(task.getTaskRole()) && !areAllSubTasksClosed(task.getWorkId())) {
                throw new IllegalStateException("请先完成所有子任务后再通过主任务验收");
            }
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
                        buildReviewLogDetail(
                                "验收通过, 质量分: " + task.getQualityScore() + ", 最终积分: " + task.getFinalPoints(),
                                dto.getReviewComment()));
                updateWorkStatusIfNecessary(task.getWorkId());
            }
            return success;
        }

        if (ReviewDecision.REJECT.equals(decision)) {
            boolean assetReview = isAssetReview(task);
            task.setReviewComment(dto.getReviewComment());
            task.setReviewerId(reviewerId);
            task.setReviewedAt(LocalDateTime.now());
            task.setReworkCount(defaultInt(task.getReworkCount()) + 1);
            task.setStatus(TaskStatus.REWORK.name());
            boolean success = this.updateById(task);
            if (success) {
                String action = assetReview ? "ASSET_REVIEW_REJECT" : "REVIEW_REJECT";
                String detailPrefix = assetReview ? "资产同步审核退回: " : "验收退回: ";
                logTaskAction(taskId, reviewerId, action, detailPrefix + nullToEmpty(dto.getReviewComment()));
                updateWorkStatusIfNecessary(task.getWorkId());
            }
            return success;
        }

        if (ReviewDecision.CANCEL.equals(decision)) {
            boolean assetReview = isAssetReview(task);
            task.setReviewComment(dto.getReviewComment());
            task.setReviewerId(reviewerId);
            task.setReviewedAt(LocalDateTime.now());
            task.setStatus(TaskStatus.CANCELLED.name());
            boolean success = this.updateById(task);
            if (success) {
                String action = assetReview ? "ASSET_REVIEW_CANCEL" : "REVIEW_CANCEL";
                String detailPrefix = assetReview ? "资产同步审核取消: " : "验收取消: ";
                logTaskAction(taskId, reviewerId, action, detailPrefix + nullToEmpty(dto.getReviewComment()));
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
            task.setStatus(TaskStatus.READY.name());
            task.setReviewComment(dto.getReviewComment());
            task.setReviewerId(reviewerId);
            task.setReviewedAt(LocalDateTime.now());
            boolean success = this.updateById(task);
            if (success) {
                logTaskAction(taskId, reviewerId, "REVIEW_TRANSFER",
                        buildReviewLogDetail(
                                "任务转派: " + oldAssignee + " -> " + dto.getTransferAssigneeId(),
                                dto.getReviewComment()));
                updateWorkStatusIfNecessary(task.getWorkId());
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
        ensureWorkOperable(task);
        TaskStatus targetStatus;
        try {
            targetStatus = TaskStatus.valueOf(status);
        } catch (IllegalArgumentException | NullPointerException exception) {
            throw new IllegalArgumentException("不支持的任务状态: " + status);
        }
        // Simplified authorization check
        if (TASK_ROLE_MAIN.equals(task.getTaskRole())
                && (TaskStatus.WAITING_REVIEW.equals(targetStatus) || TaskStatus.COMPLETED.equals(targetStatus))
                && !areAllSubTasksClosed(task.getWorkId())) {
            throw new IllegalStateException("请先完成所有子任务后再完成主任务");
        }
        String oldStatus = task.getStatus();
        task.setStatus(targetStatus.name());
        boolean success = this.updateById(task);

        if (success) {
            logTaskAction(taskId, userId, "STATUS_UPDATE", "更新状态: " + oldStatus + " -> " + targetStatus.name());
            updateWorkStatusIfNecessary(task.getWorkId());
        }
        return success;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean reopenTask(String taskId, String userId) {
        WorkTask task = this.getById(taskId);
        if (task == null) {
            throw new IllegalArgumentException("任务不存在");
        }
        ensureWorkOperable(task);
        if (!TaskStatus.CANCELLED.name().equals(task.getStatus())) {
            throw new IllegalStateException("只有已取消的任务可以重新开启");
        }

        Work work = workService.getById(task.getWorkId());
        if (work == null) {
            throw new IllegalStateException("所属工作不存在");
        }
        if (WorkStatus.CANCELLED.name().equals(work.getStatus())) {
            throw new IllegalStateException("所属工作已取消，不能单独重新开启任务");
        }
        if (!userId.equals(task.getAssigneeId()) && !userId.equals(work.getPublisherId())) {
            throw new IllegalStateException("只有任务负责人或工作发布人可以重新开启任务");
        }

        TaskStatus targetStatus = StringUtils.hasText(task.getAssigneeId())
                ? TaskStatus.READY
                : TaskStatus.OPEN;
        task.setStatus(targetStatus.name());
        boolean success = this.updateById(task);
        if (success) {
            logTaskAction(taskId, userId, "REOPEN", "重新开启任务: CANCELLED -> " + targetStatus.name());
            updateWorkStatusIfNecessary(task.getWorkId());
        }
        return success;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean advanceTaskStage(String taskId, String userId, String assetReviewNote) {
        WorkTask task = this.getById(taskId);
        if (task == null) {
            throw new IllegalArgumentException("任务不存在");
        }
        ensureWorkOperable(task);
        if (!userId.equals(task.getAssigneeId())) {
            throw new IllegalStateException("只能推进自己承接的任务阶段");
        }
        if (TaskStatus.COMPLETED.name().equals(task.getStatus())
                || TaskStatus.CANCELLED.name().equals(task.getStatus())
                || TaskStatus.WAITING_REVIEW.name().equals(task.getStatus())) {
            throw new IllegalStateException("当前状态不可推进阶段");
        }
        if (isIssueTrackingTask(task)) {
            if (TASK_ROLE_MAIN.equals(task.getTaskRole()) && !areAllSubTasksClosed(task.getWorkId())) {
                throw new IllegalStateException("请先完成所有子任务后再完成主任务");
            }
            LocalDateTime now = LocalDateTime.now();
            task.setStatus(TaskStatus.COMPLETED.name());
            task.setStageUpdatedAt(now);
            task.setSubmittedAt(now);
            task.setFinalPoints(defaultInt(task.getPoints()));
            task.setKpiPeriod(YearMonth.from(now).toString());
            boolean success = this.updateById(task);
            if (success) {
                logTaskAction(taskId, userId, "ISSUE_TRACKING_COMPLETE", "问题跟踪任务直接完成");
                updateWorkStatusIfNecessary(task.getWorkId());
            }
            return success;
        }
        if (TASK_ROLE_MAIN.equals(task.getTaskRole()) && STAGE_LAUNCH.equals(resolveStage(task))
                && !areAllSubTasksClosed(task.getWorkId())) {
            throw new IllegalStateException("请先完成所有子任务后再提交主任务验收");
        }

        String currentStage = resolveStage(task);
        LocalDateTime now = LocalDateTime.now();
        String trimmedAssetReviewNote = StringUtils.hasText(assetReviewNote) ? assetReviewNote.trim() : null;

        task.setStageRiskReported(StringUtils.hasText(task.getStageRiskNote()));
        task.setStageUpdatedAt(now);
        if (TaskStatus.READY.name().equals(task.getStatus()) || TaskStatus.REWORK.name().equals(task.getStatus())) {
            task.setStatus(TaskStatus.IN_PROGRESS.name());
        }

        if (STAGE_ASSET_REVIEW.equals(currentStage)) {
            task.setSubmittedAt(now);
            task.setStatus(TaskStatus.WAITING_REVIEW.name());
            task.setReviewComment(trimmedAssetReviewNote);
            logTaskAction(taskId, userId, "ASSET_REVIEW_RESUBMIT",
                    buildSubmitLogDetail("重新提交资产同步审核", trimmedAssetReviewNote));
        } else {
            String nextStage = nextStage(currentStage);
            if (STAGE_ASSET_REVIEW.equals(nextStage)) {
                task.setCurrentStage(nextStage);
                task.setSubmittedAt(now);
                task.setStatus(TaskStatus.WAITING_REVIEW.name());
                task.setReviewComment(trimmedAssetReviewNote);
                logTaskAction(taskId, userId, "STAGE_TO_ASSET_REVIEW",
                        buildSubmitLogDetail("测试完成，进入资产同步审核", trimmedAssetReviewNote));
            } else if (nextStage == null) {
                task.setSubmittedAt(now);
                task.setStatus(TaskStatus.WAITING_REVIEW.name());
                logTaskAction(taskId, userId, "STAGE_TO_REVIEW", "上线完成，进入验收阶段");
            } else {
                task.setCurrentStage(nextStage);
                logTaskAction(taskId, userId, "STAGE_ADVANCE", "阶段推进: " + currentStage + " -> " + nextStage);
            }
        }

        boolean success = this.updateById(task);
        if (success) {
            updateWorkStatusIfNecessary(task.getWorkId());
        }
        return success;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean reportTaskStageRisk(String taskId, String riskNote, String userId) {
        WorkTask task = this.getById(taskId);
        if (task == null) {
            throw new IllegalArgumentException("任务不存在");
        }
        ensureWorkOperable(task);
        if (!userId.equals(task.getAssigneeId())) {
            throw new IllegalStateException("只能报备自己承接的任务风险");
        }
        if (!StringUtils.hasText(riskNote)) {
            throw new IllegalArgumentException("风险说明不能为空");
        }
        if (TaskStatus.COMPLETED.name().equals(task.getStatus()) || TaskStatus.CANCELLED.name().equals(task.getStatus())) {
            throw new IllegalStateException("当前状态不可报备风险");
        }

        LocalDateTime now = LocalDateTime.now();
        String trimmedRiskNote = riskNote.trim();
        String currentStage = resolveStage(task);
        String reporterName = resolveUserName(userId);
        String riskEntry = "[" + now.format(RISK_NOTE_TIME_FORMATTER) + "][" + currentStage + "] " + reporterName + "：" + trimmedRiskNote;

        task.setCurrentStage(currentStage);
        task.setStageRiskReported(true);
        if (StringUtils.hasText(task.getStageRiskNote())) {
            task.setStageRiskNote(task.getStageRiskNote().trim() + "\n" + riskEntry);
        } else {
            task.setStageRiskNote(riskEntry);
        }
        task.setStageUpdatedAt(now);
        boolean success = this.updateById(task);
        if (success) {
            logTaskAction(taskId, userId, "STAGE_RISK", "阶段风险报备: " + task.getCurrentStage() + " - " + trimmedRiskNote);
            updateWorkStatusIfNecessary(task.getWorkId());
        }
        return success;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean appendTaskRiskTracking(String taskId, String trackingNote, String userId) {
        WorkTask task = this.getById(taskId);
        if (task == null) {
            throw new IllegalArgumentException("任务不存在");
        }
        ensureWorkOperable(task);
        Work work = workService.getById(task.getWorkId());
        if (work == null || !userId.equals(work.getPublisherId())) {
            throw new IllegalStateException("只有工作发布人可以追加风险跟踪记录");
        }
        if (!StringUtils.hasText(trackingNote)) {
            throw new IllegalArgumentException("跟踪内容不能为空");
        }
        if (TaskStatus.CANCELLED.name().equals(task.getStatus())) {
            throw new IllegalStateException("已取消任务不可追加风险跟踪记录");
        }

        LocalDateTime now = LocalDateTime.now();
        String trimmedNote = trackingNote.trim();
        String trackerName = resolveUserName(userId);
        String trackingEntry = "[" + now.format(RISK_NOTE_TIME_FORMATTER) + "][跟踪] "
                + trackerName + "：" + trimmedNote;
        task.setStageRiskReported(true);
        if (StringUtils.hasText(task.getStageRiskNote())) {
            task.setStageRiskNote(task.getStageRiskNote().trim() + "\n" + trackingEntry);
        } else {
            task.setStageRiskNote(trackingEntry);
        }
        boolean success = this.updateById(task);
        if (success) {
            logTaskAction(taskId, userId, "RISK_TRACKING_APPEND", "追加风险跟踪记录: " + trimmedNote);
        }
        return success;
    }

    @Override
    public void logTaskAction(String taskId, String operatorId, String action, String detail) {
        TaskLog log = new TaskLog();
        log.setTaskId(taskId);
        log.setOperatorId(operatorId);
        log.setAction(action);
        log.setDetail(truncateTaskLogDetail(detail));
        log.setCreateTime(LocalDateTime.now());
        taskLogMapper.insert(log);
    }

    private void updateWorkStatusIfNecessary(String workId) {
        Work work = workService.getById(workId);
        if (work == null)
            return;

        if (WorkStatus.DRAFT.name().equals(work.getStatus()) || WorkStatus.CANCELLED.name().equals(work.getStatus())) {
            return;
        }

        List<WorkTask> tasks = this.lambdaQuery()
                .eq(WorkTask::getWorkId, workId)
                .list();
        WorkTask mainTask = tasks.stream()
                .filter(task -> TASK_ROLE_MAIN.equals(task.getTaskRole()))
                .findFirst()
                .orElse(null);
        if (mainTask == null) {
            throw new IllegalStateException("工作缺少主任务，无法聚合状态");
        }
        List<WorkTask> unfinishedTasks = tasks.stream()
                .filter(task -> !TaskStatus.COMPLETED.name().equals(task.getStatus())
                        && !TaskStatus.CANCELLED.name().equals(task.getStatus()))
                .toList();

        String aggregatedStatus;
        if (TaskStatus.COMPLETED.name().equals(mainTask.getStatus()) && areAllSubTasksClosed(workId)) {
            aggregatedStatus = WorkStatus.COMPLETED.name();
        } else if (TaskStatus.WAITING_REVIEW.name().equals(mainTask.getStatus())
                && STAGE_LAUNCH.equals(resolveStage(mainTask))) {
            aggregatedStatus = WorkStatus.ACCEPTANCE.name();
        } else if (!unfinishedTasks.isEmpty()
                && unfinishedTasks.stream().allMatch(task -> TaskStatus.PAUSED.name().equals(task.getStatus()))) {
            aggregatedStatus = WorkStatus.PAUSED.name();
        } else {
            boolean hasStartedTask = tasks.stream().anyMatch(task ->
                    TaskStatus.IN_PROGRESS.name().equals(task.getStatus())
                            || TaskStatus.WAITING_REVIEW.name().equals(task.getStatus())
                            || TaskStatus.REWORK.name().equals(task.getStatus())
                            || TaskStatus.PAUSED.name().equals(task.getStatus())
                            || TaskStatus.COMPLETED.name().equals(task.getStatus()));
            aggregatedStatus = hasStartedTask ? WorkStatus.ACTIVE.name() : WorkStatus.PUBLISHED.name();
        }

        if (!aggregatedStatus.equals(work.getStatus())) {
            work.setStatus(aggregatedStatus);
            workService.updateById(work);
        }
    }

    private void ensureWorkOperable(WorkTask task) {
        Work work = workService.getById(task.getWorkId());
        if (work != null && WorkStatus.PAUSED.name().equals(work.getStatus())) {
            throw new IllegalStateException("工作已暂停，不允许操作任务");
        }
    }

    private boolean areAllSubTasksClosed(String workId) {
        long unfinishedSubTaskCount = this.lambdaQuery()
                .eq(WorkTask::getWorkId, workId)
                .eq(WorkTask::getTaskRole, TASK_ROLE_SUB)
                .notIn(WorkTask::getStatus, TaskStatus.COMPLETED.name(), TaskStatus.CANCELLED.name())
                .count();
        return unfinishedSubTaskCount == 0;
    }

    @Override
    public TaskMarketDTO getTaskDetail(String taskId) {
        WorkTask task = this.getById(taskId);
        if (task == null) {
            throw new IllegalArgumentException("任务不存在");
        }

        Work work = workService.getById(task.getWorkId());
        TaskMarketDTO dto = buildTaskMarketDTO(task, work);
        dto.setAuditLogs(loadTaskAuditLogs(taskId));
        boolean snapshotFinalized = StringUtils.hasText(task.getAssetMaintenanceSnapshot());
        dto.setAssetMaintenanceSnapshotFinalized(snapshotFinalized);
        if (snapshotFinalized) {
            List<MaintenanceRecord> filteredSnapshotRecords = filterAssetMaintenanceSnapshot(task);
            dto.setAssetMaintenanceSnapshot(serializeAssetMaintenanceRecords(filteredSnapshotRecords));
            dto.setAssetMaintenanceRecords(filteredSnapshotRecords);
        } else if (work != null && StringUtils.hasText(work.getRequirementNumber())) {
            dto.setAssetMaintenanceRecords(getAssetMaintenanceRecords(work, task, false));
        }
        return dto;
    }

    private TaskMarketDTO buildTaskMarketDTO(WorkTask task, Work work) {
        TaskMarketDTO dto = new TaskMarketDTO();
        BeanUtils.copyProperties(task, dto);

        if (work != null) {
            dto.setWorkTitle(work.getTitle());
            dto.setWorkDescription(work.getDescription());
            dto.setWorkPriority(work.getPriority());
            dto.setWorkTotalPoints(work.getTotalPoints());
            dto.setWorkStatus(work.getStatus());
            dto.setWorkPublisherId(work.getPublisherId());
            dto.setWorkDeadline(work.getDeadline());
            dto.setRequirementNumber(work.getRequirementNumber());
            dto.setApplicationDepartment(work.getApplicationDepartment());
            dto.setApplicantName(work.getApplicantName());
            dto.setOwningSystem(work.getOwningSystem());
            dto.setPrimarySystem(work.getPrimarySystem());
            dto.setPrimarySystemName(work.getPrimarySystemName());
            dto.setProjectType(work.getProjectType());
            dto.setAttachments(work.getAttachments());
            dto.setWorkCreateTime(work.getCreateTime());
            dto.setWorkUpdateTime(work.getUpdateTime());

            User publisher = userMapper.selectById(work.getPublisherId());
            if (publisher != null) {
                dto.setPublisherName(publisher.getName());
                dto.setPublisherAvatar(publisher.getAvatarUrl());
            }
        }

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

    private List<TaskAuditLogDTO> loadTaskAuditLogs(String taskId) {
        List<TaskLog> logs = taskLogMapper.selectList(new LambdaQueryWrapper<TaskLog>()
                .eq(TaskLog::getTaskId, taskId)
                .orderByDesc(TaskLog::getCreateTime));
        List<String> operatorIds = logs.stream()
                .map(TaskLog::getOperatorId)
                .filter(StringUtils::hasText)
                .distinct()
                .toList();
        Map<String, User> operatorMap = operatorIds.isEmpty()
                ? Collections.emptyMap()
                : userMapper.selectBatchIds(operatorIds).stream()
                        .collect(Collectors.toMap(user -> user.getId().toString(), Function.identity()));

        return logs.stream().map(log -> {
            TaskAuditLogDTO dto = new TaskAuditLogDTO();
            BeanUtils.copyProperties(log, dto);
            User operator = operatorMap.get(log.getOperatorId());
            dto.setOperatorName(operator != null && StringUtils.hasText(operator.getName())
                    ? operator.getName()
                    : log.getOperatorId());
            return dto;
        }).collect(Collectors.toList());
    }

    private TaskReviewHistoryDTO buildReviewHistoryDTO(
            TaskLog log,
            Map<String, WorkTask> taskMap,
            Map<String, Work> workMap,
            Map<String, User> reviewerMap) {
        TaskReviewHistoryDTO dto = new TaskReviewHistoryDTO();
        WorkTask task = taskMap.get(log.getTaskId());
        Work work = task == null ? null : workMap.get(task.getWorkId());
        User reviewer = reviewerMap.get(log.getOperatorId());

        dto.setId(log.getId());
        dto.setTaskId(log.getTaskId());
        dto.setTaskTitle(task != null ? task.getTitle() : "任务已删除");
        dto.setTaskStatus(task != null ? task.getStatus() : null);
        dto.setWorkId(task != null ? task.getWorkId() : null);
        dto.setWorkTitle(work != null ? work.getTitle() : null);
        dto.setRequirementNumber(work != null ? work.getRequirementNumber() : null);
        dto.setReviewType(log.getAction().startsWith("ASSET_REVIEW_") ? "ASSET_REVIEW" : "ACCEPTANCE");
        dto.setDecision(resolveReviewDecision(log.getAction()));
        dto.setAction(log.getAction());
        dto.setDetail(log.getDetail());
        dto.setReviewerId(log.getOperatorId());
        dto.setReviewerName(reviewer != null && StringUtils.hasText(reviewer.getName())
                ? reviewer.getName()
                : log.getOperatorId());
        dto.setReviewedAt(log.getCreateTime());
        return dto;
    }

    private String resolveReviewDecision(String action) {
        if (action.endsWith("_APPROVE")) {
            return "APPROVE";
        }
        if (action.endsWith("_REJECT")) {
            return "REJECT";
        }
        if (action.endsWith("_CANCEL")) {
            return "CANCEL";
        }
        if (action.endsWith("_TRANSFER")) {
            return "TRANSFER";
        }
        return action;
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

    private String resolveUserName(String userId) {
        User user = userMapper.selectById(userId);
        if (user != null && StringUtils.hasText(user.getName())) {
            return user.getName();
        }
        return userId;
    }

    private String resolveStage(WorkTask task) {
        return StringUtils.hasText(task.getCurrentStage()) ? task.getCurrentStage() : STAGE_REQUIREMENT;
    }

    private String nextStage(String currentStage) {
        return switch (currentStage) {
            case STAGE_REQUIREMENT -> STAGE_DEVELOPMENT;
            case STAGE_DEVELOPMENT -> STAGE_TESTING;
            case STAGE_TESTING -> STAGE_ASSET_REVIEW;
            default -> null;
        };
    }

    private boolean isAssetReview(WorkTask task) {
        return task != null
                && STAGE_ASSET_REVIEW.equals(resolveStage(task))
                && TaskStatus.WAITING_REVIEW.name().equals(task.getStatus());
    }

    private boolean isIssueTrackingTask(WorkTask task) {
        if (task == null || !StringUtils.hasText(task.getTaskType())) {
            return false;
        }
        String taskType = task.getTaskType().trim();
        return "问题跟踪".equals(taskType) || "问题追踪".equals(taskType);
    }

    private List<MaintenanceRecord> getAssetMaintenanceRecords(Work work, WorkTask task, boolean assigneeRequired) {
        if (work == null || !StringUtils.hasText(work.getRequirementNumber())) {
            throw new IllegalStateException("工作缺少需求编号，无法校验资产管理维护记录");
        }
        String assigneeName = getTaskAssigneeName(task, assigneeRequired);
        if (!StringUtils.hasText(assigneeName)) {
            return Collections.emptyList();
        }
        String requirementNumber = work.getRequirementNumber().trim();
        return maintenanceRecordService.list(new LambdaQueryWrapper<MaintenanceRecord>()
                .like(MaintenanceRecord::getReqId, requirementNumber)
                .eq(MaintenanceRecord::getOperator, assigneeName));
    }

    private List<MaintenanceRecord> filterAssetMaintenanceSnapshot(WorkTask task) {
        String assigneeName = getTaskAssigneeName(task, false);
        if (!StringUtils.hasText(assigneeName)) {
            return Collections.emptyList();
        }
        try {
            List<MaintenanceRecord> records = objectMapper.readValue(
                    task.getAssetMaintenanceSnapshot(),
                    new TypeReference<List<MaintenanceRecord>>() {
                    });
            return records.stream()
                    .filter(record -> assigneeName.equals(record.getOperator() == null
                            ? null
                            : record.getOperator().trim()))
                    .collect(Collectors.toList());
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("资产管理维护记录快照读取失败", e);
        }
    }

    private String getTaskAssigneeName(WorkTask task, boolean required) {
        if (task == null || !StringUtils.hasText(task.getAssigneeId())) {
            if (required) {
                throw new IllegalStateException("任务未分配承接人，无法匹配资产管理维护记录");
            }
            return null;
        }
        User assignee = userMapper.selectById(task.getAssigneeId());
        if (assignee == null || !StringUtils.hasText(assignee.getName())) {
            if (required) {
                throw new IllegalStateException("未找到任务承接人，无法匹配资产管理维护记录");
            }
            return null;
        }
        return assignee.getName().trim();
    }

    private String serializeAssetMaintenanceRecords(List<MaintenanceRecord> records) {
        try {
            return objectMapper.writeValueAsString(records);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("资产管理维护记录快照保存失败", e);
        }
    }

    private String buildAssetReviewComment(String submitterNote, String reviewerComment) {
        String trimmedSubmitterNote = StringUtils.hasText(submitterNote) ? submitterNote.trim() : null;
        String trimmedReviewerComment = StringUtils.hasText(reviewerComment) ? reviewerComment.trim() : null;
        if (trimmedSubmitterNote == null) {
            return trimmedReviewerComment;
        }
        if (trimmedReviewerComment == null) {
            return "提交说明: " + trimmedSubmitterNote;
        }
        return "提交说明: " + trimmedSubmitterNote + "\n审核意见: " + trimmedReviewerComment;
    }

    private String buildReviewLogDetail(String summary, String reviewComment) {
        return StringUtils.hasText(reviewComment)
                ? summary + "\n审核意见: " + reviewComment.trim()
                : summary;
    }

    private String buildSubmitLogDetail(String summary, String submitterNote) {
        return StringUtils.hasText(submitterNote)
                ? summary + "\n提交说明: " + submitterNote.trim()
                : summary;
    }

    private String truncateTaskLogDetail(String detail) {
        if (detail == null || detail.length() <= TASK_LOG_DETAIL_MAX_LENGTH) {
            return detail;
        }
        return detail.substring(0, TASK_LOG_DETAIL_MAX_LENGTH - 3) + "...";
    }

    private String nullToEmpty(String value) {
        return value == null ? "" : value;
    }
}
