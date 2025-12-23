package com.example.executor.urgs_executor.job;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.executor.urgs_executor.entity.Task;
import com.example.executor.urgs_executor.entity.TaskDependency;
import com.example.executor.urgs_executor.entity.TaskInstance;
import com.example.executor.urgs_executor.mapper.TaskDependencyMapper;
import com.example.executor.urgs_executor.mapper.TaskInstanceMapper;
import com.example.executor.urgs_executor.mapper.TaskMapper;
import com.example.executor.urgs_executor.util.CronUtils;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.quartz.Job;
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Date;
import java.util.List;

@Slf4j
@Component
public class TaskGeneratorJob implements Job {

    @Autowired
    private TaskMapper taskMapper;

    @Autowired
    private TaskInstanceMapper taskInstanceMapper;

    @Autowired
    private TaskDependencyMapper taskDependencyMapper;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public void execute(JobExecutionContext context) throws JobExecutionException {
        log.info("TaskGeneratorJob started...");

        // 1. Fetch enabled tasks
        QueryWrapper<Task> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("status", 1);
        List<Task> tasks = taskMapper.selectList(queryWrapper);

        Date now = new Date();

        for (Task task : tasks) {
            try {
                processTask(task, now);
            } catch (Exception e) {
                log.error("Failed to process task: {}", task.getId(), e);
            }
        }

        log.info("TaskGeneratorJob finished.");
    }

    private void processTask(Task task, Date now) {
        String cron = null;
        try {
            if (task.getContent() != null) {
                JsonNode node = objectMapper.readTree(task.getContent());
                if (node.has("cronExpression")) {
                    cron = node.get("cronExpression").asText();
                }
            }
        } catch (Exception e) {
            log.warn("Failed to parse task content for cron: {}", task.getId(), e);
        }

        if (cron == null || cron.isEmpty()) {
            // Fallback to direct field if content parsing fails or is missing
            cron = task.getCronExpression();
        }

        if (cron == null || cron.isEmpty() || !CronUtils.isValid(cron)) {
            log.debug("Invalid cron for task: {}", task.getId());
            return;
        }

        Date lastTime;
        if (task.getLastTriggerTime() != null) {
            lastTime = Date.from(task.getLastTriggerTime().atZone(ZoneId.systemDefault()).toInstant());
        } else if (task.getCreateTime() != null) {
            lastTime = Date.from(task.getCreateTime().atZone(ZoneId.systemDefault()).toInstant());
        } else {
            // Fallback to a past time if both are null (e.g. 1970) to ensure immediate
            // trigger if due
            lastTime = new Date(0);
        }

        Date nextTime = CronUtils.getNextExecution(cron, lastTime);

        if (nextTime != null && nextTime.before(now)) {
            log.info("Task {} is due. Next: {}, Now: {}", task.getName(), nextTime, now);
            triggerTask(task, nextTime);
            task.setLastTriggerTime(LocalDateTime.ofInstant(nextTime.toInstant(), ZoneId.systemDefault()));
            taskMapper.updateById(task);
        }
    }

    private void triggerTask(Task task, Date triggerTime) {
        // 1. Parse content for offset
        int offset = 0;
        try {
            if (task.getContent() != null) {
                JsonNode node = objectMapper.readTree(task.getContent());
                if (node.has("offset")) {
                    offset = node.get("offset").asInt(0);
                }
            }
        } catch (Exception e) {
            log.warn("Failed to parse task content for offset, using default 0. Task: {}", task.getId());
        }

        // 2. Calculate Data Date
        LocalDate triggerDate = LocalDateTime.ofInstant(triggerTime.toInstant(), ZoneId.systemDefault()).toLocalDate();
        LocalDate dataDateVal = triggerDate.plusDays(offset);
        String dataDateStr = dataDateVal.format(DateTimeFormatter.ofPattern("yyyy-MM-dd"));

        // 3. Check Dependencies and Determine Status
        QueryWrapper<TaskDependency> depWrapper = new QueryWrapper<>();
        depWrapper.eq("task_id", task.getId());
        List<TaskDependency> dependencies = taskDependencyMapper.selectList(depWrapper);

        String initialStatus = TaskInstance.STATUS_WAITING;

        if (dependencies != null && !dependencies.isEmpty()) {
            boolean allDependenciesMet = true;
            for (TaskDependency dep : dependencies) {
                QueryWrapper<TaskInstance> preInstanceWrapper = new QueryWrapper<>();
                preInstanceWrapper.eq("task_id", dep.getPreTaskId());
                preInstanceWrapper.eq("data_date", dataDateStr);
                TaskInstance preInstance = taskInstanceMapper.selectOne(preInstanceWrapper);

                if (preInstance == null ||
                        (!TaskInstance.STATUS_SUCCESS.equals(preInstance.getStatus()) &&
                                !TaskInstance.STATUS_FORCE_SUCCESS.equals(preInstance.getStatus()))) {
                    allDependenciesMet = false;
                    break;
                }
            }

            if (!allDependenciesMet) {
                initialStatus = TaskInstance.STATUS_PENDING;
            }
        }

        // 4. Idempotency Check - Update if exists, Insert if not
        QueryWrapper<TaskInstance> checkWrapper = new QueryWrapper<>();
        checkWrapper.eq("task_id", task.getId());
        checkWrapper.eq("data_date", dataDateStr);
        TaskInstance existingInstance = taskInstanceMapper.selectOne(checkWrapper);

        if (existingInstance != null) {
            log.info("TaskInstance already exists for task {} date {}. Updating existing instance.", task.getName(),
                    dataDateStr);
            existingInstance.setStatus(initialStatus);
            existingInstance.setRetryCount(0);
            existingInstance.setContentSnapshot(task.getContent());
            existingInstance.setUpdateTime(LocalDateTime.now());
            existingInstance.setCreateTime(LocalDateTime.now()); // Update create_time as per "update every time cron is
                                                                 // met"
            existingInstance.setStartTime(null); // Reset start time
            existingInstance.setEndTime(null); // Reset end time
            taskInstanceMapper.updateById(existingInstance);
        } else {
            TaskInstance instance = new TaskInstance();
            instance.setTaskId(task.getId());
            instance.setTaskType(task.getType());
            instance.setDataDate(dataDateStr);
            instance.setStatus(initialStatus);
            instance.setRetryCount(0);
            instance.setContentSnapshot(task.getContent());
            instance.setCreateTime(LocalDateTime.now());
            instance.setUpdateTime(LocalDateTime.now());
            instance.setStartTime(null); // Reset start time
            instance.setEndTime(null); // Reset end time

            taskInstanceMapper.insert(instance);
            log.info("Generated TaskInstance: {} for date {} (Status: {})",
                    task.getName(), dataDateStr, instance.getStatus());
        }
    }
}
