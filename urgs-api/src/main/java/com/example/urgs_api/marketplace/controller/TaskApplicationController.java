package com.example.urgs_api.marketplace.controller;

import com.example.urgs_api.common.PageRequest;
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
    public ResponseEntity<Void> applyForTask(@RequestHeader("X-User-Id") String applicantId,
            @RequestBody Map<String, String> body) {
        taskApplicationService.applyForTask(applicantId, body.get("taskId"), body.get("message"));
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/approve")
    public ResponseEntity<Void> approveApplication(@RequestHeader("X-User-Id") String publisherId,
            @PathVariable String id) {
        taskApplicationService.approveApplication(publisherId, id);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/reject")
    public ResponseEntity<Void> rejectApplication(@RequestHeader("X-User-Id") String publisherId,
            @PathVariable String id) {
        taskApplicationService.rejectApplication(publisherId, id);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/task/{taskId}")
    public PageResult<TaskApplication> getApplicationsByTask(@RequestHeader("X-User-Id") String publisherId,
            @PathVariable String taskId,
            @RequestParam(defaultValue = "1") int current,
            @RequestParam(defaultValue = "10") int size) {
        Page<TaskApplication> page = new Page<>(current, size);
        Page<TaskApplication> resultPage = taskApplicationService.page(page, new LambdaQueryWrapper<TaskApplication>()
                .eq(TaskApplication::getTaskId, taskId)
                .orderByDesc(TaskApplication::getCreateTime));
        return PageResult.of(resultPage);
    }
}
