package com.example.urgs_api.marketplace.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.marketplace.enums.AssignMode;
import com.example.urgs_api.marketplace.enums.TaskStatus;
import com.example.urgs_api.marketplace.mapper.TaskApplicationMapper;
import com.example.urgs_api.marketplace.model.TaskApplication;
import com.example.urgs_api.marketplace.model.Work;
import com.example.urgs_api.marketplace.model.WorkTask;
import com.example.urgs_api.marketplace.service.TaskApplicationService;
import com.example.urgs_api.marketplace.service.WorkService;
import com.example.urgs_api.marketplace.service.WorkTaskService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class TaskApplicationServiceImpl extends ServiceImpl<TaskApplicationMapper, TaskApplication>
        implements TaskApplicationService {

    @Autowired
    private WorkTaskService workTaskService;

    @Autowired
    private WorkService workService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean applyForTask(String taskId, String applicantId, String message) {
        WorkTask task = workTaskService.getById(taskId);
        if (task == null || (!TaskStatus.OPEN.name().equals(task.getStatus())
                && !TaskStatus.APPLIED.name().equals(task.getStatus()))) {
            throw new IllegalStateException("任务目前不可申请");
        }

        if (!AssignMode.COMPETE.name().equals(task.getAssignMode())) {
            throw new IllegalStateException("该任务不支持竞标申请");
        }

        // Check if already applied
        long count = this.lambdaQuery()
                .eq(TaskApplication::getTaskId, taskId)
                .eq(TaskApplication::getApplicantId, applicantId)
                .in(TaskApplication::getStatus, "PENDING", "ACCEPTED")
                .count();
        if (count > 0) {
            throw new IllegalStateException("你已经申请过该任务");
        }

        // Check max applicants
        if (task.getMaxApplicants() != null && task.getMaxApplicants() > 0) {
            long currentApps = this.lambdaQuery().eq(TaskApplication::getTaskId, taskId).count();
            if (currentApps >= task.getMaxApplicants()) {
                throw new IllegalStateException("该任务申请人数已满");
            }
        }

        TaskApplication application = new TaskApplication();
        application.setTaskId(taskId);
        application.setApplicantId(applicantId);
        application.setMessage(message);
        application.setStatus("PENDING");
        boolean success = this.save(application);

        if (success && TaskStatus.OPEN.name().equals(task.getStatus())) {
            task.setStatus(TaskStatus.APPLIED.name());
            workTaskService.updateById(task);
        }

        if (success) {
            workTaskService.logTaskAction(taskId, applicantId, "APPLY", "提交了竞标申请");
        }
        return success;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean approveApplication(String applicationId, String currentUserId) {
        TaskApplication application = this.getById(applicationId);
        if (application == null || !"PENDING".equals(application.getStatus())) {
            throw new IllegalArgumentException("申请记录不存在或已处理");
        }

        WorkTask task = workTaskService.getById(application.getTaskId());
        Work work = workService.getById(task.getWorkId());

        if (!work.getPublisherId().equals(currentUserId)) {
            throw new IllegalStateException("无权审批该申请");
        }

        // Approve this one
        application.setStatus("ACCEPTED");
        application.setUpdateTime(LocalDateTime.now());
        boolean success = this.updateById(application);

        if (success) {
            // Reject all others
            List<TaskApplication> others = this.lambdaQuery()
                    .eq(TaskApplication::getTaskId, task.getId())
                    .eq(TaskApplication::getStatus, "PENDING")
                    .ne(TaskApplication::getId, applicationId)
                    .list();
            for (TaskApplication other : others) {
                other.setStatus("REJECTED");
                other.setUpdateTime(LocalDateTime.now());
                this.updateById(other);
            }

            // Update task status
            task.setStatus(TaskStatus.ASSIGNED.name());
            task.setAssigneeId(application.getApplicantId());
            workTaskService.updateById(task);

            workTaskService.logTaskAction(task.getId(), currentUserId, "APPROVE_APP",
                    "通过了竞标申请, 负责人: " + application.getApplicantId());
        }
        return success;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean rejectApplication(String applicationId, String currentUserId) {
        TaskApplication application = this.getById(applicationId);
        if (application == null || !"PENDING".equals(application.getStatus())) {
            throw new IllegalArgumentException("申请记录不存在或已处理");
        }

        WorkTask task = workTaskService.getById(application.getTaskId());
        Work work = workService.getById(task.getWorkId());

        if (!work.getPublisherId().equals(currentUserId)) {
            throw new IllegalStateException("无权审批该申请");
        }

        application.setStatus("REJECTED");
        application.setUpdateTime(LocalDateTime.now());
        boolean success = this.updateById(application);

        if (success) {
            // If no more pending applications, change task status back to OPEN
            long pendingCount = this.lambdaQuery()
                    .eq(TaskApplication::getTaskId, task.getId())
                    .eq(TaskApplication::getStatus, "PENDING")
                    .count();
            if (pendingCount == 0 && TaskStatus.APPLIED.name().equals(task.getStatus())) {
                task.setStatus(TaskStatus.OPEN.name());
                workTaskService.updateById(task);
            }

            workTaskService.logTaskAction(task.getId(), currentUserId, "REJECT_APP",
                    "驳回了竞标申请: " + application.getApplicantId());
        }

        return success;
    }
}
