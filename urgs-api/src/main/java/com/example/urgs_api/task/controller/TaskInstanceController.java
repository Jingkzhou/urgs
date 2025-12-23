package com.example.urgs_api.task.controller;

import com.example.urgs_api.task.entity.TaskInstance;
import com.example.urgs_api.task.service.TaskService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/task/instance")
public class TaskInstanceController {

    @Autowired
    private TaskService taskService;

    @GetMapping("/list")
    public List<TaskInstance> listInstances(
            @RequestParam(required = false) String taskId,
            @RequestParam(required = false) String dataDate,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String executionDate,
            @RequestParam(required = false) String keyword) {
        return taskService.listInstances(taskId, dataDate, status, executionDate, keyword);
    }

    @PostMapping("/rerun/{id}")
    public String rerunInstance(@PathVariable String id,
            @RequestParam(required = false, defaultValue = "false") boolean withDownstream) {
        taskService.rerunTask(id, withDownstream);
        return "Success";
    }

    @PostMapping("/rerun/batch")
    public String rerunBatch(@RequestBody List<String> ids,
            @RequestParam(required = false, defaultValue = "false") boolean withDownstream) {
        taskService.rerunBatch(ids, withDownstream);
        return "Success";
    }

    @GetMapping("/validate-rerun/{id}")
    public List<String> validateRerun(@PathVariable String id) {
        return taskService.validateRerun(id);
    }

    @PostMapping("/validate-rerun/batch")
    public Map<String, List<String>> validateRerunBatch(@RequestBody List<String> ids) {
        return taskService.validateRerunBatch(ids);
    }

    @PostMapping("/stop/{id}")
    public String stopInstance(@PathVariable String id) {
        taskService.stopTask(id);
        return "Success";
    }

    @PostMapping("/force-success/{id}")
    public String forceSuccess(@PathVariable String id) {
        taskService.forceSuccess(id);
        return "Success";
    }

    @GetMapping("/log/{id}")
    public java.util.Map<String, String> getTaskLog(@PathVariable String id) {
        return java.util.Collections.singletonMap("content", taskService.getTaskLog(id));
    }

    @GetMapping("/stats/daily")
    public com.example.urgs_api.task.vo.TaskInstanceStatsVO getDailyStats(@RequestParam(required = false) String date) {
        return taskService.getDailyStats(date);
    }

    @GetMapping("/stats/hourly")
    public List<java.util.Map<String, Object>> getHourlyThroughput(@RequestParam(required = false) String date) {
        return taskService.getHourlyThroughput(date);
    }

    @GetMapping("/stats/workflow")
    public List<com.example.urgs_api.task.vo.WorkflowStatsVO> getWorkflowStats(
            @RequestParam(required = false) String date) {
        return taskService.getWorkflowStats(date);
    }

    @PostMapping("/create")
    public org.springframework.http.ResponseEntity<?> createInstance(@RequestParam String taskId,
            @RequestParam String dataDate) {
        String result = taskService.createTaskInstance(taskId, dataDate);
        if ("EXIST".equals(result)) {
            return org.springframework.http.ResponseEntity.badRequest()
                    .body("该日期的任务实例已存在");
        }
        return org.springframework.http.ResponseEntity.ok(result);
    }
}
