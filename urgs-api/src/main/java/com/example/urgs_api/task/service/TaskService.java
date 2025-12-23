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
import com.example.urgs_api.task.vo.WorkflowStatsVO;
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
            String cronExpression, Integer status, Integer priority, List<String> preTaskIds) {
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

        // 2. Insert new
        if (preTaskIds != null && !preTaskIds.isEmpty()) {
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

    public com.baomidou.mybatisplus.core.metadata.IPage<Task> listTasks(String keyword, String workflowIds,
            Integer page, Integer size) {
        com.baomidou.mybatisplus.extension.plugins.pagination.Page<Task> pageObj = new com.baomidou.mybatisplus.extension.plugins.pagination.Page<>(
                page, size);
        QueryWrapper<Task> query = new QueryWrapper<>();
        if (StringUtils.hasText(keyword)) {
            query.like("name", keyword);
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
        instance.setStatus("WAITING"); // Reset to WAITING
        instance.setStartTime(null);
        instance.setEndTime(null);
        instance.setUpdateTime(LocalDateTime.now());
        taskInstanceMapper.updateById(instance);
    }

    @Transactional(rollbackFor = Exception.class)
    public void forceSuccess(String instanceId) {
        TaskInstance instance = taskInstanceMapper.selectById(instanceId);
        if (instance == null)
            return;

        instance.setStatus("FORCE_SUCCESS");
        instance.setEndTime(LocalDateTime.now());
        instance.setUpdateTime(LocalDateTime.now());
        instance.setLogContent(
                instance.getLogContent() + "\n[System] Manually marked as success at " + LocalDateTime.now());
        taskInstanceMapper.updateById(instance);

        // Trigger downstream tasks
        checkAndPromoteDownstream(instance);
    }

    private void checkAndPromoteDownstream(TaskInstance completedInstance) {
        // 1. Find downstream tasks
        QueryWrapper<TaskDependency> depWrapper = new QueryWrapper<>();
        depWrapper.eq("pre_task_id", completedInstance.getTaskId());
        List<TaskDependency> downstreamDeps = taskDependencyMapper.selectList(depWrapper);

        for (TaskDependency dep : downstreamDeps) {
            String downstreamTaskId = dep.getTaskId();

            // 2. Find downstream instance for the same data_date
            QueryWrapper<TaskInstance> instanceWrapper = new QueryWrapper<>();
            instanceWrapper.eq("task_id", downstreamTaskId);
            instanceWrapper.eq("data_date", completedInstance.getDataDate());
            TaskInstance downstreamInstance = taskInstanceMapper.selectOne(instanceWrapper);

            if (downstreamInstance != null && "PENDING".equals(downstreamInstance.getStatus())) {
                // 3. Check if ALL upstream dependencies are met
                if (areAllDependenciesMet(downstreamTaskId, completedInstance.getDataDate())) {
                    downstreamInstance.setStatus("WAITING");
                    downstreamInstance.setUpdateTime(LocalDateTime.now());
                    taskInstanceMapper.updateById(downstreamInstance);
                    log.info("Downstream task {} promoted to WAITING due to force success of {}",
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
        if (instance != null) {
            log.info("Retrieved log for task {}. Content length: {}", id,
                    instance.getLogContent() != null ? instance.getLogContent().length() : "null");
            return instance.getLogContent();
        }
        return "Log not found";
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
        if (taskInstanceMapper.selectCount(query) > 0) {
            return "EXIST";
        }

        TaskInstance instance = new TaskInstance();
        instance.setTaskId(taskId);
        instance.setDataDate(dataDate);
        instance.setStatus("PENDING"); // Wait for dependencies
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
}
