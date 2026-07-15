package com.example.urgs_api.marketplace.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.marketplace.dto.TaskApplicationDTO;
import com.example.urgs_api.marketplace.enums.AssignMode;
import com.example.urgs_api.marketplace.enums.TaskStatus;
import com.example.urgs_api.marketplace.enums.WorkStatus;
import com.example.urgs_api.marketplace.mapper.TaskApplicationMapper;
import com.example.urgs_api.marketplace.model.TaskApplication;
import com.example.urgs_api.marketplace.model.Work;
import com.example.urgs_api.marketplace.model.WorkTask;
import com.example.urgs_api.marketplace.service.TaskApplicationService;
import com.example.urgs_api.marketplace.service.WorkService;
import com.example.urgs_api.marketplace.service.WorkTaskService;
import com.example.urgs_api.user.mapper.UserMapper;
import com.example.urgs_api.user.model.User;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;

@Service
public class TaskApplicationServiceImpl extends ServiceImpl<TaskApplicationMapper, TaskApplication>
        implements TaskApplicationService {
    private static final String TASK_ROLE_MAIN = "MAIN";

    @Autowired
    private WorkTaskService workTaskService;

    @Autowired
    private WorkService workService;

    @Autowired
    private UserMapper userMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean applyForTask(TaskApplicationDTO dto, String applicantId) {
        if (dto == null || !StringUtils.hasText(dto.getTaskId())) {
            throw new IllegalArgumentException("任务ID不能为空");
        }
        if (!StringUtils.hasText(dto.getMessage())) {
            throw new IllegalArgumentException("申请理由不能为空");
        }
        if (!StringUtils.hasText(dto.getSolution())) {
            throw new IllegalArgumentException("实施方案不能为空");
        }

        WorkTask task = workTaskService.getById(dto.getTaskId());
        if (task == null || !TaskStatus.OPEN.name().equals(task.getStatus())) {
            throw new IllegalStateException("任务目前不可申请");
        }
        if (!AssignMode.COMPETE.name().equals(task.getAssignMode())) {
            throw new IllegalStateException("该任务不支持竞标申请");
        }
        if (TASK_ROLE_MAIN.equals(task.getTaskRole())) {
            throw new IllegalStateException("主任务不支持竞标申请");
        }
        if (task.getDeadline() != null && LocalDateTime.now().isAfter(task.getDeadline())) {
            throw new IllegalStateException("任务已超过截止时间，不能继续竞标");
        }

        Work work = workService.getById(task.getWorkId());
        if (work == null || WorkStatus.DRAFT.name().equals(work.getStatus())
                || WorkStatus.CANCELLED.name().equals(work.getStatus())
                || WorkStatus.COMPLETED.name().equals(work.getStatus())) {
            throw new IllegalStateException("所属需求当前不可竞标");
        }
        if (applicantId.equals(work.getPublisherId())) {
            throw new IllegalStateException("发布人不能竞标自己发布的任务");
        }

        long existingCount = this.lambdaQuery()
                .eq(TaskApplication::getTaskId, task.getId())
                .eq(TaskApplication::getApplicantId, applicantId)
                .in(TaskApplication::getStatus, "PENDING", "ACCEPTED")
                .count();
        if (existingCount > 0) {
            throw new IllegalStateException("你已经申请过该任务");
        }

        if (task.getMaxApplicants() != null && task.getMaxApplicants() > 0) {
            long effectiveApplications = this.lambdaQuery()
                    .eq(TaskApplication::getTaskId, task.getId())
                    .in(TaskApplication::getStatus, "PENDING", "ACCEPTED")
                    .count();
            if (effectiveApplications >= task.getMaxApplicants()) {
                throw new IllegalStateException("该任务申请人数已满");
            }
        }

        TaskApplication application = new TaskApplication();
        application.setTaskId(task.getId());
        application.setApplicantId(applicantId);
        application.setMessage(dto.getMessage());
        application.setSolution(dto.getSolution());
        application.setExpectedCompletionTime(dto.getExpectedCompletionTime());
        application.setStatus("PENDING");
        boolean success = this.save(application);

        if (success) {
            workTaskService.logTaskAction(task.getId(), applicantId, "APPLY",
                    "提交竞标申请: " + dto.getMessage());
        }
        return success;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean approveApplication(String applicationId, String currentUserId, String reviewComment) {
        TaskApplication application = getPendingApplication(applicationId);
        WorkTask task = getApplicationTask(application);
        Work work = getAuthorizedWork(task, currentUserId);

        if (!TaskStatus.OPEN.name().equals(task.getStatus())) {
            throw new IllegalStateException("任务已进入承接或交付流程，不能再审批竞标");
        }

        LocalDateTime now = LocalDateTime.now();
        application.setStatus("ACCEPTED");
        application.setReviewComment(reviewComment);
        application.setReviewedBy(currentUserId);
        application.setReviewedAt(now);
        application.setUpdateTime(now);
        boolean success = this.updateById(application);

        if (success) {
            List<TaskApplication> others = this.lambdaQuery()
                    .eq(TaskApplication::getTaskId, task.getId())
                    .eq(TaskApplication::getStatus, "PENDING")
                    .ne(TaskApplication::getId, applicationId)
                    .list();
            for (TaskApplication other : others) {
                other.setStatus("REJECTED");
                other.setReviewComment("已由其他申请人中标");
                other.setReviewedBy(currentUserId);
                other.setReviewedAt(now);
                other.setUpdateTime(now);
                this.updateById(other);
            }

            task.setStatus(TaskStatus.READY.name());
            task.setAssigneeId(application.getApplicantId());
            task.setReworkCount(defaultInt(task.getReworkCount()));
            task.setBonusPoints(defaultInt(task.getBonusPoints()));
            task.setPenaltyPoints(defaultInt(task.getPenaltyPoints()));
            task.setFinalPoints(defaultInt(task.getFinalPoints()));
            workTaskService.updateById(task);

            workTaskService.logTaskAction(task.getId(), currentUserId, "APPROVE_APP",
                    "竞标中标, 承接人: " + application.getApplicantId());
        }
        return success;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean rejectApplication(String applicationId, String currentUserId, String reviewComment) {
        TaskApplication application = getPendingApplication(applicationId);
        WorkTask task = getApplicationTask(application);
        getAuthorizedWork(task, currentUserId);

        LocalDateTime now = LocalDateTime.now();
        application.setStatus("REJECTED");
        application.setReviewComment(reviewComment);
        application.setReviewedBy(currentUserId);
        application.setReviewedAt(now);
        application.setUpdateTime(now);
        boolean success = this.updateById(application);

        if (success) {
            workTaskService.logTaskAction(task.getId(), currentUserId, "REJECT_APP",
                    "驳回竞标申请: " + application.getApplicantId());
        }

        return success;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean withdrawApplication(String applicationId, String applicantId) {
        TaskApplication application = this.getById(applicationId);
        if (application == null || !"PENDING".equals(application.getStatus())) {
            throw new IllegalArgumentException("申请记录不存在或已处理");
        }
        if (!applicantId.equals(application.getApplicantId())) {
            throw new IllegalStateException("只能撤回自己的竞标申请");
        }

        WorkTask task = getApplicationTask(application);
        LocalDateTime now = LocalDateTime.now();
        application.setStatus("WITHDRAWN");
        application.setReviewComment("申请人撤回竞标");
        application.setReviewedBy(applicantId);
        application.setReviewedAt(now);
        application.setUpdateTime(now);
        boolean success = this.updateById(application);
        if (success) {
            workTaskService.logTaskAction(task.getId(), applicantId, "WITHDRAW_APP", "撤回竞标申请");
        }
        return success;
    }

    @Override
    public Page<TaskApplicationDTO> listTaskApplications(Page<TaskApplication> page, String taskId, String currentUserId) {
        WorkTask task = workTaskService.getById(taskId);
        if (task == null) {
            throw new IllegalArgumentException("任务不存在");
        }
        getAuthorizedWork(task, currentUserId);

        Page<TaskApplication> applicationPage = this.page(page, new LambdaQueryWrapper<TaskApplication>()
                .eq(TaskApplication::getTaskId, taskId)
                .orderByDesc(TaskApplication::getCreateTime));
        return toDtoPage(applicationPage);
    }

    @Override
    public Page<TaskApplicationDTO> listMyApplications(Page<TaskApplication> page, String applicantId) {
        Page<TaskApplication> applicationPage = this.page(page, new LambdaQueryWrapper<TaskApplication>()
                .eq(TaskApplication::getApplicantId, applicantId)
                .orderByDesc(TaskApplication::getCreateTime));
        return toDtoPage(applicationPage);
    }

    private TaskApplication getPendingApplication(String applicationId) {
        TaskApplication application = this.getById(applicationId);
        if (application == null || !"PENDING".equals(application.getStatus())) {
            throw new IllegalArgumentException("申请记录不存在或已处理");
        }
        return application;
    }

    private WorkTask getApplicationTask(TaskApplication application) {
        WorkTask task = workTaskService.getById(application.getTaskId());
        if (task == null) {
            throw new IllegalArgumentException("任务不存在");
        }
        return task;
    }

    private Work getAuthorizedWork(WorkTask task, String currentUserId) {
        Work work = workService.getById(task.getWorkId());
        if (work == null || !currentUserId.equals(work.getPublisherId())) {
            throw new IllegalStateException("无权审批该竞标申请");
        }
        return work;
    }

    private Page<TaskApplicationDTO> toDtoPage(Page<TaskApplication> applicationPage) {
        Page<TaskApplicationDTO> dtoPage = new Page<>();
        BeanUtils.copyProperties(applicationPage, dtoPage, "records");
        dtoPage.setRecords(applicationPage.getRecords().stream()
                .map(this::buildDto)
                .toList());
        return dtoPage;
    }

    private TaskApplicationDTO buildDto(TaskApplication application) {
        TaskApplicationDTO dto = new TaskApplicationDTO();
        BeanUtils.copyProperties(application, dto);

        WorkTask task = workTaskService.getById(application.getTaskId());
        if (task != null) {
            dto.setTaskTitle(task.getTitle());
            dto.setWorkId(task.getWorkId());
            dto.setTaskPoints(task.getPoints());
            Work work = workService.getById(task.getWorkId());
            dto.setWorkTitle(work != null ? work.getTitle() : null);
        }

        User applicant = userMapper.selectById(application.getApplicantId());
        dto.setApplicantName(applicant != null ? applicant.getName() : application.getApplicantId());
        enrichApplicantStats(dto, application.getApplicantId());
        return dto;
    }

    private void enrichApplicantStats(TaskApplicationDTO dto, String applicantId) {
        List<WorkTask> completedTasks = workTaskService.lambdaQuery()
                .eq(WorkTask::getAssigneeId, applicantId)
                .eq(WorkTask::getStatus, TaskStatus.COMPLETED.name())
                .list();
        dto.setCompletedTaskCount(completedTasks.size());
        dto.setFinalPoints(completedTasks.stream().mapToInt(task -> defaultInt(task.getFinalPoints())).sum());
        dto.setAverageQualityScore(completedTasks.isEmpty() ? 0D : round(completedTasks.stream()
                .map(WorkTask::getQualityScore)
                .filter(Objects::nonNull)
                .mapToInt(Integer::intValue)
                .average()
                .orElse(0D)));
        dto.setOnTimeRate(completedTasks.isEmpty() ? 0D : round(completedTasks.stream()
                .filter(this::isOnTime)
                .count() * 100D / completedTasks.size()));
        dto.setCurrentLoad(Math.toIntExact(workTaskService.lambdaQuery()
                .eq(WorkTask::getAssigneeId, applicantId)
                .in(WorkTask::getStatus, TaskStatus.READY.name(), TaskStatus.IN_PROGRESS.name(),
                        TaskStatus.WAITING_REVIEW.name(), TaskStatus.REWORK.name(), TaskStatus.PAUSED.name())
                .count()));
    }

    private boolean isOnTime(WorkTask task) {
        return task.getDeadline() == null || task.getSubmittedAt() == null || !task.getSubmittedAt().isAfter(task.getDeadline());
    }

    private Double round(double value) {
        return Math.round(value * 100D) / 100D;
    }

    private int defaultInt(Integer value) {
        return value == null ? 0 : value;
    }
}
