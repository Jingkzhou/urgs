package com.example.executor.quartz.controller;

import com.example.executor.quartz.domain.dto.ExecutorStopTaskDTO;
import com.example.executor.quartz.domain.dto.ExecutorStopTaskResultDTO;
import com.example.executor.quartz.service.ExecutorTaskService;
import com.example.executor.support.domain.ResponseDTO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/executor/task")
public class ExecutorTaskController {

    @Autowired
    private ExecutorTaskService executorTaskService;

    @PostMapping("/stop")
    public ResponseDTO<ExecutorStopTaskResultDTO> stopTask(@RequestBody ExecutorStopTaskDTO stopTaskDTO) {
        if (stopTaskDTO.getPlanId() == null || stopTaskDTO.getDataDate() == null || stopTaskDTO.getDataDate().trim().isEmpty()) {
            return ResponseDTO.wrap(400, "planId 和 dataDate 不能为空");
        }

        boolean foundRunningTask = executorTaskService.isTaskRunning(stopTaskDTO.getPlanId(), stopTaskDTO.getDataDate());
        boolean cancelled = foundRunningTask && executorTaskService.stopTask(stopTaskDTO.getPlanId(), stopTaskDTO.getDataDate());
        if (foundRunningTask && !cancelled) {
            return ResponseDTO.wrap(500, "任务正在运行，但取消失败");
        }
        return ResponseDTO.succData(new ExecutorStopTaskResultDTO(
                foundRunningTask,
                cancelled,
                stopTaskDTO.getPlanId() + "_" + stopTaskDTO.getDataDate()
        ));
    }
}
