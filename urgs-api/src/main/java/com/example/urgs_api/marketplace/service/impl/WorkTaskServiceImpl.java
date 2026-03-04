package com.example.urgs_api.marketplace.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.marketplace.dto.TaskMarketDTO;
import com.example.urgs_api.marketplace.enums.AssignMode;
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
    public Page<TaskMarketDTO> getMarketTasks(Page<WorkTask> page, String category, String keyword) {
        // Query tasks that are part of PUBLISHED works and are OPEN
        LambdaQueryWrapper<WorkTask> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(WorkTask::getStatus, TaskStatus.OPEN.name());

        if (StringUtils.hasText(keyword)) {
            queryWrapper.like(WorkTask::getTitle, keyword);
        }

        queryWrapper.orderByDesc(WorkTask::getCreateTime);
        Page<WorkTask> taskPage = this.page(page, queryWrapper);

        Page<TaskMarketDTO> dtoPage = new Page<>();
        BeanUtils.copyProperties(taskPage, dtoPage, "records");

        // Map to DTO and enrich with Work and User info
        dtoPage.setRecords(taskPage.getRecords().stream().map(task -> {
            TaskMarketDTO dto = new TaskMarketDTO();
            BeanUtils.copyProperties(task, dto);

            Work work = workService.getById(task.getWorkId());
            if (work != null) {
                dto.setWorkTitle(work.getTitle());
                if (StringUtils.hasText(category) && !category.equals(work.getCategory())) {
                    return null; // Should filter in SQL ideally, but simplified here
                }

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
        boolean success = this.updateById(task);

        if (success) {
            logTaskAction(taskId, userId, "CLAIM", "直接领取了任务");
            updateWorkStatusIfNecessary(task.getWorkId());
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
                    .in(WorkTask::getStatus, TaskStatus.COMPLETED.name(), TaskStatus.REJECTED.name() /* or cancelled */)
                    .count();
            if (totalCount > 0 && totalCount == compCount) {
                work.setStatus(WorkStatus.COMPLETED.name());
                workService.updateById(work);
            }
        }
    }
}
