package com.example.urgs_api.marketplace.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.marketplace.dto.WorkCreateDTO;
import com.example.urgs_api.marketplace.enums.AssignMode;
import com.example.urgs_api.marketplace.enums.TaskStatus;
import com.example.urgs_api.marketplace.enums.WorkStatus;
import com.example.urgs_api.marketplace.mapper.WorkMapper;
import com.example.urgs_api.marketplace.model.Work;
import com.example.urgs_api.marketplace.model.WorkTask;
import com.example.urgs_api.marketplace.service.WorkService;
import com.example.urgs_api.marketplace.service.WorkTaskService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
public class WorkServiceImpl extends ServiceImpl<WorkMapper, Work> implements WorkService {

    @Autowired
    @org.springframework.context.annotation.Lazy
    private WorkTaskService workTaskService;

    @Autowired
    private ObjectMapper objectMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Work createWork(WorkCreateDTO dto, String userId) {
        Work work = new Work();
        work.setTitle(dto.getTitle());
        work.setDescription(dto.getDescription());
        work.setCategory(dto.getCategory());
        work.setPriority(dto.getPriority() != null ? dto.getPriority() : "P2");
        work.setStatus(WorkStatus.DRAFT.name());
        work.setPublisherId(userId);
        work.setDeadline(dto.getDeadline());
        work.setRequirementNumber(dto.getRequirementNumber());

        if (dto.getAttachments() != null && !dto.getAttachments().isEmpty()) {
            try {
                work.setAttachments(objectMapper.writeValueAsString(dto.getAttachments()));
            } catch (JsonProcessingException e) {
                log.error("Failed to serialize attachments for work: {}", dto.getTitle(), e);
            }
        }

        // Calculate total points
        int totalPoints = 0;
        if (dto.getTasks() != null) {
            for (var taskDto : dto.getTasks()) {
                totalPoints += (taskDto.getPoints() != null ? taskDto.getPoints() : 0);
            }
        }
        work.setTotalPoints(totalPoints);
        this.save(work);

        // Save tasks
        if (dto.getTasks() != null && !dto.getTasks().isEmpty()) {
            List<WorkTask> taskList = new ArrayList<>();
            int order = 1;
            for (var taskDto : dto.getTasks()) {
                WorkTask task = new WorkTask();
                task.setWorkId(work.getId());
                task.setTitle(taskDto.getTitle());
                task.setDescription(taskDto.getDescription());
                task.setRequiredSkills(taskDto.getRequiredSkills());
                task.setPoints(taskDto.getPoints() != null ? taskDto.getPoints() : 0);
                task.setAssignMode(taskDto.getAssignMode());
                task.setDeadline(taskDto.getDeadline());
                task.setSortOrder(order++);

                // Initialize task status based on assign mode
                if (AssignMode.ASSIGN.name().equals(task.getAssignMode()) && taskDto.getAssigneeId() != null) {
                    task.setAssigneeId(taskDto.getAssigneeId());
                    // Task won't be visible in open market if it's assigned straight away when
                    // draft is published
                    task.setStatus(TaskStatus.ASSIGNED.name());
                } else {
                    task.setMaxApplicants(taskDto.getMaxApplicants() != null ? taskDto.getMaxApplicants() : 0);
                    task.setStatus(TaskStatus.OPEN.name());
                }

                taskList.add(task);
            }
            workTaskService.saveBatch(taskList);
        }
        return work;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean publishWork(String workId, String userId) {
        Work work = this.getById(workId);
        if (work == null || !work.getPublisherId().equals(userId)) {
            throw new IllegalArgumentException("工作不存在或无权操作");
        }
        if (!WorkStatus.DRAFT.name().equals(work.getStatus())) {
            throw new IllegalStateException("只能发布草稿状态的工作");
        }

        work.setStatus(WorkStatus.PUBLISHED.name());
        return this.updateById(work);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean cancelWork(String workId, String userId) {
        Work work = this.getById(workId);
        if (work == null || !work.getPublisherId().equals(userId)) {
            throw new IllegalArgumentException("工作不存在或无权操作");
        }
        if (WorkStatus.COMPLETED.name().equals(work.getStatus())
                || WorkStatus.CANCELLED.name().equals(work.getStatus())) {
            throw new IllegalStateException("当前状态无法取消");
        }

        work.setStatus(WorkStatus.CANCELLED.name());
        boolean success = this.updateById(work);

        if (success) {
            // Cancel all related open/assigned tasks
            List<WorkTask> tasks = workTaskService.lambdaQuery()
                    .eq(WorkTask::getWorkId, workId)
                    .in(WorkTask::getStatus, TaskStatus.OPEN.name(), TaskStatus.APPLIED.name(),
                            TaskStatus.ASSIGNED.name())
                    .list();
            for (WorkTask task : tasks) {
                task.setStatus(TaskStatus.REJECTED.name()); // Or create a CANCELLED status, reuse REJECTED/new
                                                            // CANCELLED
                workTaskService.updateById(task);
            }
        }
        return success;
    }
}
