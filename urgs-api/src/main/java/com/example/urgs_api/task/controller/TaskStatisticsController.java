package com.example.urgs_api.task.controller;

import com.example.urgs_api.task.dto.TaskStatsQuery;
import com.example.urgs_api.task.dto.TaskStatsVO;
import com.example.urgs_api.task.entity.TaskRealtimeMonitor;
import com.example.urgs_api.task.service.TaskStatisticsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/tasks/stats")
public class TaskStatisticsController {
    @Autowired
    private TaskStatisticsService taskStatisticsService;

    @PostMapping("/batch")
    public List<TaskStatsVO> getBatchStatusStats(@RequestBody TaskStatsQuery query) {
        return taskStatisticsService.getBatchStatusStats(query);
    }

    @GetMapping("/realtime-details")
    public List<TaskRealtimeMonitor> getRealtimeDetails(@RequestParam(required = false) String systemId) {
        return taskStatisticsService.getRealtimeDetails(systemId);
    }
}
