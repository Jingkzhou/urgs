package com.example.executor.urgs_executor.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.executor.urgs_executor.entity.ExecutorTaskInstance;
import com.example.executor.urgs_executor.entity.TaskDependency;
import com.example.executor.urgs_executor.mapper.TaskDependencyMapper;
import com.example.executor.urgs_executor.mapper.ExecutorTaskInstanceMapper;
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

/**
 * 任务执行调度器 (TaskExecutor)
 * 核心功能：
 * 1. 轮询并执行待处理任务 (WAITING -> RUNNING)。
 * 2. 并在执行过程中实时更新日志与状态。
 * 3. 监控并响应任务停止请求。
 * 4. 同步影子任务 (DEPENDENT 类型) 的状态。
 * 5. 任务失败后自动登记问题单。
 */
@Slf4j
@Service("urgsTaskExecutor")
public class TaskExecutor {

    @Autowired
    private ExecutorTaskInstanceMapper taskInstanceMapper;

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

    /**
     * 核心调度逻辑：轮询并执行待处理任务
     * 每3秒执行一次。采用乐观锁机制确保分布式环境下同一任务只被一个执行器节点获取。
     */
    @Scheduled(fixedDelay = 3000) // Poll every 3 seconds
    public void pollAndExecute() {
        // 0. 检查当前节点负载，如果线程池已满则跳过本次轮询
        if (runningTasks.size() >= 10) {
            log.debug("Task pool is full ({}), skipping poll", runningTasks.size());
            return;
        }

        // 1. 获取待执行任务 (限定数量以匹配剩余线程池容量)
        int limit = 10 - runningTasks.size();
        if (limit <= 0)
            return;

        QueryWrapper<ExecutorTaskInstance> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("status", ExecutorTaskInstance.STATUS_WAITING);
        queryWrapper.ne("task_type", "DEPENDENT"); // 排除影子任务，影子任务通过状态同步处理
        queryWrapper.last("LIMIT " + limit);
        List<ExecutorTaskInstance> waitingTasks = taskInstanceMapper.selectList(queryWrapper);

        if (waitingTasks.isEmpty()) {
            return;
        }

        log.info("Found {} waiting tasks", waitingTasks.size());

        for (ExecutorTaskInstance instance : waitingTasks) {
            // 2. 尝试获取分布式乐观锁 (基于数据库更新行数)
            int rows = taskInstanceMapper.tryLockTask(instance.getId());
            if (rows > 0) {
                // 成功锁定任务
                log.info("Lock acquired for task instance: {}", instance.getId());

                // 立即更新状态为 RUNNING，防止其他节点在极短时间内重复拉取
                instance.setStartTime(LocalDateTime.now());
                instance.setEndTime(null);
                instance.setStatus(ExecutorTaskInstance.STATUS_RUNNING);
                taskInstanceMapper.updateById(instance);

                // 异步提交至线程池执行
                java.util.concurrent.Future<?> future = taskThreadPool.submit(() -> executeTask(instance));
                runningTasks.put(instance.getId(), future);
            } else {
                // 获取锁失败（可能被其他执行器实例先行抢占）
                log.debug("Failed to acquire lock for task instance: {}", instance.getId());
            }
        }
    }

    /**
     * 检查并取消外部停止请求的任务
     */
    @Scheduled(fixedDelay = 2000) // Check for stopped tasks every 2 seconds
    public void checkStoppedTasks() {
        if (runningTasks.isEmpty())
            return;

        for (Long instanceId : runningTasks.keySet()) {
            ExecutorTaskInstance instance = taskInstanceMapper.selectById(instanceId);
            // 如果数据库中状态已变更为 STOPPED，说明用户在页面上点击了停止
            if (instance != null && "STOPPED".equals(instance.getStatus())) {
                java.util.concurrent.Future<?> future = runningTasks.get(instanceId);
                if (future != null && !future.isDone() && !future.isCancelled()) {
                    log.info("Stopping task instance {} as requested", instanceId);
                    future.cancel(true); // 强行中断线程
                }
            }
        }
    }

    /**
     * 同步影子任务 (DEPENDENT 节点) 状态的逻辑
     * 影子任务本身不执行任何具体脚本，它镜像上游任务的状态
     */
    @Scheduled(fixedDelay = 2000)
    public void syncShadowTasks() {
        // 1. 查找所有处于活跃状态（非终态）的影子任务
        QueryWrapper<ExecutorTaskInstance> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("task_type", "DEPENDENT");
        queryWrapper.in("status", ExecutorTaskInstance.STATUS_PENDING, ExecutorTaskInstance.STATUS_WAITING,
                ExecutorTaskInstance.STATUS_RUNNING);
        List<ExecutorTaskInstance> shadowTasks = taskInstanceMapper.selectList(queryWrapper);

        for (ExecutorTaskInstance shadow : shadowTasks) {
            // 2. 确定上游依赖项
            QueryWrapper<TaskDependency> depWrapper = new QueryWrapper<>();
            depWrapper.eq("task_id", shadow.getTaskId());
            List<TaskDependency> deps = taskDependencyMapper.selectList(depWrapper);

            if (deps.isEmpty())
                continue;

            // 获取第一个基准上游任务ID
            String upstreamTaskId = deps.get(0).getPreTaskId();

            // 3. 查找同业务日期的上游任务实例
            QueryWrapper<ExecutorTaskInstance> upstreamWrapper = new QueryWrapper<>();
            upstreamWrapper.eq("task_id", upstreamTaskId);
            upstreamWrapper.eq("data_date", shadow.getDataDate());
            ExecutorTaskInstance upstream = taskInstanceMapper.selectOne(upstreamWrapper);

            if (upstream == null)
                continue;

            boolean changed = false;
            String newStatus = shadow.getStatus();

            // 4. 镜像上游状态
            String upstreamStatus = upstream.getStatus();

            if (ExecutorTaskInstance.STATUS_WAITING.equals(upstreamStatus)) {
                if (!ExecutorTaskInstance.STATUS_WAITING.equals(shadow.getStatus())) {
                    newStatus = ExecutorTaskInstance.STATUS_WAITING;
                    changed = true;
                }
            } else if (ExecutorTaskInstance.STATUS_RUNNING.equals(upstreamStatus)) {
                if (!ExecutorTaskInstance.STATUS_RUNNING.equals(shadow.getStatus())) {
                    newStatus = ExecutorTaskInstance.STATUS_RUNNING;
                    if (shadow.getStartTime() == null) {
                        shadow.setStartTime(upstream.getStartTime());
                    }
                    changed = true;
                }
            } else if (ExecutorTaskInstance.STATUS_SUCCESS.equals(upstreamStatus)
                    || ExecutorTaskInstance.STATUS_FORCE_SUCCESS.equals(upstreamStatus)) {
                if (!ExecutorTaskInstance.STATUS_SUCCESS.equals(shadow.getStatus())
                        && !ExecutorTaskInstance.STATUS_FORCE_SUCCESS.equals(shadow.getStatus())) {
                    newStatus = ExecutorTaskInstance.STATUS_SUCCESS;
                    shadow.setEndTime(upstream.getEndTime());
                    shadow.setLogContent("Shadow Task: Upstream " + upstreamTaskId + " Succeeded.");
                    changed = true;
                }
            } else if (ExecutorTaskInstance.STATUS_FAIL.equals(upstreamStatus)) {
                if (!ExecutorTaskInstance.STATUS_FAIL.equals(shadow.getStatus())) {
                    newStatus = ExecutorTaskInstance.STATUS_FAIL;
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

                // 如果状态同步为成功，则触发后续任务
                if (ExecutorTaskInstance.STATUS_SUCCESS.equals(newStatus)) {
                    checkDownstreamTasks(shadow);
                }
            }
        }
    }

    /**
     * 单个任务实例的执行流程
     */
    private void executeTask(ExecutorTaskInstance instance) {
        try {
            log.info("Executing task instance: {} (TaskID: {}, Type: {}, Date: {})",
                    instance.getId(), instance.getTaskId(), instance.getTaskType(), instance.getDataDate());

            // 1. 获取对应的任务处理器实现 (根据 taskType 路由)
            com.example.executor.urgs_executor.handler.TaskHandler handler = taskHandlerFactory
                    .getHandler(instance.getTaskType());

            if (handler == null) {
                throw new RuntimeException("No handler found for task type: " + instance.getTaskType());
            }

            // 2. 调用具体的 Handler 执行逻辑
            String logContent = handler.execute(instance);

            // 3. 执行成功：更新状态并记录日志
            instance.setStatus(ExecutorTaskInstance.STATUS_SUCCESS);
            instance.setEndTime(LocalDateTime.now());
            instance.setLogContent(logContent);
            taskInstanceMapper.updateById(instance);

            log.info("Task instance {} completed successfully", instance.getId());

            // 4. 递归检查并触发后续依赖任务
            checkDownstreamTasks(instance);

        } catch (InterruptedException e) {
            log.warn("Task instance {} execution interrupted (STOPPED)", instance.getId());
            // 此时该实例可能已被 API 置为 STOPPED 状态，此处不做额外更新。
        } catch (Exception e) {
            // 如果是由 RuntimeException 包装的中断异常，也不做失败处理（视为停止）
            if (e instanceof RuntimeException && e.getCause() instanceof InterruptedException) {
                log.warn("Task instance {} execution interrupted (STOPPED)", instance.getId());
                return;
            }

            log.error("Task instance {} failed", instance.getId(), e);

            // 失败处理逻辑：更新状态为 FAIL
            ExecutorTaskInstance current = taskInstanceMapper.selectById(instance.getId());
            // 确保不会覆盖用户的“强行停止”状态
            if (!"STOPPED".equals(current.getStatus())) {
                instance.setStatus(ExecutorTaskInstance.STATUS_FAIL);
                instance.setEndTime(LocalDateTime.now());

                // 获取异常堆栈信息
                java.io.StringWriter sw = new java.io.StringWriter();
                java.io.PrintWriter pw = new java.io.PrintWriter(sw);
                e.printStackTrace(pw);
                String stackTrace = sw.toString();

                // 字段长度保护（截断过长的堆栈防止数据库字段溢出）
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

            // 5. 自动在系统中登记问题单 (Auto Issue Register)
            try {
                registerIssue(instance, e);
            } catch (Exception issueEx) {
                log.error("Failed to auto-register issue for task {}", instance.getId(), issueEx);
            }
        } finally {
            // 从当前运行队列移除
            runningTasks.remove(instance.getId());
        }
    }

    /**
     * 实现故障自动登记为问题单的机制
     */
    private void registerIssue(ExecutorTaskInstance instance, Exception e) {
        String taskId = instance.getTaskId();
        String dataDate = instance.getDataDate();

        // 1. 幂等性检查：避免为同一个任务实例创建多个重复的问题单
        QueryWrapper<Issue> checkWrapper = new QueryWrapper<>();
        checkWrapper.like("description", "实例ID: " + instance.getId());
        if (issueMapper.selectCount(checkWrapper) > 0) {
            log.info("Issue already exists for instance {}", instance.getId());
            return;
        }

        // 同时检查该任务和业务日期组合是否已存在相关问题单，遵循“一任务一日期一单”原则
        List<Issue> existingIssues = issueMapper
                .selectList(new QueryWrapper<Issue>().like("description", "任务ID: " + taskId));
        boolean exists = existingIssues.stream()
                .anyMatch(issue -> (issue.getTitle() != null && issue.getTitle().contains(dataDate)) ||
                        (issue.getDescription() != null && issue.getDescription().contains(dataDate)));

        if (exists) {
            log.info("Issue already exists for task {} date {}", taskId, dataDate);
            return;
        }

        // 2. 补充业务上下文元数据（所属系统、负责人等）
        String taskName = taskId;
        Task task = taskMapper.selectById(taskId);
        if (task != null)
            taskName = task.getName();

        String wfName = "Unknown";
        String owner = "Admin";

        // 通过工作流定义内容扫描该任务所属的父级工作流
        List<Workflow> workflows = workflowMapper.selectList(null);
        for (Workflow wf : workflows) {
            if (wf.getContent() != null && wf.getContent().contains(taskId)) {
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

        // 3. 构建并保存问题单对象
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
            stack = stack.substring(0, 2000) + "..."; // 限制描述字段长度

        desc.append("异常信息:\n").append(stack);

        issue.setDescription(desc.toString());
        issue.setCreateTime(LocalDateTime.now());
        issue.setUpdateTime(LocalDateTime.now());
        issue.setCreateBy("System");

        issueMapper.insert(issue);
        log.info("Auto-registered issue for task instance {}", instance.getId());
    }

    /**
     * 当一个任务实例运行成功后，检查并尝试通过其下游依赖项
     */
    private void checkDownstreamTasks(ExecutorTaskInstance completedInstance) {
        // 1. 查找所有以该任务为前置依赖的下游任务
        QueryWrapper<TaskDependency> depWrapper = new QueryWrapper<>();
        depWrapper.eq("pre_task_id", completedInstance.getTaskId());
        List<TaskDependency> downstreamDeps = taskDependencyMapper.selectList(depWrapper);

        for (TaskDependency dep : downstreamDeps) {
            String downstreamTaskId = dep.getTaskId();

            // 2. 找到同业务日期的下游任务实例
            QueryWrapper<ExecutorTaskInstance> instanceWrapper = new QueryWrapper<>();
            instanceWrapper.eq("task_id", downstreamTaskId);
            instanceWrapper.eq("data_date", completedInstance.getDataDate());
            ExecutorTaskInstance downstreamInstance = taskInstanceMapper.selectOne(instanceWrapper);

            // 如果下游任务目前处于 PENDING（等待依赖）状态
            if (downstreamInstance != null
                    && ExecutorTaskInstance.STATUS_PENDING.equals(downstreamInstance.getStatus())) {
                // 3. 递归检查该下游任务的所有上游依赖是否都已达成
                if (areAllDependenciesMet(downstreamTaskId, completedInstance.getDataDate())) {
                    // 满足条件，将其状态提升至 WAITING，等待调度执行
                    downstreamInstance.setStatus(ExecutorTaskInstance.STATUS_WAITING);
                    taskInstanceMapper.updateById(downstreamInstance);
                    log.info("Downstream task {} promoted to WAITING", downstreamInstance.getId());
                }
            }
        }
    }

    /**
     * 判断一个任务在特定业务日期的所有上游依赖是否已经成功执行
     */
    private boolean areAllDependenciesMet(String taskId, String dataDate) {
        // 获取所有配置的上游依赖关系
        QueryWrapper<TaskDependency> upstreamWrapper = new QueryWrapper<>();
        upstreamWrapper.eq("task_id", taskId);
        List<TaskDependency> upstreamDeps = taskDependencyMapper.selectList(upstreamWrapper);

        for (TaskDependency dep : upstreamDeps) {
            // 检查每个上游任务的实例状态
            QueryWrapper<ExecutorTaskInstance> preInstanceWrapper = new QueryWrapper<>();
            preInstanceWrapper.eq("task_id", dep.getPreTaskId());
            preInstanceWrapper.eq("data_date", dataDate);
            ExecutorTaskInstance preInstance = taskInstanceMapper.selectOne(preInstanceWrapper);

            // 如果上游实例尚不存在，或处于非成功状态，则返回 false
            if (preInstance == null) {
                return false;
            }

            if (!ExecutorTaskInstance.STATUS_SUCCESS.equals(preInstance.getStatus()) &&
                    !ExecutorTaskInstance.STATUS_FORCE_SUCCESS.equals(preInstance.getStatus())) {
                return false;
            }
        }
        return true;
    }
}
