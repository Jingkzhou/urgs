package com.example.urgs_api.marketplace.controller;

import com.example.urgs_api.common.PageResult;
import com.example.urgs_api.marketplace.dto.TaskMarketDTO;
import com.example.urgs_api.marketplace.dto.TaskReviewDTO;
import com.example.urgs_api.marketplace.dto.TaskReviewHistoryDTO;
import com.example.urgs_api.marketplace.dto.TaskStageRiskDTO;
import com.example.urgs_api.marketplace.dto.TaskSubmissionDTO;
import com.example.urgs_api.marketplace.dto.WorkTaskCreateDTO;
import com.example.urgs_api.marketplace.enums.TaskStatus;
import com.example.urgs_api.marketplace.model.Work;
import com.example.urgs_api.marketplace.model.WorkTask;
import com.example.urgs_api.marketplace.service.WorkService;
import com.example.urgs_api.marketplace.service.WorkTaskService;
import com.example.urgs_api.role.model.Role;
import com.example.urgs_api.role.service.RoleService;
import com.example.urgs_api.user.model.User;
import com.example.urgs_api.user.service.UserService;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/marketplace/tasks")
public class WorkTaskController {
    private static final String TASK_ROLE_MAIN = "MAIN";
    private static final String TASK_ROLE_SUB = "SUB";
    private static final String STAGE_TEST_SUBMISSION_COMPLETED = "TEST_SUBMISSION_COMPLETED";

    @Autowired
    private WorkTaskService workTaskService;

    @Autowired
    private WorkService workService;

    @Autowired
    private UserService userService;

    @Autowired
    private RoleService roleService;

    @GetMapping("/work/{workId}")
    public List<WorkTask> getTasksByWorkId(@PathVariable String workId) {
        return workTaskService.lambdaQuery()
                .eq(WorkTask::getWorkId, workId)
                .orderByAsc(WorkTask::getSortOrder)
                .list();
    }

    @PostMapping("/work/{workId}")
    public WorkTask addTaskToWork(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String workId,
            @RequestBody WorkTaskCreateDTO dto) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);

        WorkTask task = new WorkTask();
        task.setWorkId(workId);
        task.setTaskRole(TASK_ROLE_SUB);
        task.setParentTaskId(findMainTaskId(workId));
        task.setCurrentStage(dto.getCurrentStage() != null ? dto.getCurrentStage() : STAGE_TEST_SUBMISSION_COMPLETED);
        task.setStageRiskReported(false);
        task.setTitle(dto.getTitle());
        task.setDescription(dto.getDescription());
        task.setTaskType(dto.getTaskType());
        task.setDifficulty(dto.getDifficulty());
        task.setInvolvedSystemIds(dto.getInvolvedSystemIds());
        task.setRequiredSkills(dto.getRequiredSkills());
        task.setAcceptanceCriteria(dto.getAcceptanceCriteria());
        task.setPoints(dto.getPoints() != null ? dto.getPoints() : 0);
        task.setEstimatedHours(dto.getEstimatedHours());
        task.setAssignMode(dto.getAssignMode());
        task.setDeadline(dto.getDeadline());
        task.setReworkCount(0);
        task.setBonusPoints(0);
        task.setPenaltyPoints(0);
        task.setFinalPoints(0);

        if (dto.getAssigneeId() != null && !dto.getAssigneeId().isEmpty()) {
            task.setAssigneeId(dto.getAssigneeId());
        }
        if (dto.getMaxApplicants() != null) {
            task.setMaxApplicants(dto.getMaxApplicants());
        }

        // Set initial status based on assign mode
        if ("ASSIGN".equals(dto.getAssignMode()) && dto.getAssigneeId() != null) {
            task.setStatus(TaskStatus.READY.name());
        } else {
            task.setMaxApplicants(dto.getMaxApplicants() != null ? dto.getMaxApplicants() : 0);
            task.setStatus(TaskStatus.OPEN.name());
        }

        // Get current max sortOrder and increment
        int nextOrder = workTaskService.lambdaQuery()
                .eq(WorkTask::getWorkId, workId)
                .orderByDesc(WorkTask::getSortOrder)
                .last("LIMIT 1")
                .list()
                .stream()
                .mapToInt(WorkTask::getSortOrder)
                .max()
                .orElse(0) + 1;
        task.setSortOrder(nextOrder);

        workTaskService.save(task);
        workService.recomputeTotalPoints(workId);
        return task;
    }

    @GetMapping
    public PageResult<TaskMarketDTO> getMarketTasks(@RequestParam(defaultValue = "1") int current,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String status) {
        Page<WorkTask> page = new Page<>(current, size);
        Page<TaskMarketDTO> resultPage = workTaskService.getMarketTasks(page, keyword, status);
        return PageResult.of(resultPage);
    }

    @GetMapping("/assignee/{userId}")
    public PageResult<TaskMarketDTO> getAssigneeTasks(
            @PathVariable String userId,
            @RequestParam(defaultValue = "1") int current,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String status,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime deadlineStart,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime deadlineEnd) {
        Page<WorkTask> page = new Page<>(current, size);
        Page<TaskMarketDTO> resultPage = workTaskService.getAssigneeTasks(
                page, userId, status, deadlineStart, deadlineEnd);
        return PageResult.of(resultPage);
    }

    @GetMapping("/{id}")
    public ResponseEntity<TaskMarketDTO> getTaskById(@PathVariable String id) {
        TaskMarketDTO dto = workTaskService.getTaskDetail(id);
        return ResponseEntity.ok(dto);
    }

    @GetMapping("/my")
    public PageResult<TaskMarketDTO> getMyTasks(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @RequestParam(defaultValue = "1") int current,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "false") boolean archived,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "false") boolean overdue,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime deadlineStart,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime deadlineEnd) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        Page<WorkTask> page = new Page<>(current, size);
        Page<TaskMarketDTO> resultPage = workTaskService.getMyTasks(
                page, userId, archived, status, overdue, deadlineStart, deadlineEnd);
        return PageResult.of(resultPage);
    }

    @GetMapping("/review/pending")
    public PageResult<TaskMarketDTO> getPendingReviewTasks(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @RequestParam(defaultValue = "1") int current,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String system,
            @RequestParam(required = false) String requirementNumber,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime deadlineStart,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime deadlineEnd) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        Page<WorkTask> page = new Page<>(current, size);
        Page<TaskMarketDTO> resultPage = workTaskService.getReviewTasks(
                page, resolveReviewPublisherId(userId), false, system, requirementNumber, deadlineStart, deadlineEnd);
        return PageResult.of(resultPage);
    }

    @GetMapping("/review/history")
    public PageResult<TaskReviewHistoryDTO> getReviewHistoryTasks(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @RequestParam(defaultValue = "1") int current,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String system,
            @RequestParam(required = false) String requirementNumber,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime deadlineStart,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime deadlineEnd) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        Page<TaskReviewHistoryDTO> page = new Page<>(current, size);
        Page<TaskReviewHistoryDTO> resultPage = workTaskService.getReviewHistory(
                page, resolveReviewPublisherId(userId), system, requirementNumber, deadlineStart, deadlineEnd);
        return PageResult.of(resultPage);
    }

    @PostMapping("/{id}/claim")
    public ResponseEntity<Void> claimTask(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String id) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        workTaskService.claimTask(id, userId);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/release")
    public ResponseEntity<Void> releaseTask(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String id) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        workTaskService.releaseTask(id, userId);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<Void> updateTaskStatus(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String id,
            @RequestBody Map<String, String> body) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        workTaskService.updateTaskStatus(id, body.get("status"), userId);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/reopen")
    public ResponseEntity<Void> reopenTask(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String id) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        workTaskService.reopenTask(id, resolveAuthorizedPublisherIdByTask(id, userId));
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/stage/advance")
    public ResponseEntity<Void> advanceTaskStage(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String id,
            @RequestBody(required = false) Map<String, String> body) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        workTaskService.advanceTaskStage(id, userId, body != null ? body.get("assetReviewNote") : null);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/stage/risk")
    public ResponseEntity<Void> reportTaskStageRisk(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String id,
            @RequestBody TaskStageRiskDTO dto) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        workTaskService.reportTaskStageRisk(id, dto.getRiskNote(), userId);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/stage/risk/tracking")
    public ResponseEntity<Void> appendTaskRiskTracking(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String id,
            @RequestBody Map<String, String> body) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        workTaskService.appendTaskRiskTracking(id, body.get("trackingNote"), userId);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/submit")
    public ResponseEntity<Void> submitForReview(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String id,
            @RequestBody TaskSubmissionDTO dto) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        workTaskService.submitForReview(id, dto, userId);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/review")
    public ResponseEntity<Void> reviewTask(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String id,
            @RequestBody TaskReviewDTO dto) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        workTaskService.reviewTask(id, dto, userId, resolveAuthorizedPublisherIdByTask(id, userId));
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/assign")
    public ResponseEntity<Void> assignTask(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String id,
            @RequestBody Map<String, String> body) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        workTaskService.assignTask(id, body.get("assigneeId"), resolveAuthorizedPublisherIdByTask(id, userId));
        return ResponseEntity.ok().build();
    }

    private String getEffectiveUserId(String headerUserId, Long attrUserId) {
        if (headerUserId != null && !headerUserId.isEmpty()) {
            return headerUserId;
        }
        if (attrUserId != null) {
            return String.valueOf(attrUserId);
        }
        throw new IllegalArgumentException("Missing user identifier");
    }

    private String resolveReviewPublisherId(String userId) {
        return isRegTechAdmin(userId) ? null : userId;
    }

    private String resolveAuthorizedPublisherIdByTask(String taskId, String userId) {
        WorkTask task = workTaskService.getById(taskId);
        if (!isRegTechAdmin(userId) || task == null) {
            return userId;
        }
        Work work = workService.getById(task.getWorkId());
        return work != null ? work.getPublisherId() : userId;
    }

    private boolean isRegTechAdmin(String userId) {
        try {
            User user = userService.getById(Long.valueOf(userId));
            if (user == null) {
                return false;
            }
            if ("监管科技管理员".equals(user.getRoleName())) {
                return true;
            }
            if (user.getRoleId() == null) {
                return false;
            }
            Role role = roleService.getById(user.getRoleId());
            return role != null && "监管科技管理员".equals(role.getName());
        } catch (NumberFormatException ignored) {
            return false;
        }
    }

    private String findMainTaskId(String workId) {
        WorkTask mainTask = workTaskService.lambdaQuery()
                .eq(WorkTask::getWorkId, workId)
                .eq(WorkTask::getTaskRole, TASK_ROLE_MAIN)
                .one();
        if (mainTask == null) {
            throw new IllegalStateException("需求缺少主任务，不能添加子任务");
        }
        return mainTask.getId();
    }
}
