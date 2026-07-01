package com.example.urgs_api.marketplace.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.marketplace.dto.WorkCreateDTO;
import com.example.urgs_api.marketplace.dto.WorkImportDTO;
import com.example.urgs_api.marketplace.dto.WorkTaskCreateDTO;
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
    private static final String TASK_ROLE_MAIN = "MAIN";
    private static final String TASK_ROLE_SUB = "SUB";
    private static final String STAGE_REQUIREMENT = "REQUIREMENT";

    @Autowired
    @org.springframework.context.annotation.Lazy
    private WorkTaskService workTaskService;

    @Autowired
    private ObjectMapper objectMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Work createWork(WorkCreateDTO dto, String userId) {
        if (dto.getMainTask() == null) {
            throw new IllegalArgumentException("工作必须包含一个主任务");
        }

        Work work = new Work();
        work.setTitle(dto.getTitle());
        work.setDescription(dto.getDescription());
        work.setPriority(dto.getPriority() != null ? dto.getPriority() : "P2");
        work.setStatus(WorkStatus.DRAFT.name());
        work.setPublisherId(userId);
        work.setDeadline(dto.getDeadline());
        work.setRequirementNumber(dto.getRequirementNumber());
        work.setApplicationDepartment(dto.getApplicationDepartment());
        work.setApplicantName(dto.getApplicantName());
        work.setOwningSystem(dto.getOwningSystem());
        work.setPrimarySystem(dto.getPrimarySystem() != null ? dto.getPrimarySystem() : true);
        work.setPrimarySystemName(dto.getPrimarySystemName());
        work.setProjectType(dto.getProjectType());

        if (dto.getAttachments() != null && !dto.getAttachments().isEmpty()) {
            try {
                work.setAttachments(objectMapper.writeValueAsString(dto.getAttachments()));
            } catch (JsonProcessingException e) {
                log.error("Failed to serialize attachments for work: {}", dto.getTitle(), e);
            }
        }

        int totalPoints = defaultPoints(dto.getMainTask());
        if (dto.getTasks() != null) {
            for (var taskDto : dto.getTasks()) {
                totalPoints += defaultPoints(taskDto);
            }
        }
        work.setTotalPoints(totalPoints);
        this.save(work);

        WorkTask mainTask = buildTask(work.getId(), dto.getMainTask(), TASK_ROLE_MAIN, null, 0, userId);
        mainTask.setAssignMode(AssignMode.ASSIGN.name());
        if (mainTask.getAssigneeId() == null || mainTask.getAssigneeId().isEmpty()) {
            mainTask.setAssigneeId(userId);
        }
        mainTask.setStatus(TaskStatus.ASSIGNED.name());
        workTaskService.save(mainTask);

        if (dto.getTasks() != null && !dto.getTasks().isEmpty()) {
            List<WorkTask> taskList = new ArrayList<>();
            int order = 1;
            for (var taskDto : dto.getTasks()) {
                taskList.add(buildTask(work.getId(), taskDto, TASK_ROLE_SUB, mainTask.getId(), order++, userId));
            }
            workTaskService.saveBatch(taskList);
        }
        return work;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public int importWorks(List<WorkImportDTO> works, String userId) {
        if (works == null || works.isEmpty()) {
            throw new IllegalArgumentException("导入数据不能为空");
        }
        if (works.size() > 500) {
            throw new IllegalArgumentException("单次最多导入500条工作");
        }

        for (int index = 0; index < works.size(); index++) {
            WorkImportDTO importDTO = works.get(index);
            if (Boolean.FALSE.equals(importDTO.getPrimarySystem())
                    && isBlank(importDTO.getPrimarySystemName())) {
                throw new IllegalArgumentException("第" + (index + 2) + "行：非主系统必须填写主系统名称");
            }

            WorkCreateDTO createDTO = new WorkCreateDTO();
            createDTO.setTitle(trim(importDTO.getTitle()));
            createDTO.setDescription(trim(importDTO.getDescription()));
            createDTO.setPriority(trim(importDTO.getPriority()));
            createDTO.setDeadline(importDTO.getDeadline());
            createDTO.setRequirementNumber(trimToNull(importDTO.getRequirementNumber()));
            createDTO.setApplicationDepartment(trim(importDTO.getApplicationDepartment()));
            createDTO.setApplicantName(trim(importDTO.getApplicantName()));
            createDTO.setOwningSystem(trim(importDTO.getOwningSystem()));
            createDTO.setPrimarySystem(importDTO.getPrimarySystem());
            createDTO.setPrimarySystemName(Boolean.TRUE.equals(importDTO.getPrimarySystem())
                    ? null
                    : trimToNull(importDTO.getPrimarySystemName()));
            createDTO.setProjectType(trim(importDTO.getProjectType()));

            WorkTaskCreateDTO mainTask = new WorkTaskCreateDTO();
            mainTask.setTitle(createDTO.getTitle());
            mainTask.setDescription(createDTO.getDescription());
            mainTask.setTaskType("主任务");
            mainTask.setPoints(0);
            mainTask.setAssignMode(AssignMode.ASSIGN.name());
            mainTask.setAssigneeId(userId);
            mainTask.setDeadline(createDTO.getDeadline());
            createDTO.setMainTask(mainTask);

            createWork(createDTO, userId);
        }
        return works.size();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean publishWork(String workId, String userId) {
        Work work = this.getById(workId);
        if (work == null || !work.getPublisherId().equals(userId)) {
            throw new IllegalArgumentException("工作不存在或无权操作");
        }
        WorkTask mainTask = workTaskService.lambdaQuery()
                .eq(WorkTask::getWorkId, workId)
                .eq(WorkTask::getTaskRole, TASK_ROLE_MAIN)
                .one();
        if (mainTask == null) {
            throw new IllegalStateException("工作必须包含且仅包含一个主任务");
        }
        if (!WorkStatus.DRAFT.name().equals(work.getStatus())) {
            throw new IllegalStateException("只能发布草稿状态的工作");
        }

        work.setStatus(mainTask.getStatus());
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

    @Override
    public void recomputeTotalPoints(String workId) {
        Work work = this.getById(workId);
        if (work == null) return;

        List<WorkTask> tasks = workTaskService.lambdaQuery()
                .eq(WorkTask::getWorkId, workId)
                .list();
        int total = tasks.stream()
                .mapToInt(t -> t.getPoints() != null ? t.getPoints() : 0)
                .sum();
        work.setTotalPoints(total);
        this.updateById(work);
    }

    private WorkTask buildTask(String workId, WorkTaskCreateDTO taskDto, String taskRole, String parentTaskId,
            int sortOrder, String userId) {
        WorkTask task = new WorkTask();
        task.setWorkId(workId);
        task.setTaskRole(taskRole);
        task.setParentTaskId(parentTaskId);
        task.setCurrentStage(taskDto.getCurrentStage() != null ? taskDto.getCurrentStage() : STAGE_REQUIREMENT);
        task.setStageRiskReported(false);
        task.setTitle(taskDto.getTitle());
        task.setDescription(taskDto.getDescription());
        task.setTaskType(taskDto.getTaskType());
        task.setDifficulty(taskDto.getDifficulty());
        task.setRequiredSkills(taskDto.getRequiredSkills());
        task.setAcceptanceCriteria(taskDto.getAcceptanceCriteria());
        task.setPoints(defaultPoints(taskDto));
        task.setEstimatedHours(taskDto.getEstimatedHours());
        task.setAssignMode(taskDto.getAssignMode());
        task.setDeadline(taskDto.getDeadline());
        task.setSortOrder(sortOrder);
        task.setReworkCount(0);
        task.setBonusPoints(0);
        task.setPenaltyPoints(0);
        task.setFinalPoints(0);

        if (taskDto.getAssigneeId() != null && !taskDto.getAssigneeId().isEmpty()) {
            task.setAssigneeId(taskDto.getAssigneeId());
        }

        if (TASK_ROLE_MAIN.equals(taskRole)) {
            task.setAssignMode(AssignMode.ASSIGN.name());
            task.setAssigneeId(task.getAssigneeId() != null ? task.getAssigneeId() : userId);
            task.setMaxApplicants(0);
            task.setStatus(TaskStatus.ASSIGNED.name());
            return task;
        }

        if (AssignMode.ASSIGN.name().equals(task.getAssignMode()) && task.getAssigneeId() != null) {
            task.setStatus(TaskStatus.ASSIGNED.name());
        } else {
            task.setMaxApplicants(taskDto.getMaxApplicants() != null ? taskDto.getMaxApplicants() : 0);
            task.setStatus(TaskStatus.OPEN.name());
        }
        return task;
    }

    private int defaultPoints(WorkTaskCreateDTO taskDto) {
        return taskDto != null && taskDto.getPoints() != null ? taskDto.getPoints() : 0;
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }

    private String trimToNull(String value) {
        String trimmed = trim(value);
        return isBlank(trimmed) ? null : trimmed;
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
