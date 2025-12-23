package com.example.executor.urgs_executor.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.executor.urgs_executor.entity.TaskInstance;
import com.example.executor.urgs_executor.entity.TaskDependency;
import com.example.executor.urgs_executor.mapper.TaskDependencyMapper;
import com.example.executor.urgs_executor.mapper.TaskInstanceMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import com.example.executor.urgs_executor.entity.Issue;
import com.example.executor.urgs_executor.entity.Task;
import com.example.executor.urgs_executor.entity.Workflow;
import com.example.executor.urgs_executor.mapper.IssueMapper;
import com.example.executor.urgs_executor.mapper.TaskMapper;
import com.example.executor.urgs_executor.mapper.WorkflowMapper;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Service("urgsTaskExecutor")
public class TaskExecutor {

    @Autowired
    private TaskInstanceMapper taskInstanceMapper;

    @Autowired
    private TaskDependencyMapper taskDependencyMapper;

    @Autowired
    private com.example.executor.urgs_executor.handler.TaskHandlerFactory taskHandlerFactory;

    @Autowired
    private TaskMapper taskMapper;

    @Autowired
    private IssueMapper issueMapper;

    @Autowired
    private WorkflowMapper workflowMapper;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private final java.util.concurrent.ExecutorService taskThreadPool = java.util.concurrent.Executors
            .newFixedThreadPool(10);
    private final java.util.concurrent.ConcurrentHashMap<Long, java.util.concurrent.Future<?>> runningTasks = new java.util.concurrent.ConcurrentHashMap<>();

    @Scheduled(fixedDelay = 3000) // Poll every 3 seconds
    public void pollAndExecute() {
        // 0. Check capacity
        if (runningTasks.size() >= 10) {
            log.debug("Task pool is full ({}), skipping poll", runningTasks.size());
            return;
        }

        // 1. Fetch WAITING tasks (Limit to remaining capacity)
        int limit = 10 - runningTasks.size();
        if (limit <= 0)
            return;

        QueryWrapper<TaskInstance> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("status", TaskInstance.STATUS_WAITING);
        queryWrapper.ne("task_type", "DEPENDENT");
        queryWrapper.last("LIMIT " + limit);
        List<TaskInstance> waitingTasks = taskInstanceMapper.selectList(queryWrapper);

        if (waitingTasks.isEmpty()) {
            return;
        }

        log.info("Found {} waiting tasks", waitingTasks.size());

        for (TaskInstance instance : waitingTasks) {
            // 2. Try to acquire lock
            int rows = taskInstanceMapper.tryLockTask(instance.getId());
            if (rows > 0) {
                // Lock acquired
                log.info("Lock acquired for task instance: {}", instance.getId());

                // Set to RUNNING immediately to prevent re-fetch
                instance.setStartTime(LocalDateTime.now());
                instance.setEndTime(null);
                instance.setStatus(TaskInstance.STATUS_RUNNING);
                taskInstanceMapper.updateById(instance);

                // Submit to thread pool
                java.util.concurrent.Future<?> future = taskThreadPool.submit(() -> executeTask(instance));
                runningTasks.put(instance.getId(), future);
            } else {
                // Lock failed (taken by another node)
                log.debug("Failed to acquire lock for task instance: {}", instance.getId());
            }
        }
    }

    @Scheduled(fixedDelay = 2000) // Check for stopped tasks every 2 seconds
    public void checkStoppedTasks() {
        if (runningTasks.isEmpty())
            return;

        for (Long instanceId : runningTasks.keySet()) {
            TaskInstance instance = taskInstanceMapper.selectById(instanceId);
            if (instance != null && "STOPPED".equals(instance.getStatus())) {
                java.util.concurrent.Future<?> future = runningTasks.get(instanceId);
                if (future != null && !future.isDone() && !future.isCancelled()) {
                    log.info("Stopping task instance {} as requested", instanceId);
                    future.cancel(true); // Interrupt the thread
                }
            }
        }
    }

    @Scheduled(fixedDelay = 2000)
    public void syncShadowTasks() {
        // 1. Find all active DEPENDENT tasks
        QueryWrapper<TaskInstance> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("task_type", "DEPENDENT");
        queryWrapper.in("status", TaskInstance.STATUS_PENDING, TaskInstance.STATUS_WAITING,
                TaskInstance.STATUS_RUNNING);
        List<TaskInstance> shadowTasks = taskInstanceMapper.selectList(queryWrapper);

        for (TaskInstance shadow : shadowTasks) {
            // 2. Find upstream dependency (Assume 1:1)
            QueryWrapper<TaskDependency> depWrapper = new QueryWrapper<>();
            depWrapper.eq("task_id", shadow.getTaskId());
            List<TaskDependency> deps = taskDependencyMapper.selectList(depWrapper);

            if (deps.isEmpty())
                continue;

            // Determine Upstream Task ID (Take the first one)
            String upstreamTaskId = deps.get(0).getPreTaskId();

            // 3. Find Upstream Instance
            QueryWrapper<TaskInstance> upstreamWrapper = new QueryWrapper<>();
            upstreamWrapper.eq("task_id", upstreamTaskId);
            upstreamWrapper.eq("data_date", shadow.getDataDate());
            TaskInstance upstream = taskInstanceMapper.selectOne(upstreamWrapper);

            if (upstream == null)
                continue;

            boolean changed = false;
            String newStatus = shadow.getStatus();

            // 4. Sync Status
            // Check current status of upstream and mirror it
            String upstreamStatus = upstream.getStatus();

            if (TaskInstance.STATUS_WAITING.equals(upstreamStatus)) {
                if (!TaskInstance.STATUS_WAITING.equals(shadow.getStatus())) {
                    newStatus = TaskInstance.STATUS_WAITING;
                    changed = true;
                }
            } else if (TaskInstance.STATUS_RUNNING.equals(upstreamStatus)) {
                if (!TaskInstance.STATUS_RUNNING.equals(shadow.getStatus())) {
                    newStatus = TaskInstance.STATUS_RUNNING;
                    if (shadow.getStartTime() == null) {
                        shadow.setStartTime(upstream.getStartTime());
                    }
                    changed = true;
                }
            } else if (TaskInstance.STATUS_SUCCESS.equals(upstreamStatus)
                    || TaskInstance.STATUS_FORCE_SUCCESS.equals(upstreamStatus)) {
                if (!TaskInstance.STATUS_SUCCESS.equals(shadow.getStatus())
                        && !TaskInstance.STATUS_FORCE_SUCCESS.equals(shadow.getStatus())) {
                    newStatus = TaskInstance.STATUS_SUCCESS;
                    shadow.setEndTime(upstream.getEndTime());
                    shadow.setLogContent("Shadow Task: Upstream " + upstreamTaskId + " Succeeded.");
                    changed = true;
                }
            } else if (TaskInstance.STATUS_FAIL.equals(upstreamStatus)) {
                if (!TaskInstance.STATUS_FAIL.equals(shadow.getStatus())) {
                    newStatus = TaskInstance.STATUS_FAIL;
                    shadow.setEndTime(upstream.getEndTime());
                    shadow.setLogContent("Shadow Task: Upstream " + upstreamTaskId + " Failed.");
                    changed = true;
                }
            }

            if (changed) {
                shadow.setStatus(newStatus);
                shadow.setUpdateTime(LocalDateTime.now());
                taskInstanceMapper.updateById(shadow);
                log.info("Shadow task {} synced to status {} (Upstream: {})", shadow.getId(), newStatus,
                        upstream.getId());

                // If finished successfully, trigger downstream
                if (TaskInstance.STATUS_SUCCESS.equals(newStatus)) {
                    checkDownstreamTasks(shadow);
                }
            }
        }
    }

    private void executeTask(TaskInstance instance) {
        try {
            log.info("Executing task instance: {} (TaskID: {}, Type: {}, Date: {})",
                    instance.getId(), instance.getTaskId(), instance.getTaskType(), instance.getDataDate());

            // 1. Get Handler
            com.example.executor.urgs_executor.handler.TaskHandler handler = taskHandlerFactory
                    .getHandler(instance.getTaskType());

            if (handler == null) {
                throw new RuntimeException("No handler found for task type: " + instance.getTaskType());
            }

            // 2. Execute
            String logContent = handler.execute(instance);

            // 3. Update Status to SUCCESS
            instance.setStatus(TaskInstance.STATUS_SUCCESS);
            instance.setEndTime(LocalDateTime.now());
            instance.setLogContent(logContent);
            taskInstanceMapper.updateById(instance);

            log.info("Task instance {} completed successfully", instance.getId());

            // 4. Trigger Downstream Tasks
            checkDownstreamTasks(instance);

        } catch (InterruptedException e) {
            log.warn("Task instance {} execution interrupted (STOPPED)", instance.getId());
            // Status is already STOPPED in DB by API, or we should set it?
            // API sets it to STOPPED. We just need to ensure we don't overwrite it with
            // FAIL.
            // But if we catch InterruptedException, we should probably check if it's
            // STOPPED.
            // If API set it to STOPPED, we leave it.
            TaskInstance current = taskInstanceMapper.selectById(instance.getId());
            if (!"STOPPED".equals(current.getStatus())) {
                // If not stopped by API (e.g. system shutdown), maybe set to FAIL or STOPPED?
                // For now assume API stop.
            }
        } catch (Exception e) {
            // Check if it was a wrapped InterruptedException
            if (e instanceof RuntimeException && e.getCause() instanceof InterruptedException) {
                log.warn("Task instance {} execution interrupted (STOPPED)", instance.getId());
                return;
            }

            log.error("Task instance {} failed", instance.getId(), e);

            // 4. Update Status to FAIL
            // Don't overwrite STOPPED
            TaskInstance current = taskInstanceMapper.selectById(instance.getId());
            if (!"STOPPED".equals(current.getStatus())) {
                instance.setStatus(TaskInstance.STATUS_FAIL);
                instance.setEndTime(LocalDateTime.now());

                // Save exception to log
                java.io.StringWriter sw = new java.io.StringWriter();
                java.io.PrintWriter pw = new java.io.PrintWriter(sw);
                e.printStackTrace(pw);
                String stackTrace = sw.toString();

                // Truncate if too long (e.g. 10000 chars) to prevent DB error
                if (stackTrace.length() > 10000) {
                    stackTrace = stackTrace.substring(0, 10000) + "\n... [Truncated]";
                }
                String currentLog = instance.getLogContent();
                instance.setLogContent((currentLog != null ? currentLog + "\n" : "") + stackTrace);

                try {
                    log.info("Saving error log for task instance {}. Log length: {}", instance.getId(),
                            stackTrace.length());
                    int rows = taskInstanceMapper.updateById(instance);
                    log.info("Updated task instance {}. Rows affected: {}", instance.getId(), rows);
                } catch (Exception updateEx) {
                    log.error("Failed to update task instance {} with error log", instance.getId(), updateEx);
                }
            }

            // 5. Auto Register Issue
            try {
                registerIssue(instance, e);
            } catch (Exception issueEx) {
                log.error("Failed to auto-register issue for task {}", instance.getId(), issueEx);
            }
        } finally {
            runningTasks.remove(instance.getId());
        }
    }

    private void registerIssue(TaskInstance instance, Exception e) {
        String taskId = instance.getTaskId();
        String dataDate = instance.getDataDate();

        // 1. Idempotency Check
        QueryWrapper<Issue> checkWrapper = new QueryWrapper<>();
        checkWrapper.like("description", "实例ID: " + instance.getId());
        if (issueMapper.selectCount(checkWrapper) > 0) {
            log.info("Issue already exists for instance {}", instance.getId());
            return;
        }

        // Also check by task + dataDate to be stricter (matches frontend logic)
        // logic: if any issue for this task has the same dataDate in title/desc
        // BUT strict constraint: one issue per failed instance ID is safer?
        // User Requirement: "strictly ensure that only one issue is created per unique
        // task and data date combination"
        // So I should check if ANY issue exists for this Task + DataDate.

        QueryWrapper<Issue> taskDateWrapper = new QueryWrapper<>();
        taskDateWrapper.and(wrapper -> wrapper.like("description", "任务ID: " + taskId).or().like("description", taskId))
                .and(wrapper -> wrapper.like("description", dataDate).or().like("title", dataDate));

        // This is a fuzzy check. A more precise check would be better if we had
        // structured fields, but description is all we have.
        // Let's iterate issues for this task to be safe, like frontend did.
        // Or trust the specific string formats.

        List<Issue> existingIssues = issueMapper
                .selectList(new QueryWrapper<Issue>().like("description", "任务ID: " + taskId));
        boolean exists = existingIssues.stream()
                .anyMatch(issue -> (issue.getTitle() != null && issue.getTitle().contains(dataDate)) ||
                        (issue.getDescription() != null && issue.getDescription().contains(dataDate)));

        if (exists) {
            log.info("Issue already exists for task {} date {}", taskId, dataDate);
            return;
        }

        // 2. Fetch Metadata
        String taskName = taskId;
        Task task = taskMapper.selectById(taskId);
        if (task != null)
            taskName = task.getName();

        String wfName = "Unknown";
        String owner = "Admin";

        // Scan workflows to find parent
        List<Workflow> workflows = workflowMapper.selectList(null);
        for (Workflow wf : workflows) {
            if (wf.getContent() != null && wf.getContent().contains(taskId)) {
                // Confirm with JSON parsing
                try {
                    JsonNode root = objectMapper.readTree(wf.getContent());
                    if (root.has("nodes")) {
                        for (JsonNode node : root.get("nodes")) {
                            String nodeId = node.has("id") ? node.get("id").asText() : "";
                            if (nodeId.equals(taskId)) {
                                wfName = wf.getName();
                                owner = wf.getOwner();
                                break;
                            }
                        }
                    }
                } catch (Exception ignored) {
                }
            }
            if (!"Unknown".equals(wfName))
                break;
        }
        if (owner == null || owner.isEmpty())
            owner = "Admin";

        // 3. Create Issue
        Issue issue = new Issue();
        issue.setTitle("[自动登记] 任务失败: " + taskName + " - " + dataDate);
        issue.setSystem(wfName);
        issue.setIssueType("批量任务处理");
        issue.setOccurTime(LocalDateTime.now());
        issue.setReporter("System");
        issue.setHandler(owner);
        issue.setStatus("新建");

        StringBuilder desc = new StringBuilder();
        desc.append("任务名称: ").append(taskName).append("\n");
        desc.append("任务ID: ").append(taskId).append("\n");
        desc.append("实例ID: ").append(instance.getId()).append("\n");
        desc.append("工作流: ").append(wfName).append("\n");
        desc.append("数据日期: ").append(dataDate).append("\n\n");

        StringWriter sw = new StringWriter();
        e.printStackTrace(new PrintWriter(sw));
        String stack = sw.toString();
        if (stack.length() > 2000)
            stack = stack.substring(0, 2000) + "..."; // Limit size

        desc.append("异常信息:\n").append(stack);

        issue.setDescription(desc.toString());
        issue.setCreateTime(LocalDateTime.now());
        issue.setUpdateTime(LocalDateTime.now());
        issue.setCreateBy("System");

        issueMapper.insert(issue);
        log.info("Auto-registered issue for task instance {}", instance.getId());
    }

    private void checkDownstreamTasks(TaskInstance completedInstance) {
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

            if (downstreamInstance != null && TaskInstance.STATUS_PENDING.equals(downstreamInstance.getStatus())) {
                // 3. Check if ALL upstream dependencies are met
                if (areAllDependenciesMet(downstreamTaskId, completedInstance.getDataDate())) {
                    downstreamInstance.setStatus(TaskInstance.STATUS_WAITING);
                    taskInstanceMapper.updateById(downstreamInstance);
                    log.info("Downstream task {} promoted to WAITING", downstreamInstance.getId());
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

            if (!TaskInstance.STATUS_SUCCESS.equals(preInstance.getStatus()) &&
                    !TaskInstance.STATUS_FORCE_SUCCESS.equals(preInstance.getStatus())) {
                return false; // Upstream not complete
            }
        }
        return true;
    }
}
