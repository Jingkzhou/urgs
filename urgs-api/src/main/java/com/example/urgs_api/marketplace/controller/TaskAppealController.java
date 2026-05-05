package com.example.urgs_api.marketplace.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.common.PageResult;
import com.example.urgs_api.marketplace.dto.TaskAppealDTO;
import com.example.urgs_api.marketplace.model.TaskAppeal;
import com.example.urgs_api.marketplace.service.TaskAppealService;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/marketplace/appeals")
public class TaskAppealController {

    @Autowired
    private TaskAppealService taskAppealService;

    @PostMapping("/task/{taskId}")
    public TaskAppeal createAppeal(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String taskId,
            @RequestBody TaskAppealDTO dto) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        return taskAppealService.createAppeal(taskId, userId, dto);
    }

    @PutMapping("/{id}/resolve")
    public ResponseEntity<Void> resolveAppeal(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String id,
            @RequestBody TaskAppealDTO dto) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        taskAppealService.resolveAppeal(id, userId, dto);
        return ResponseEntity.ok().build();
    }

    @GetMapping
    public PageResult<TaskAppeal> listAppeals(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "1") int current,
            @RequestParam(defaultValue = "10") int size) {
        LambdaQueryWrapper<TaskAppeal> wrapper = new LambdaQueryWrapper<TaskAppeal>()
                .orderByDesc(TaskAppeal::getCreateTime);
        if (status != null && !status.isEmpty()) {
            wrapper.eq(TaskAppeal::getStatus, status);
        }
        return PageResult.of(taskAppealService.page(new Page<>(current, size), wrapper));
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
