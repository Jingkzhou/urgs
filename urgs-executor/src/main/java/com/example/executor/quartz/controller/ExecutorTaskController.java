package com.example.executor.quartz.controller;

import com.example.executor.quartz.domain.dto.ExecutorStopTaskDTO;
import com.example.executor.quartz.domain.dto.ExecutorStopTaskResultDTO;
import com.example.executor.quartz.domain.dto.ExecutorTriggerNowDTO;
import com.example.executor.quartz.domain.dto.ExecutorPoolStatsDTO;
import com.example.executor.quartz.domain.entity.QuartzTaskEntity;
import com.example.executor.quartz.service.ExecutorTaskService;
import com.example.executor.quartz.service.TaskExecutorPool;
import com.example.executor.support.domain.ResponseDTO;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/executor/task")
public class ExecutorTaskController {

    private final ExecutorTaskService executorTaskService;
    private final TaskExecutorPool taskExecutorPool;

    public ExecutorTaskController(ExecutorTaskService executorTaskService, TaskExecutorPool taskExecutorPool) {
        this.executorTaskService = executorTaskService;
        this.taskExecutorPool = taskExecutorPool;
    }

    @GetMapping("/pool/stats")
    public ResponseDTO<ExecutorPoolStatsDTO> getPoolStats() {
        return ResponseDTO.succData(taskExecutorPool.getPoolStats());
    }

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

    @PostMapping("/triggerNow")
    public ResponseDTO<String> triggerNow(@RequestBody ExecutorTriggerNowDTO triggerNowDTO) {
        if (triggerNowDTO.getPlanId() == null || triggerNowDTO.getDataDate() == null || triggerNowDTO.getDataDate().trim().isEmpty()) {
            return ResponseDTO.wrap(400, "planId 和 dataDate 不能为空");
        }
        QuartzTaskEntity task = executorTaskService.getByTaskId(triggerNowDTO.getPlanId());
        if (task == null) {
            return ResponseDTO.wrap(404, "任务不存在: planId=" + triggerNowDTO.getPlanId());
        }
        boolean rerun = "rerun".equals(triggerNowDTO.getTriggerType());
        if (!rerun && executorTaskService.isTaskRunning(triggerNowDTO.getPlanId(), triggerNowDTO.getDataDate())) {
            return ResponseDTO.wrap(409, "任务已在执行中: " + triggerNowDTO.getPlanId() + "_" + triggerNowDTO.getDataDate());
        }
        String validationError = executorTaskService.validateTaskReadyForSubmit(task);
        if (validationError != null) {
            return ResponseDTO.wrap(400, validationError);
        }
        boolean accepted = executorTaskService.submitTaskToPool(
                task,
                triggerNowDTO.getDataDate(),
                triggerNowDTO.getTriggerType()
        );
        if (!accepted) {
            return ResponseDTO.wrap(409, "任务已在执行中: " + triggerNowDTO.getPlanId() + "_" + triggerNowDTO.getDataDate());
        }
        return ResponseDTO.succ();
    }
}
