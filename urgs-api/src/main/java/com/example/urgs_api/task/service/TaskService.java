package com.example.urgs_api.task.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.example.urgs_api.quartz.dao.QuartzTaskDao;
import com.example.urgs_api.quartz.dao.QuartzTaskStatusDao;
import com.example.urgs_api.quartz.domain.entity.QuartzTaskEntity;
import com.example.urgs_api.quartz.domain.entity.QuartzTaskStatusEntity;
import com.example.urgs_api.task.entity.Task;
import com.example.urgs_api.task.entity.TaskDependency;
import com.example.urgs_api.task.entity.TaskInstance;
import com.example.urgs_api.task.mapper.TaskDependencyMapper;
import com.example.urgs_api.task.mapper.TaskInstanceMapper;
import com.example.urgs_api.task.mapper.TaskMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Collections;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import com.example.urgs_api.task.vo.UpstreamDependencyVO;
import com.example.urgs_api.task.vo.WorkflowStatsVO;
import com.example.urgs_api.task.vo.TaskDefinitionStatsVO;
import com.example.urgs_api.workflow.entity.Workflow;
import com.example.urgs_api.workflow.repository.WorkflowMapper;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
public class TaskService {

    @Autowired
    private TaskMapper taskMapper;

    @Autowired
    private TaskDependencyMapper taskDependencyMapper;

    @Autowired
    private TaskInstanceMapper taskInstanceMapper;

    @Autowired
    private WorkflowMapper workflowMapper;

    @Autowired
    private QuartzTaskStatusDao quartzTaskStatusDao;

    @Autowired
    private QuartzTaskDao quartzTaskDao;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Transactional(rollbackFor = Exception.class)
    public String saveTask(String id, String name, String type, String content,
            String cronExpression, Integer status, Integer priority, List<String> preTaskIds, Long systemId) {
        Task task = null;
        if (id != null) {
            task = taskMapper.selectById(id);
        }

        if (task == null) {
            task = new Task();
            if (id != null) {
                task.setId(id);
            }
            task.setCreateTime(LocalDateTime.now());
        }

        task.setName(name);
        task.setType(type);
        task.setContent(content);
        task.setCronExpression(cronExpression);
        if (status != null) {
            task.setStatus(status);
        } else if (task.getStatus() == null) {
            task.setStatus(1); // Default to enabled for new tasks
        }
        task.setPriority(priority != null ? priority : 0);
        task.setSystemId(systemId);
        task.setUpdateTime(LocalDateTime.now());

        if (taskMapper.selectById(task.getId()) == null) {
            taskMapper.insert(task);
        } else {
            taskMapper.updateById(task);
        }

        // Manage Dependencies
        // 1. Delete existing
        QueryWrapper<TaskDependency> delWrapper = new QueryWrapper<>();
        delWrapper.eq("task_id", task.getId());
        taskDependencyMapper.delete(delWrapper);

        // 2. Cycle detection + Insert new
        if (preTaskIds != null && !preTaskIds.isEmpty()) {
            if (hasCircularDependency(task.getId(), preTaskIds)) {
                throw new IllegalArgumentException("检测到循环依赖，无法保存");
            }
            for (String preId : preTaskIds) {
                TaskDependency dep = new TaskDependency();
                dep.setTaskId(task.getId());
                dep.setPreTaskId(preId);
                taskDependencyMapper.insert(dep);
            }
        }

        return task.getId();
    }

    public void deleteTask(String id) {
        taskMapper.deleteById(id);
    }

    @Transactional(rollbackFor = Exception.class)
    public void batchUpdateStatus(List<String> ids, Integer status) {
        if (ids == null || ids.isEmpty()) {
            return;
        }
        UpdateWrapper<Task> updateWrapper = new UpdateWrapper<>();
        updateWrapper.in("id", ids);
        updateWrapper.set("status", status);
        updateWrapper.set("update_time", LocalDateTime.now());
        taskMapper.update(null, updateWrapper);
    }

    public com.baomidou.mybatisplus.core.metadata.IPage<Task> listTasks(String keyword, String workflowIds,
            Integer status,
            Integer page, Integer size) {
        com.baomidou.mybatisplus.extension.plugins.pagination.Page<Task> pageObj = new com.baomidou.mybatisplus.extension.plugins.pagination.Page<>(
                page, size);
        QueryWrapper<Task> query = new QueryWrapper<>();
        if (StringUtils.hasText(keyword)) {
            query.like("name", keyword);
        }
        if (status != null) {
            query.eq("status", status);
        }

        if (StringUtils.hasText(workflowIds)) {
            List<String> taskIds = new ArrayList<>();
            String[] wIds = workflowIds.split(",");
            List<Long> workflowIdList = new ArrayList<>();
            for (String wId : wIds) {
                try {
                    workflowIdList.add(Long.parseLong(wId.trim()));
                } catch (NumberFormatException e) {
                    // ignore invalid ids
                }
            }

            if (!workflowIdList.isEmpty()) {
                List<Workflow> workflows = workflowMapper.selectBatchIds(workflowIdList);
                for (Workflow workflow : workflows) {
                    try {
                        if (workflow.getContent() != null) {
                            JsonNode root = objectMapper.readTree(workflow.getContent());
                            if (root.has("nodes")) {
                                for (JsonNode node : root.get("nodes")) {
                                    if (node.has("id")) {
                                        taskIds.add(node.get("id").asText());
                                    }
                                }
                            }
                        }
                    } catch (Exception e) {
                        log.error("Failed to parse workflow content for workflow id: " + workflow.getId(), e);
                    }
                }
            }

            if (taskIds.isEmpty()) {
                // If workflows were selected but no tasks found, return empty result
                // We use a condition that is always false
                query.eq("id", "___NO_MATCHING_TASKS___");
            } else {
                query.in("id", taskIds);
            }
        }

        query.orderByDesc("update_time");
        return taskMapper.selectPage(pageObj, query);
    }

    public List<TaskInstance> listInstances(String taskId, String dataDate, String status, String executionDate,
            String keyword) {
        QueryWrapper<TaskInstance> query = new QueryWrapper<>();
        query.ne("task_type", "DEPENDENT"); // DEPENDENT 任务无实例，防御过滤
        if (StringUtils.hasText(taskId)) {
            query.eq("task_id", taskId);
        }
        if (StringUtils.hasText(dataDate)) {
            query.eq("data_date", dataDate);
        }
        if (StringUtils.hasText(status)) {
            query.eq("status", status);
        }
        if (StringUtils.hasText(executionDate)) {
            query.like("create_time", executionDate);
        }
        if (StringUtils.hasText(keyword)) {
            List<String> matchingTaskIds = taskMapper.selectList(new QueryWrapper<Task>().like("name", keyword))
                    .stream().map(Task::getId).collect(java.util.stream.Collectors.toList());

            query.and(w -> {
                w.like("task_id", keyword);
                if (!matchingTaskIds.isEmpty()) {
                    w.or().in("task_id", matchingTaskIds);
                }
            });
        }
        query.orderByDesc("start_time", "create_time");
        return taskInstanceMapper.selectList(query);
    }

    public List<String> validateRerun(String instanceId) {
        TaskInstance instance = taskInstanceMapper.selectById(instanceId);
        if (instance == null)
            return Collections.emptyList();

        List<String> invalidTasks = new ArrayList<>();
        // Check downstream recursively
        checkDownstreamStatus(instance.getTaskId(), instance.getDataDate(), invalidTasks);
        return invalidTasks;
    }

    public Map<String, List<String>> validateRerunBatch(List<String> instanceIds) {
        Map<String, List<String>> result = new HashMap<>();
        for (String id : instanceIds) {
            List<String> invalidTasks = validateRerun(id);
            if (!invalidTasks.isEmpty()) {
                result.put(id, invalidTasks);
            }
        }
        return result;
    }

    private void checkDownstreamStatus(String taskId, String dataDate, List<String> invalidTasks) {
        QueryWrapper<TaskDependency> depQuery = new QueryWrapper<>();
        depQuery.eq("pre_task_id", taskId);
        List<TaskDependency> downstreamDeps = taskDependencyMapper.selectList(depQuery);

        for (TaskDependency dep : downstreamDeps) {
            String downstreamTaskId = dep.getTaskId();

            // DEPENDENT 无实例，穿透递归
            Task downstreamDef = taskMapper.selectById(downstreamTaskId);
            if (downstreamDef != null && "DEPENDENT".equals(downstreamDef.getType())) {
                checkDownstreamStatus(downstreamTaskId, dataDate, invalidTasks);
                continue;
            }

            // Check instance status
            QueryWrapper<TaskInstance> instanceQuery = new QueryWrapper<>();
            instanceQuery.eq("task_id", downstreamTaskId);
            instanceQuery.eq("data_date", dataDate);
            TaskInstance dsInstance = taskInstanceMapper.selectOne(instanceQuery);

            if (dsInstance != null) {
                String status = dsInstance.getStatus();
                if (!"SUCCESS".equals(status) && !"FAILURE".equals(status) && !"FORCE_SUCCESS".equals(status)) {
                    // Invalid status (RUNNING, WAITING, PENDING)
                    invalidTasks.add(downstreamDef != null ? downstreamDef.getName() : downstreamTaskId);
                }
            }

            // Recurse
            checkDownstreamStatus(downstreamTaskId, dataDate, invalidTasks);
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public void rerunTask(String instanceId, boolean withDownstream) {
        TaskInstance instance = taskInstanceMapper.selectById(instanceId);
        if (instance == null)
            return;

        resetInstance(instance);

        if (withDownstream) {
            rerunDownstream(instance.getTaskId(), instance.getDataDate());
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public void rerunBatch(List<String> instanceIds, boolean withDownstream) {
        for (String id : instanceIds) {
            rerunTask(id, withDownstream);
        }
    }

    private void rerunDownstream(String taskId, String dataDate) {
        QueryWrapper<TaskDependency> depQuery = new QueryWrapper<>();
        depQuery.eq("pre_task_id", taskId);
        List<TaskDependency> downstreamDeps = taskDependencyMapper.selectList(depQuery);

        for (TaskDependency dep : downstreamDeps) {
            String downstreamTaskId = dep.getTaskId();

            // DEPENDENT 无实例，跳过重置但继续递归下游
            Task downstreamDef = taskMapper.selectById(downstreamTaskId);
            if (downstreamDef != null && "DEPENDENT".equals(downstreamDef.getType())) {
                rerunDownstream(downstreamTaskId, dataDate);
                continue;
            }

            QueryWrapper<TaskInstance> instanceQuery = new QueryWrapper<>();
            instanceQuery.eq("task_id", downstreamTaskId);
            instanceQuery.eq("data_date", dataDate);
            TaskInstance dsInstance = taskInstanceMapper.selectOne(instanceQuery);

            if (dsInstance != null) {
                resetInstance(dsInstance);
            }

            // Recurse
            rerunDownstream(downstreamTaskId, dataDate);
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public void stopTask(String instanceId) {
        TaskInstance instance = taskInstanceMapper.selectById(instanceId);
        if (instance == null)
            return;

        // Only allow stopping if currently running, waiting, or pending
        String status = instance.getStatus();
        if ("RUNNING".equals(status) || "WAITING".equals(status) || "PENDING".equals(status)) {
            instance.setStatus("STOPPED");
            instance.setEndTime(LocalDateTime.now());
            instance.setUpdateTime(LocalDateTime.now());
            taskInstanceMapper.updateById(instance);
        }
    }

    private void resetInstance(TaskInstance instance) {
        LocalDateTime now = LocalDateTime.now();
        Task task = requireTaskForRerun(instance);

        // DEPENDENT 任务无实例，不应调用此方法
        if ("DEPENDENT".equals(task.getType())) {
            log.warn("尝试重置 DEPENDENT 任务实例: {}，已跳过", instance.getId());
            return;
        }

        UpdateWrapper<TaskInstance> updateWrapper = new UpdateWrapper<>();
        updateWrapper.eq("id", instance.getId());
        updateWrapper.set("task_type", task.getType());
        updateWrapper.set("system_id", task.getSystemId());
        updateWrapper.set("content_snapshot", task.getContent());
        updateWrapper.set("priority", task.getPriority());
        updateWrapper.set("status", "PENDING");
        updateWrapper.set("retry_count", 0);
        updateWrapper.set("start_time", null);
        updateWrapper.set("end_time", null);
        updateWrapper.set("log_content", null);
        updateWrapper.set("create_time", now);
        updateWrapper.set("update_time", now);
        taskInstanceMapper.update(null, updateWrapper);

        // 检查依赖是否满足，满足则提升为 WAITING
        if (areAllDependenciesMet(instance.getTaskId(), instance.getDataDate())) {
            UpdateWrapper<TaskInstance> statusUpdate = new UpdateWrapper<>();
            statusUpdate.eq("id", instance.getId());
            statusUpdate.set("status", "WAITING");
            taskInstanceMapper.update(null, statusUpdate);
        }
    }

    private Task requireTaskForRerun(TaskInstance instance) {
        Task task = taskMapper.selectById(instance.getTaskId());
        if (task == null) {
            throw new RuntimeException(
                    "任务实例 " + instance.getId() + " 对应的任务 " + instance.getTaskId() + " 已不存在，无法重跑");
        }
        return task;
    }

    @Transactional(rollbackFor = Exception.class)
    public void forceSuccess(String instanceId) {
        TaskInstance instance = taskInstanceMapper.selectById(instanceId);
        if (instance == null)
            return;

        instance.setStatus("FORCE_SUCCESS");
        instance.setEndTime(LocalDateTime.now());
        instance.setUpdateTime(LocalDateTime.now());
        String existingLog = instance.getLogContent() != null ? instance.getLogContent() : "";
        instance.setLogContent(
                existingLog + "\n[System] Manually marked as success at " + LocalDateTime.now());
        taskInstanceMapper.updateById(instance);

        // Trigger downstream tasks
        checkAndPromoteDownstream(instance);
    }

    /**
     * 穿透模式：遍历 sys_task_dependency 找下游任务。
     * 遇到 DEPENDENT 节点时递归穿透到其下游真实任务。
     */
    private void checkAndPromoteDownstream(TaskInstance completedInstance) {
        promoteEligibleDownstream(completedInstance.getTaskId(), completedInstance.getDataDate(),
                new java.util.HashSet<>());
    }

    private void promoteEligibleDownstream(String completedTaskId, String dataDate,
            java.util.Set<String> visited) {
        if (!visited.add(completedTaskId)) return; // 防循环

        QueryWrapper<TaskDependency> depWrapper = new QueryWrapper<>();
        depWrapper.eq("pre_task_id", completedTaskId);
        List<TaskDependency> downstreamDeps = taskDependencyMapper.selectList(depWrapper);

        for (TaskDependency dep : downstreamDeps) {
            String downstreamTaskId = dep.getTaskId();

            // DEPENDENT 下游：穿透
            Task downstreamDef = taskMapper.selectById(downstreamTaskId);
            if (downstreamDef != null && "DEPENDENT".equals(downstreamDef.getType())) {
                promoteEligibleDownstream(downstreamTaskId, dataDate, visited);
                continue;
            }

            // 普通任务：PENDING → WAITING
            QueryWrapper<TaskInstance> instanceWrapper = new QueryWrapper<>();
            instanceWrapper.eq("task_id", downstreamTaskId);
            instanceWrapper.eq("data_date", dataDate);
            TaskInstance downstreamInstance = taskInstanceMapper.selectOne(instanceWrapper);

            if (downstreamInstance == null) continue;

            if ("PENDING".equals(downstreamInstance.getStatus())) {
                if (areAllDependenciesMet(downstreamTaskId, dataDate)) {
                    downstreamInstance.setStatus("WAITING");
                    downstreamInstance.setUpdateTime(LocalDateTime.now());
                    taskInstanceMapper.updateById(downstreamInstance);
                    log.info("下游任务 {} 依赖已满足，状态提升为 WAITING", downstreamInstance.getId());
                }
            }
        }
    }

    private boolean areAllDependenciesMet(String taskId, String dataDate) {
        QueryWrapper<TaskDependency> upstreamWrapper = new QueryWrapper<>();
        upstreamWrapper.eq("task_id", taskId);
        List<TaskDependency> upstreamDeps = taskDependencyMapper.selectList(upstreamWrapper);

        for (TaskDependency dep : upstreamDeps) {
            if (!isUpstreamDependencyMet(dep.getPreTaskId(), dataDate)) {
                return false;
            }
        }
        return true;
    }

    /**
     * 检查单个上游依赖是否满足。
     * DEPENDENT 任务无实例，直接穿透到母体任务递归检查。
     */
    private boolean isUpstreamDependencyMet(String preTaskId, String dataDate) {
        // DEPENDENT 任务：穿透到母体
        Task taskDef = taskMapper.selectById(preTaskId);
        if (taskDef != null && "DEPENDENT".equals(taskDef.getType())) {
            String motherTaskId = resolveMotherTaskId(taskDef);
            if (motherTaskId != null) {
                return isUpstreamDependencyMet(motherTaskId, dataDate);
            }
            return false;
        }

        // 普通任务：查实例状态
        QueryWrapper<TaskInstance> preInstanceWrapper = new QueryWrapper<>();
        preInstanceWrapper.eq("task_id", preTaskId);
        preInstanceWrapper.eq("data_date", dataDate);
        TaskInstance preInstance = taskInstanceMapper.selectOne(preInstanceWrapper);

        if (preInstance != null) {
            return "SUCCESS".equals(preInstance.getStatus())
                    || "FORCE_SUCCESS".equals(preInstance.getStatus());
        }
        return false;
    }

    /**
     * 从 DEPENDENT 任务定义的 content JSON 中解析母体任务 ID。
     */
    private String resolveMotherTaskId(Task dependentTaskDef) {
        if (dependentTaskDef == null || dependentTaskDef.getContent() == null) return null;
        try {
            JsonNode contentNode = objectMapper.readTree(dependentTaskDef.getContent());
            JsonNode taskIdNode = contentNode.get("taskId");
            if (taskIdNode != null && !taskIdNode.isNull() && !taskIdNode.asText().isEmpty()) {
                return taskIdNode.asText();
            }
        } catch (Exception e) {
            log.warn("解析 DEPENDENT 任务 {} 的 content JSON 失败: {}", dependentTaskDef.getId(), e.getMessage());
        }
        return null;
    }

    public String getTaskLog(String id) {
        TaskInstance instance = taskInstanceMapper.selectById(id);
        if (instance == null) {
            return "Log not found";
        }
        if (instance.getLogContent() != null && !instance.getLogContent().isEmpty()) {
            log.info("Retrieved log for task {}. Content length: {}", id, instance.getLogContent().length());
            return instance.getLogContent();
        }
        // 无执行日志时，返回实例状态摘要
        StringBuilder sb = new StringBuilder();
        sb.append("[System] Task Instance ID: ").append(instance.getId()).append("\n");
        sb.append("[System] Task ID: ").append(instance.getTaskId()).append("\n");
        sb.append("[System] Status: ").append(instance.getStatus()).append("\n");
        if (instance.getCreateTime() != null) {
            sb.append("[System] Created at: ").append(instance.getCreateTime()).append("\n");
        }
        if (instance.getStartTime() != null) {
            sb.append("[System] Started at: ").append(instance.getStartTime()).append("\n");
        } else {
            sb.append("[System] Waiting to be dispatched by executor...\n");
        }
        return sb.toString();
    }

    public com.example.urgs_api.task.vo.TaskInstanceStatsVO getDailyStats(String date) {
        QueryWrapper<QuartzTaskStatusEntity> query = new QueryWrapper<>();
        applyUpdateDateFilter(query, date);

        List<QuartzTaskStatusEntity> tasks = quartzTaskStatusDao.selectList(query);

        com.example.urgs_api.task.vo.TaskInstanceStatsVO stats = new com.example.urgs_api.task.vo.TaskInstanceStatsVO();
        stats.setTotal(tasks.size());

        long success = tasks.stream()
                .filter(t -> t.getStatus() == 3)
                .count();
        long failed = tasks.stream()
                .filter(t -> t.getStatus() == 4)
                .count();
        long running = tasks.stream()
                .filter(t -> t.getStatus() == 2)
                .count();
        long waiting = tasks.stream()
                .filter(t -> t.getStatus() == 1)
                .count();

        stats.setSuccess(success);
        stats.setFailed(failed);
        stats.setRunning(running);
        stats.setWaiting(waiting);

        if (stats.getTotal() > 0) {
            stats.setSuccessRate((double) success / stats.getTotal() * 100);
        } else {
            stats.setSuccessRate(0);
        }

        return stats;
    }

    public java.util.List<java.util.Map<String, Object>> getHourlyThroughput(String date) {
        String compactDate = normalizeCompactDate(date);

        QueryWrapper<QuartzTaskStatusEntity> query = new QueryWrapper<>();
        query.eq("create_date", compactDate);
        query.eq("status", 3);
        query.isNotNull("end_time");

        List<QuartzTaskStatusEntity> tasks = quartzTaskStatusDao.selectList(query);

        // Group by hour
        java.util.Map<Integer, Long> hourlyCounts = new java.util.HashMap<>();
        for (QuartzTaskStatusEntity task : tasks) {
            if (task.getEndTime() == null) {
                continue;
            }
            int hour = task.getEndTime().getHours();
            hourlyCounts.put(hour, hourlyCounts.getOrDefault(hour, 0L) + 1);
        }

        java.util.List<java.util.Map<String, Object>> result = new java.util.ArrayList<>();
        for (int i = 0; i < 24; i++) {
            java.util.Map<String, Object> item = new java.util.HashMap<>();
            item.put("hour", String.format("%02d:00", i));
            item.put("count", hourlyCounts.getOrDefault(i, 0L));
            result.add(item);
        }

        return result;
    }

    public List<WorkflowStatsVO> getWorkflowStats(String date) {
        QueryWrapper<QuartzTaskStatusEntity> query = new QueryWrapper<>();
        applyUpdateDateFilter(query, date);
        List<QuartzTaskStatusEntity> instances = quartzTaskStatusDao.selectList(query);

        if (instances.isEmpty()) {
            return new ArrayList<>();
        }

        Set<Long> planIds = instances.stream()
                .map(QuartzTaskStatusEntity::getPlanId)
                .collect(Collectors.toSet());

        Map<Long, QuartzTaskEntity> taskMap = quartzTaskDao.selectBatchIds(planIds).stream()
                .collect(Collectors.toMap(QuartzTaskEntity::getId, task -> task));

        Map<String, WorkflowStatsVO> workflowStatsMap = new HashMap<>();

        for (QuartzTaskStatusEntity instance : instances) {
            QuartzTaskEntity task = taskMap.get(instance.getPlanId());
            String workflowName = task == null || !StringUtils.hasText(task.getTaskSystem())
                    ? "未分组"
                    : task.getTaskSystem();

            WorkflowStatsVO vo = workflowStatsMap.computeIfAbsent(workflowName, key -> {
                WorkflowStatsVO item = new WorkflowStatsVO();
                item.setWorkflowName(key);
                return item;
            });

            vo.setTotal(vo.getTotal() + 1);
            if (instance.getStatus() == 3) {
                vo.setSuccess(vo.getSuccess() + 1);
            } else if (instance.getStatus() == 4) {
                vo.setFailed(vo.getFailed() + 1);
            }
        }

        return workflowStatsMap.values().stream()
                .sorted((left, right) -> Long.compare(right.getTotal(), left.getTotal()))
                .collect(Collectors.toList());
    }

    private String normalizeCompactDate(String date) {
        String resolvedDate = StringUtils.hasText(date) ? date : LocalDate.now().toString();
        return resolvedDate.replace("-", "");
    }

    private void applyUpdateDateFilter(QueryWrapper<QuartzTaskStatusEntity> query, String date) {
        LocalDate targetDate = resolveStatsDate(date);
        query.ge("update_time", targetDate.atStartOfDay());
        query.lt("update_time", targetDate.plusDays(1).atStartOfDay());
    }

    private LocalDate resolveStatsDate(String date) {
        if (!StringUtils.hasText(date)) {
            return LocalDate.now();
        }
        String trimmed = date.trim();
        if (trimmed.contains("-")) {
            return LocalDate.parse(trimmed);
        }
        return LocalDate.parse(trimmed, DateTimeFormatter.BASIC_ISO_DATE);
    }

    @Transactional(rollbackFor = Exception.class)
    public String createTaskInstance(String taskId, String dataDate) {
        // DEPENDENT 任务是纯虚拟 DAG 边，不支持创建实例
        Task taskDef = taskMapper.selectById(taskId);
        if (taskDef != null && "DEPENDENT".equals(taskDef.getType())) {
            throw new IllegalArgumentException("DEPENDENT 类型任务不支持创建实例");
        }

        // Check if exists
        QueryWrapper<TaskInstance> query = new QueryWrapper<>();
        query.eq("task_id", taskId);
        query.eq("data_date", dataDate);
        TaskInstance existing = taskInstanceMapper.selectOne(query);
        if (existing != null) {
            String status = existing.getStatus();
            if ("RUNNING".equals(status) || "PENDING".equals(status)) {
                return "EXIST";
            }

            Task task = taskMapper.selectById(taskId);
            if (task != null) {
                existing.setSystemId(task.getSystemId());
                existing.setTaskType(task.getType());
                existing.setContentSnapshot(task.getContent());
                existing.setPriority(task.getPriority());
            }

            existing.setStatus("PENDING"); // Wait for dependencies
            existing.setStartTime(null);
            existing.setEndTime(null);
            existing.setLogContent(null);
            existing.setCreateTime(LocalDateTime.now());
            existing.setUpdateTime(LocalDateTime.now());
            taskInstanceMapper.updateById(existing);

            if (areAllDependenciesMet(taskId, dataDate)) {
                existing.setStatus("WAITING");
                taskInstanceMapper.updateById(existing);
            }

            return String.valueOf(existing.getId());
        }

        TaskInstance instance = new TaskInstance();
        instance.setTaskId(taskId);
        instance.setDataDate(dataDate);
        instance.setStatus("PENDING"); // Wait for dependencies

        // Inherit systemId from task
        Task task = taskMapper.selectById(taskId);
        if (task != null) {
            instance.setSystemId(task.getSystemId());
            instance.setTaskType(task.getType());
            instance.setContentSnapshot(task.getContent());
            instance.setPriority(task.getPriority());
        }

        instance.setCreateTime(LocalDateTime.now());
        instance.setUpdateTime(LocalDateTime.now());

        taskInstanceMapper.insert(instance);

        // Force clear times in case DB set defaults
        UpdateWrapper<TaskInstance> clearTimes = new UpdateWrapper<>();
        clearTimes.eq("id", instance.getId());
        clearTimes.set("start_time", null);
        clearTimes.set("end_time", null);
        taskInstanceMapper.update(null, clearTimes);

        // Check if it can run immediately (no dependencies or all met)
        if (areAllDependenciesMet(taskId, dataDate)) {
            instance.setStatus("WAITING");
            taskInstanceMapper.updateById(instance);
        }

        return String.valueOf(instance.getId());
    }

    public List<UpstreamDependencyVO> getUpstreamDependencies(String taskId, String dataDate) {
        List<UpstreamDependencyVO> result = new ArrayList<>();
        java.util.Set<String> visited = new java.util.HashSet<>();
        java.util.Queue<String[]> queue = new java.util.LinkedList<>();

        // Initialize: direct upstream of the given task
        QueryWrapper<TaskDependency> initQuery = new QueryWrapper<>();
        initQuery.eq("task_id", taskId);
        for (TaskDependency dep : taskDependencyMapper.selectList(initQuery)) {
            queue.add(new String[]{dep.getPreTaskId(), "1"});
        }

        while (!queue.isEmpty()) {
            String[] item = queue.poll();
            String curTaskId = item[0];
            int level = Integer.parseInt(item[1]);

            if (visited.contains(curTaskId)) continue;
            visited.add(curTaskId);

            Task preTask = taskMapper.selectById(curTaskId);

            // Skip DEPENDENT proxy tasks: resolve to real task via content.taskId
            if (preTask != null && "DEPENDENT".equals(preTask.getType())) {
                String realTaskId = extractTaskIdFromContent(preTask.getContent());
                if (realTaskId != null && !visited.contains(realTaskId)) {
                    queue.add(new String[]{realTaskId, String.valueOf(level)});
                }
                continue;
            }

            UpstreamDependencyVO vo = new UpstreamDependencyVO();
            vo.setTaskId(curTaskId);
            vo.setLevel(level);
            vo.setTaskName(preTask != null ? preTask.getName() : curTaskId);

            QueryWrapper<TaskInstance> instQuery = new QueryWrapper<>();
            instQuery.eq("task_id", curTaskId);
            instQuery.eq("data_date", dataDate);
            TaskInstance preInstance = taskInstanceMapper.selectOne(instQuery);

            if (preInstance != null) {
                vo.setStatus(preInstance.getStatus());
                vo.setInstanceId(preInstance.getId());
                vo.setStartTime(preInstance.getStartTime() != null ? preInstance.getStartTime().toString() : null);
                vo.setEndTime(preInstance.getEndTime() != null ? preInstance.getEndTime().toString() : null);
            } else {
                // No instance found: default to WAITING (等待下发), consistent with dependency graph
                vo.setStatus("WAITING");
            }

            result.add(vo);

            // BFS: continue to this task's upstream
            QueryWrapper<TaskDependency> nextQuery = new QueryWrapper<>();
            nextQuery.eq("task_id", curTaskId);
            for (TaskDependency dep : taskDependencyMapper.selectList(nextQuery)) {
                if (!visited.contains(dep.getPreTaskId())) {
                    queue.add(new String[]{dep.getPreTaskId(), String.valueOf(level + 1)});
                }
            }
        }

        result.sort(java.util.Comparator.comparingInt(UpstreamDependencyVO::getLevel));
        return result;
    }

    /**
     * Detect circular dependency: BFS from each preTaskId upstream,
     * if taskId is reachable, adding these dependencies would create a cycle.
     */
    private boolean hasCircularDependency(String taskId, List<String> preTaskIds) {
        java.util.Set<String> visited = new java.util.HashSet<>();
        java.util.Queue<String> queue = new java.util.LinkedList<>(preTaskIds);

        while (!queue.isEmpty()) {
            String cur = queue.poll();
            if (cur.equals(taskId)) return true;
            if (visited.contains(cur)) continue;
            visited.add(cur);

            QueryWrapper<TaskDependency> qw = new QueryWrapper<>();
            qw.eq("task_id", cur);
            for (TaskDependency dep : taskDependencyMapper.selectList(qw)) {
                if (!visited.contains(dep.getPreTaskId())) {
                    queue.offer(dep.getPreTaskId());
                }
            }
        }
        return false;
    }

    private String extractTaskIdFromContent(String content) {
        if (content == null || content.isBlank()) return null;
        try {
            com.fasterxml.jackson.databind.ObjectMapper om = new com.fasterxml.jackson.databind.ObjectMapper();
            com.fasterxml.jackson.databind.JsonNode node = om.readTree(content);
            com.fasterxml.jackson.databind.JsonNode taskIdNode = node.get("taskId");
            return taskIdNode != null && !taskIdNode.isNull() ? taskIdNode.asText() : null;
        } catch (Exception e) {
            return null;
        }
    }

    public TaskDefinitionStatsVO getTaskGlobalStats() {
        TaskDefinitionStatsVO stats = new TaskDefinitionStatsVO();

        long total = taskMapper.selectCount(null);
        long enabled = taskMapper.selectCount(new QueryWrapper<Task>().ne("status", 0));
        long disabled = total - enabled;

        // Count distinct system IDs
        QueryWrapper<Task> systemQuery = new QueryWrapper<>();
        systemQuery.select("distinct system_id");
        long systems = taskMapper.selectList(systemQuery).stream()
                .filter(t -> t != null && t.getSystemId() != null)
                .map(Task::getSystemId)
                .distinct()
                .count();

        long workflows = workflowMapper.selectCount(null);

        stats.setTotal(total);
        stats.setEnabled(enabled);
        stats.setDisabled(disabled);
        stats.setSystems(systems);
        stats.setWorkflows(workflows);

        return stats;
    }
}
