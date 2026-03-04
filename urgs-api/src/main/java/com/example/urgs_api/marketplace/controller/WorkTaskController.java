package com.example.urgs_api.marketplace.controller;

import com.example.urgs_api.common.PageRequest;
import com.example.urgs_api.common.PageResult;
import com.example.urgs_api.marketplace.dto.TaskMarketDTO;
import com.example.urgs_api.marketplace.model.WorkTask;
import com.example.urgs_api.marketplace.service.WorkTaskService;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/marketplace/tasks")
public class WorkTaskController {

    @Autowired
    private WorkTaskService workTaskService;

    @GetMapping
    public PageResult<TaskMarketDTO> getMarketTasks(@RequestParam(defaultValue = "1") int current,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String keyword) {
        Page<WorkTask> page = new Page<>(current, size);
        // FIXME: category is missing in RequestParam, passing null for now
        Page<TaskMarketDTO> resultPage = workTaskService.getMarketTasks(page, null, keyword);
        return PageResult.of(resultPage);
    }

    @GetMapping("/my")
    public PageResult<WorkTask> getMyTasks(@RequestHeader("X-User-Id") String userId,
            @RequestParam(defaultValue = "1") int current,
            @RequestParam(defaultValue = "10") int size) {
        Page<WorkTask> page = new Page<>(current, size);
        Page<WorkTask> resultPage = workTaskService.page(page,
                new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<WorkTask>()
                        .eq(WorkTask::getAssigneeId, userId)
                        .orderByDesc(WorkTask::getCreateTime));
        return PageResult.of(resultPage);
    }

    @PostMapping("/{id}/claim")
    public ResponseEntity<Void> claimTask(@RequestHeader("X-User-Id") String userId, @PathVariable String id) {
        workTaskService.claimTask(userId, id);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/assign")
    public ResponseEntity<Void> assignTask(@RequestHeader("X-User-Id") String userId, @PathVariable String id,
            @RequestBody Map<String, String> body) {
        workTaskService.assignTask(userId, id, body.get("assigneeId"));
        return ResponseEntity.ok().build();
    }
}
