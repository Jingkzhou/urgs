package com.example.urgs_api.task.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
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

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
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

            // Check instance status
            QueryWrapper<TaskInstance> instanceQuery = new QueryWrapper<>();
            instanceQuery.eq("task_id", downstreamTaskId);
            instanceQuery.eq("data_date", dataDate);
            TaskInstance dsInstance = taskInstanceMapper.selectOne(instanceQuery);

            if (dsInstance != null) {
                String status = dsInstance.getStatus();
                if (!"SUCCESS".equals(status) && !"FAILURE".equals(status) && !"FORCE_SUCCESS".equals(status)) {
                    // Invalid status (RUNNING, WAITING, PENDING)
                    Task task = taskMapper.selectById(downstreamTaskId);
                    invalidTasks.add(task != null ? task.getName() : downstreamTaskId);
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

        String taskType = task.getType();
        String initialStatus;

        if ("DEPENDENT".equals(taskType)) {
            // DEPENDENT 影子任务：查母体任务状态，直接镜像
            initialStatus = resolveParentStatus(instance.getTaskId(), instance.getDataDate());
        } else {
            // 普通任务：先设 PENDING，检查依赖后再决定
            initialStatus = "PENDING";
        }

        UpdateWrapper<TaskInstance> updateWrapper = new UpdateWrapper<>();
        updateWrapper.eq("id", instance.getId());
        updateWrapper.set("task_type", task.getType());
        updateWrapper.set("system_id", task.getSystemId());
        updateWrapper.set("content_snapshot", task.getContent());
        updateWrapper.set("priority", task.getPriority());
        updateWrapper.set("status", initialStatus);
        updateWrapper.set("retry_count", 0);
        updateWrapper.set("start_time", null);
        updateWrapper.set("end_time", null);
        updateWrapper.set("log_content", null);
        updateWrapper.set("create_time", now);
        updateWrapper.set("update_time", now);
        taskInstanceMapper.update(null, updateWrapper);

        // DEPENDENT 影子任务如果母体已成功，递归传播下游
        if ("DEPENDENT".equals(taskType)
                && ("SUCCESS".equals(initialStatus) || "FORCE_SUCCESS".equals(initialStatus))) {
            // 重新查询更新后的实例用于传播
            TaskInstance updated = taskInstanceMapper.selectById(instance.getId());
            if (updated != null) {
                checkAndPromoteDownstream(updated);
            }
        }

        // 非 DEPENDENT 任务：检查依赖是否满足，满足则提升为 WAITING
        if (!"DEPENDENT".equals(taskType)
                && areAllDependenciesMet(instance.getTaskId(), instance.getDataDate())) {
            UpdateWrapper<TaskInstance> statusUpdate = new UpdateWrapper<>();
            statusUpdate.eq("id", instance.getId());
            statusUpdate.set("status", "WAITING");
            taskInstanceMapper.update(null, statusUpdate);
        }
    }

    /**
     * 查询 DEPENDENT 影子任务的母体（第一个上游依赖）状态，直接镜像
     */
    private String resolveParentStatus(String taskId, String dataDate) {
        QueryWrapper<TaskDependency> depWrapper = new QueryWrapper<>();
        depWrapper.eq("task_id", taskId);
        List<TaskDependency> deps = taskDependencyMapper.selectList(depWrapper);

        if (deps.isEmpty()) {
            return "WAITING";
        }

        // 取第一个上游作为母体（与 syncShadowTasks 逻辑一致）
        String parentTaskId = deps.get(0).getPreTaskId();
        QueryWrapper<TaskInstance> parentWrapper = new QueryWrapper<>();
        parentWrapper.eq("task_id", parentTaskId);
        parentWrapper.eq("data_date", dataDate);
        TaskInstance parent = taskInstanceMapper.selectOne(parentWrapper);

        if (parent == null) {
            return "PENDING";
        }

        return parent.getStatus();
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

    private void checkAndPromoteDownstream(TaskInstance completedInstance) {
        // 1. 查找所有以该任务为前置依赖的下游任务
        QueryWrapper<TaskDependency> depWrapper = new QueryWrapper<>();
        depWrapper.eq("pre_task_id", completedInstance.getTaskId());
        List<TaskDependency> downstreamDeps = taskDependencyMapper.selectList(depWrapper);

        for (TaskDependency dep : downstreamDeps) {
            String downstreamTaskId = dep.getTaskId();

            // 2. 找到同业务日期的下游任务实例
            QueryWrapper<TaskInstance> instanceWrapper = new QueryWrapper<>();
            instanceWrapper.eq("task_id", downstreamTaskId);
            instanceWrapper.eq("data_date", completedInstance.getDataDate());
            TaskInstance downstreamInstance = taskInstanceMapper.selectOne(instanceWrapper);

            if (downstreamInstance == null) continue;

            // DEPENDENT 影子任务：直接镜像上游状态并递归传播
            if ("DEPENDENT".equals(downstreamInstance.getTaskType())) {
                if (!"SUCCESS".equals(downstreamInstance.getStatus())
                        && !"FORCE_SUCCESS".equals(downstreamInstance.getStatus())) {
                    downstreamInstance.setStatus("SUCCESS");
                    downstreamInstance.setEndTime(LocalDateTime.now());
                    downstreamInstance.setUpdateTime(LocalDateTime.now());
                    String ts = LocalDateTime.now()
                            .format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
                    downstreamInstance.setLogContent(
                            "[" + ts + "] 影子任务: 上游任务 " + completedInstance.getTaskId() + " 已成功");
                    taskInstanceMapper.updateById(downstreamInstance);
                    log.info("影子任务 {} 已同步为 SUCCESS（上游: {}）", downstreamInstance.getId(),
                            completedInstance.getId());
                    // 递归：继续传播影子任务的下游
                    checkAndPromoteDownstream(downstreamInstance);
                }
                continue;
            }

            // 普通任务：PENDING → WAITING
            if ("PENDING".equals(downstreamInstance.getStatus())) {
                if (areAllDependenciesMet(downstreamTaskId, completedInstance.getDataDate())) {
                    downstreamInstance.setStatus("WAITING");
                    downstreamInstance.setUpdateTime(LocalDateTime.now());
                    taskInstanceMapper.updateById(downstreamInstance);
                    log.info("下游任务 {} 依赖已满足，状态提升为 WAITING（因 {} 强制成功）",
                            downstreamInstance.getId(), completedInstance.getId());
                }
            }
        }
    }

    private boolean areAllDependenciesMet(String taskId, String dataDate) {
        // Get all upstream dependencies
        QueryWrapper<TaskDependency> upstreamWrapper = new QueryWrapper<>();
        upstreamWrapper.eq("task_id", taskId);
        List<TaskDependency> upstreamDeps = taskDependencyMapper.selectList(upstreamWrapper);

        for (TaskDependency dep : upstreamDeps) {
            // Check status of each upstream task instance
            QueryWrapper<TaskInstance> preInstanceWrapper = new QueryWrapper<>();
            preInstanceWrapper.eq("task_id", dep.getPreTaskId());
            preInstanceWrapper.eq("data_date", dataDate);
            TaskInstance preInstance = taskInstanceMapper.selectOne(preInstanceWrapper);

            if (preInstance == null) {
                return false; // Upstream instance doesn't exist yet
            }

            if (!"SUCCESS".equals(preInstance.getStatus()) &&
                    !"FORCE_SUCCESS".equals(preInstance.getStatus())) {
                return false; // Upstream not complete
            }
        }
        return true;
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
        if (date == null) {
            date = java.time.LocalDate.now().toString(); // YYYY-MM-DD
        }

        QueryWrapper<TaskInstance> query = new QueryWrapper<>();
        query.like("create_time", date);

        List<TaskInstance> tasks = taskInstanceMapper.selectList(query);

        com.example.urgs_api.task.vo.TaskInstanceStatsVO stats = new com.example.urgs_api.task.vo.TaskInstanceStatsVO();
        stats.setTotal(tasks.size());

        long success = tasks.stream()
                .filter(t -> "SUCCESS".equals(t.getStatus()) || "FORCE_SUCCESS".equals(t.getStatus())).count();
        long failed = tasks.stream().filter(t -> "FAIL".equals(t.getStatus())).count();
        long running = tasks.stream().filter(t -> "RUNNING".equals(t.getStatus())).count();
        long waiting = tasks.stream().filter(t -> "WAITING".equals(t.getStatus()) || "PENDING".equals(t.getStatus()))
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
        if (date == null) {
            date = java.time.LocalDate.now().toString();
        }

        QueryWrapper<TaskInstance> query = new QueryWrapper<>();
        query.like("end_time", date);
        query.in("status", "SUCCESS", "FORCE_SUCCESS");

        List<TaskInstance> tasks = taskInstanceMapper.selectList(query);

        // Group by hour
        java.util.Map<Integer, Long> hourlyCounts = tasks.stream()
                .filter(t -> t.getEndTime() != null)
                .collect(java.util.stream.Collectors.groupingBy(
                        t -> t.getEndTime().getHour(),
                        java.util.stream.Collectors.counting()));

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
        if (date == null) {
            date = java.time.LocalDate.now().toString();
        }

        // 1. Get all workflows
        List<Workflow> workflows = workflowMapper.selectList(null);

        // 2. Get all task instances for the date
        QueryWrapper<TaskInstance> query = new QueryWrapper<>();
        query.like("create_time", date);
        List<TaskInstance> instances = taskInstanceMapper.selectList(query);

        // Map taskId -> List<TaskInstance>
        Map<String, List<TaskInstance>> taskInstanceMap = new HashMap<>();
        for (TaskInstance instance : instances) {
            taskInstanceMap.computeIfAbsent(instance.getTaskId(), k -> new ArrayList<>()).add(instance);
        }

        List<WorkflowStatsVO> result = new ArrayList<>();

        for (Workflow workflow : workflows) {
            WorkflowStatsVO vo = new WorkflowStatsVO();
            vo.setWorkflowName(workflow.getName());
            long total = 0;
            long success = 0;
            long failed = 0;

            try {
                if (workflow.getContent() != null) {
                    JsonNode root = objectMapper.readTree(workflow.getContent());
                    if (root.has("nodes")) {
                        for (JsonNode node : root.get("nodes")) {
                            if (node.has("id")) {
                                String taskId = node.get("id").asText();
                                List<TaskInstance> taskInstances = taskInstanceMap.get(taskId);
                                if (taskInstances != null) {
                                    total += taskInstances.size();
                                    success += taskInstances.stream()
                                            .filter(t -> "SUCCESS".equals(t.getStatus())
                                                    || "FORCE_SUCCESS".equals(t.getStatus()))
                                            .count();
                                    failed += taskInstances.stream()
                                            .filter(t -> "FAIL".equals(t.getStatus())
                                                    || "FAILURE".equals(t.getStatus())) // Cover both possibilities just
                                                                                        // in case
                                            .count();
                                }
                            }
                        }
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }

            vo.setTotal(total);
            vo.setSuccess(success);
            vo.setFailed(failed);

            // Only add if there are instances (active today)
            if (total > 0) {
                result.add(vo);
            }
        }

        return result;
    }

    @Transactional(rollbackFor = Exception.class)
    public String createTaskInstance(String taskId, String dataDate) {
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
