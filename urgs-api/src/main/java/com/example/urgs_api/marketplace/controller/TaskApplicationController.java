package com.example.urgs_api.marketplace.controller;

import com.example.urgs_api.common.PageResult;
import com.example.urgs_api.marketplace.model.TaskApplication;
import com.example.urgs_api.marketplace.service.TaskApplicationService;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/marketplace/applications")
public class TaskApplicationController {

    @Autowired
    private TaskApplicationService taskApplicationService;

    @PostMapping("/apply")
    public ResponseEntity<Void> applyForTask(
            @RequestHeader(value = "X-User-Id", required = false) String headerApplicantId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @RequestBody Map<String, String> body) {
        String applicantId = getEffectiveUserId(headerApplicantId, attrUserId);
        taskApplicationService.applyForTask(applicantId, body.get("taskId"), body.get("message"));
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/approve")
    public ResponseEntity<Void> approveApplication(
            @RequestHeader(value = "X-User-Id", required = false) String headerPublisherId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String id) {
        String publisherId = getEffectiveUserId(headerPublisherId, attrUserId);
        taskApplicationService.approveApplication(publisherId, id);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/reject")
    public ResponseEntity<Void> rejectApplication(
            @RequestHeader(value = "X-User-Id", required = false) String headerPublisherId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String id) {
        String publisherId = getEffectiveUserId(headerPublisherId, attrUserId);
        taskApplicationService.rejectApplication(publisherId, id);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/task/{taskId}")
    public PageResult<TaskApplication> getApplicationsByTask(
            @RequestHeader(value = "X-User-Id", required = false) String headerPublisherId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String taskId,
            @RequestParam(defaultValue = "1") int current,
            @RequestParam(defaultValue = "10") int size) {
        String publisherId = getEffectiveUserId(headerPublisherId, attrUserId);
        Page<TaskApplication> page = new Page<>(current, size);
        Page<TaskApplication> resultPage = taskApplicationService.page(page, new LambdaQueryWrapper<TaskApplication>()
                .eq(TaskApplication::getTaskId, taskId)
                .orderByDesc(TaskApplication::getCreateTime));
        return PageResult.of(resultPage);
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
