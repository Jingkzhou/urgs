package com.example.urgs_api.marketplace.controller;

import com.example.urgs_api.common.PageResult;
import com.example.urgs_api.marketplace.dto.TaskMarketDTO;
import com.example.urgs_api.marketplace.dto.WorkTaskCreateDTO;
import com.example.urgs_api.marketplace.enums.TaskStatus;
import com.example.urgs_api.marketplace.model.WorkTask;
import com.example.urgs_api.marketplace.service.WorkService;
import com.example.urgs_api.marketplace.service.WorkTaskService;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/marketplace/tasks")
public class WorkTaskController {

    @Autowired
    private WorkTaskService workTaskService;

    @Autowired
    private WorkService workService;

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
        task.setTitle(dto.getTitle());
        task.setDescription(dto.getDescription());
        task.setRequiredSkills(dto.getRequiredSkills());
        task.setPoints(dto.getPoints() != null ? dto.getPoints() : 0);
        task.setAssignMode(dto.getAssignMode());
        task.setDeadline(dto.getDeadline());

        if (dto.getAssigneeId() != null && !dto.getAssigneeId().isEmpty()) {
            task.setAssigneeId(dto.getAssigneeId());
        }
        if (dto.getMaxApplicants() != null) {
            task.setMaxApplicants(dto.getMaxApplicants());
        }

        // Set initial status based on assign mode
        if ("ASSIGN".equals(dto.getAssignMode()) && dto.getAssigneeId() != null) {
            task.setStatus(TaskStatus.ASSIGNED.name());
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
        // FIXME: category is missing in RequestParam, passing null for now
        Page<TaskMarketDTO> resultPage = workTaskService.getMarketTasks(page, null, keyword, status);
        return PageResult.of(resultPage);
    }

    @GetMapping("/{id}")
    public ResponseEntity<TaskMarketDTO> getTaskById(@PathVariable String id) {
        TaskMarketDTO dto = workTaskService.getTaskDetail(id);
        return ResponseEntity.ok(dto);
    }

    @GetMapping("/my")
    public PageResult<WorkTask> getMyTasks(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @RequestParam(defaultValue = "1") int current,
            @RequestParam(defaultValue = "10") int size) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        Page<WorkTask> page = new Page<>(current, size);
        Page<WorkTask> resultPage = workTaskService.page(page,
                new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<WorkTask>()
                        .eq(WorkTask::getAssigneeId, userId)
                        .orderByDesc(WorkTask::getCreateTime));
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

    @PutMapping("/{id}/assign")
    public ResponseEntity<Void> assignTask(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String id,
            @RequestBody Map<String, String> body) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        workTaskService.assignTask(id, body.get("assigneeId"), userId);
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
}
