package com.example.executor.urgs_executor.job;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.executor.urgs_executor.entity.Task;
import com.example.executor.urgs_executor.entity.TaskDependency;
import com.example.executor.urgs_executor.entity.ExecutorTaskInstance;
import com.example.executor.urgs_executor.mapper.TaskDependencyMapper;
import com.example.executor.urgs_executor.mapper.ExecutorTaskInstanceMapper;
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

/**
 * 任务生成作业（Quartz Job）
 * 负责扫描所有启用的任务定义，并根据其 Cron 表达式判断是否需要生成新的任务实例。
 */
@Slf4j
@Component
public class TaskGeneratorJob implements Job {

    @Autowired
    private TaskMapper taskMapper;

    @Autowired
    private ExecutorTaskInstanceMapper taskInstanceMapper;

    @Autowired
    private TaskDependencyMapper taskDependencyMapper;

    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Quartz Job 执行入口
     */
    @Override
    public void execute(JobExecutionContext context) throws JobExecutionException {
        log.info("TaskGeneratorJob started...");

        // 1. 获取所有状态为启用的任务定义
        QueryWrapper<Task> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("status", 1);
        List<Task> tasks = taskMapper.selectList(queryWrapper);

        Date now = new Date();

        // 2. 逐一处理每个任务
        for (Task task : tasks) {
            try {
                processTask(task, now);
            } catch (Exception e) {
                log.error("Failed to process task: {}", task.getId(), e);
            }
        }

        log.info("TaskGeneratorJob finished.");
    }

    /**
     * 处理单个任务定义的逻辑，判断其是否到达触发时间
     */
    private void processTask(Task task, Date now) {
        log.info("Processing Task: ID={}, Name={}, ContentLen={}", task.getId(), task.getName(),
                task.getContent() == null ? "NULL" : task.getContent().length());

        // 解析 Cron 表达式（优先从 content 字段解析，兼容前端配置）
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
            // 如果 content 中没有，则取任务定义的直接字段
            cron = task.getCronExpression();
        }

        // 校验 Cron 表达式合法性
        if (cron == null || cron.isEmpty() || !CronUtils.isValid(cron)) {
            log.debug("Invalid cron for task: {}", task.getId());
            return;
        }

        // 确定基准参考时间（由于是轮询机制，需要根据上次触发时间来找下一个触发点）
        Date lastTime;
        if (task.getLastTriggerTime() != null) {
            lastTime = Date.from(task.getLastTriggerTime().atZone(ZoneId.systemDefault()).toInstant());
        } else if (task.getCreateTime() != null) {
            lastTime = Date.from(task.getCreateTime().atZone(ZoneId.systemDefault()).toInstant());
        } else {
            lastTime = new Date(0); // 兜底使用 1970 年
        }

        // 计算下一次执行时间
        Date nextTime = CronUtils.getNextExecution(cron, lastTime);

        // 如果下一次执行时间早于当前时间，说明该任务已经“过期”需要触发
        if (nextTime != null && nextTime.before(now)) {
            log.info("Task {} is due. Next: {}, Now: {}", task.getName(), nextTime, now);
            triggerTask(task, nextTime);
            // 更新该任务定义的“最后触发时间”，防止重复触发
            task.setLastTriggerTime(LocalDateTime.ofInstant(nextTime.toInstant(), ZoneId.systemDefault()));
            taskMapper.updateById(task);
        }
    }

    /**
     * 实际执行任务触发逻辑：创建或更新任务实例
     */
    private void triggerTask(Task task, Date triggerTime) {
        // 1. 解析任务内容中的偏移量（用于计算业务日期 DataDate）
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

        // 2. 计算 Data Date（业务日期 = 触发日期 + 偏移量）
        LocalDate triggerDate = LocalDateTime.ofInstant(triggerTime.toInstant(), ZoneId.systemDefault()).toLocalDate();
        LocalDate dataDateVal = triggerDate.plusDays(offset);
        String dataDateStr = dataDateVal.format(DateTimeFormatter.ofPattern("yyyy-MM-dd"));

        // 3. 检查上游依赖情况，决定初始状态
        QueryWrapper<TaskDependency> depWrapper = new QueryWrapper<>();
        depWrapper.eq("task_id", task.getId());
        List<TaskDependency> dependencies = taskDependencyMapper.selectList(depWrapper);

        String initialStatus = ExecutorTaskInstance.STATUS_WAITING;

        if (dependencies != null && !dependencies.isEmpty()) {
            boolean allDependenciesMet = true;
            for (TaskDependency dep : dependencies) {
                // 查找同业务日期的上游任务实例状态
                QueryWrapper<ExecutorTaskInstance> preInstanceWrapper = new QueryWrapper<>();
                preInstanceWrapper.eq("task_id", dep.getPreTaskId());
                preInstanceWrapper.eq("data_date", dataDateStr);
                ExecutorTaskInstance preInstance = taskInstanceMapper.selectOne(preInstanceWrapper);

                // 如果上游实例不存在，或者尚未成功，则当前任务需处于 PENDING 状态等待
                if (preInstance == null ||
                        (!ExecutorTaskInstance.STATUS_SUCCESS.equals(preInstance.getStatus()) &&
                                !ExecutorTaskInstance.STATUS_FORCE_SUCCESS.equals(preInstance.getStatus()))) {
                    allDependenciesMet = false;
                    break;
                }
            }

            if (!allDependenciesMet) {
                initialStatus = ExecutorTaskInstance.STATUS_PENDING;
            }
        }

        // 4. 幂等性检查：如果该任务在同一业务日期已存在实例，则进行更新；否则插入新实例。
        QueryWrapper<ExecutorTaskInstance> checkWrapper = new QueryWrapper<>();
        checkWrapper.eq("task_id", task.getId());
        checkWrapper.eq("data_date", dataDateStr);
        ExecutorTaskInstance existingInstance = taskInstanceMapper.selectOne(checkWrapper);

        if (existingInstance != null) {
            log.info("TaskInstance already exists for task {} date {}. Updating existing instance.", task.getName(),
                    dataDateStr);
            existingInstance.setStatus(initialStatus);
            existingInstance.setRetryCount(0);
            existingInstance.setContentSnapshot(task.getContent()); // 更新最新的脚本快照
            existingInstance.setUpdateTime(LocalDateTime.now());
            existingInstance.setCreateTime(LocalDateTime.now());
            existingInstance.setStartTime(null); // 重置执行时间
            existingInstance.setEndTime(null);
            taskInstanceMapper.updateById(existingInstance);
        } else {
            // 插入新实例
            ExecutorTaskInstance instance = new ExecutorTaskInstance();
            instance.setTaskId(task.getId());
            instance.setTaskType(task.getType());
            if (task.getSystemId() != null) {
                try {
                    instance.setSystemId(Long.parseLong(task.getSystemId()));
                } catch (NumberFormatException e) {
                    // ignore
                }
            }
            instance.setDataDate(dataDateStr);
            instance.setStatus(initialStatus);
            instance.setRetryCount(0);
            instance.setContentSnapshot(task.getContent()); // 保存任务定义的当前快照，确保执行时的一致性
            instance.setCreateTime(LocalDateTime.now());
            instance.setUpdateTime(LocalDateTime.now());
            instance.setStartTime(null);
            instance.setEndTime(null);

            log.info("DEBUG: ContentSnapshot before insert: {}", instance.getContentSnapshot());

            taskInstanceMapper.insert(instance);
            log.info("Generated TaskInstance: {} for date {} (Status: {})",
                    task.getName(), dataDateStr, instance.getStatus());
        }
    }
}
