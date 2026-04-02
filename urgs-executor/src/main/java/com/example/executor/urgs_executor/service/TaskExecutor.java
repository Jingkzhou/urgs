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
            .newCachedThreadPool();
    private final java.util.concurrent.ConcurrentHashMap<Long, java.util.concurrent.Future<?>> runningTasks = new java.util.concurrent.ConcurrentHashMap<>();

    /**
     * 核心调度逻辑：轮询并执行待处理任务
     * 每3秒执行一次。采用乐观锁机制确保分布式环境下同一任务只被一个执行器节点获取。
     */
    @Scheduled(fixedDelay = 3000)
    public void pollAndExecute() {
        QueryWrapper<ExecutorTaskInstance> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("status", ExecutorTaskInstance.STATUS_WAITING);
        queryWrapper.ne("task_type", "DEPENDENT"); // 排除影子任务，影子任务通过状态同步处理
        queryWrapper.orderByDesc("priority");
        queryWrapper.orderByAsc("create_time");
        List<ExecutorTaskInstance> waitingTasks = taskInstanceMapper.selectList(queryWrapper);

        if (waitingTasks.isEmpty()) {
            return;
        }

        log.info("发现 {} 个待执行任务", waitingTasks.size());

        for (ExecutorTaskInstance instance : waitingTasks) {
            // 尝试获取分布式乐观锁 (基于数据库更新行数)
            int rows = taskInstanceMapper.tryLockTask(instance.getId());
            if (rows > 0) {
                log.info("成功锁定任务实例: {}", instance.getId());

                // 立即更新状态为 RUNNING，防止其他节点在极短时间内重复拉取
                instance.setStartTime(LocalDateTime.now());
                instance.setEndTime(null);
                instance.setStatus(ExecutorTaskInstance.STATUS_RUNNING);
                taskInstanceMapper.updateById(instance);

                // 异步提交至线程池执行
                java.util.concurrent.Future<?> future = taskThreadPool.submit(() -> executeTask(instance));
                runningTasks.put(instance.getId(), future);
            } else {
                log.debug("锁定任务实例失败（已被其他节点抢占）: {}", instance.getId());
            }
        }
    }

    /**
     * 检查并取消外部停止请求的任务
     */
    @Scheduled(fixedDelay = 2000)
    public void checkStoppedTasks() {
        if (runningTasks.isEmpty())
            return;

        for (Long instanceId : runningTasks.keySet()) {
            ExecutorTaskInstance instance = taskInstanceMapper.selectById(instanceId);
            // 如果数据库中状态已变更为 STOPPED，说明用户在页面上点击了停止
            if (instance != null && "STOPPED".equals(instance.getStatus())) {
                java.util.concurrent.Future<?> future = runningTasks.get(instanceId);
                if (future != null && !future.isDone() && !future.isCancelled()) {
                    log.info("收到停止请求，正在停止任务实例 {}", instanceId);
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
            // 2. 确定母体任务ID：优先从任务定义的 content JSON 中获取 taskId（跨工作流依赖），
            //    如果不存在则回退到 sys_task_dependency 表
            String upstreamTaskId = resolveUpstreamTaskId(shadow.getTaskId());
            if (upstreamTaskId == null) continue;

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
                    String ts = java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
                    shadow.setLogContent("[" + ts + "] 影子任务: 上游任务 " + upstreamTaskId + " 已成功");
                    changed = true;
                }
            } else if (ExecutorTaskInstance.STATUS_FAIL.equals(upstreamStatus)) {
                if (!ExecutorTaskInstance.STATUS_FAIL.equals(shadow.getStatus())) {
                    newStatus = ExecutorTaskInstance.STATUS_FAIL;
                    shadow.setEndTime(upstream.getEndTime());
                    String ts = java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
                    shadow.setLogContent("[" + ts + "] 影子任务: 上游任务 " + upstreamTaskId + " 已失败");
                    changed = true;
                }
            }

            if (changed) {
                shadow.setStatus(newStatus);
                shadow.setUpdateTime(LocalDateTime.now());
                taskInstanceMapper.updateById(shadow);
                log.info("影子任务 {} 状态已同步为 {}（上游: {}）", shadow.getId(), newStatus,
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
            log.info("开始执行任务实例: {}（任务ID: {}, 类型: {}, 数据日期: {}）",
                    instance.getId(), instance.getTaskId(), instance.getTaskType(), instance.getDataDate());

            // 1. 获取对应的任务处理器实现 (根据 taskType 路由)
            com.example.executor.urgs_executor.handler.TaskHandler handler = taskHandlerFactory
                    .getHandler(instance.getTaskType());

            if (handler == null) {
                throw new RuntimeException("未找到任务类型对应的处理器: " + instance.getTaskType());
            }

            // 2. 调用具体的 Handler 执行逻辑
            String logContent = handler.execute(instance);

            // 3. 执行成功：更新状态并记录日志
            instance.setStatus(ExecutorTaskInstance.STATUS_SUCCESS);
            instance.setEndTime(LocalDateTime.now());
            instance.setLogContent(logContent);
            taskInstanceMapper.updateById(instance);

            log.info("任务实例 {} 执行成功", instance.getId());

            // 4. 递归检查并触发后续依赖任务
            checkDownstreamTasks(instance);

        } catch (InterruptedException e) {
            log.warn("任务实例 {} 执行被中断（已停止）", instance.getId());
            // 此时该实例可能已被 API 置为 STOPPED 状态，此处不做额外更新。
        } catch (Exception e) {
            // 如果是由 RuntimeException 包装的中断异常，也不做失败处理（视为停止）
            if (e instanceof RuntimeException && e.getCause() instanceof InterruptedException) {
                log.warn("任务实例 {} 执行被中断（已停止）", instance.getId());
                return;
            }

            log.error("任务实例 {} 执行失败", instance.getId(), e);

            // 失败处理逻辑：更新状态为 FAIL
            ExecutorTaskInstance current = taskInstanceMapper.selectById(instance.getId());
            // 确保不会覆盖用户的"强行停止"状态
            if (!"STOPPED".equals(current.getStatus())) {
                instance.setStatus(ExecutorTaskInstance.STATUS_FAIL);
                instance.setEndTime(LocalDateTime.now());

                // 获取异常堆栈信息
                java.io.StringWriter sw = new java.io.StringWriter();
                java.io.PrintWriter pw = new java.io.PrintWriter(sw);
                e.printStackTrace(pw);
                String stackTrace = sw.toString();

                String timeErr = java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
                stackTrace = "[" + timeErr + "] 错误: 任务执行失败\n" + stackTrace;

                // 字段长度保护（截断过长的堆栈防止数据库字段溢出）
                if (stackTrace.length() > 10000) {
                    stackTrace = stackTrace.substring(0, 10000) + "\n... [已截断]";
                }
                String currentLog = instance.getLogContent();
                instance.setLogContent((currentLog != null ? currentLog + "\n" : "") + stackTrace);

                try {
                    log.info("正在保存任务实例 {} 的错误日志，日志长度: {}", instance.getId(),
                            stackTrace.length());
                    int rows = taskInstanceMapper.updateById(instance);
                    log.info("任务实例 {} 更新完成，影响行数: {}", instance.getId(), rows);
                } catch (Exception updateEx) {
                    log.error("更新任务实例 {} 的错误日志失败", instance.getId(), updateEx);
                }
            }

            // 5. 自动在系统中登记问题单
            try {
                registerIssue(instance, e);
            } catch (Exception issueEx) {
                log.error("自动登记问题单失败，任务: {}", instance.getId(), issueEx);
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
            log.info("任务实例 {} 的问题单已存在，跳过", instance.getId());
            return;
        }

        // 同时检查该任务和业务日期组合是否已存在相关问题单，遵循"一任务一日期一单"原则
        List<Issue> existingIssues = issueMapper
                .selectList(new QueryWrapper<Issue>().like("description", "任务ID: " + taskId));
        boolean exists = existingIssues.stream()
                .anyMatch(issue -> (issue.getTitle() != null && issue.getTitle().contains(dataDate)) ||
                        (issue.getDescription() != null && issue.getDescription().contains(dataDate)));

        if (exists) {
            log.info("任务 {} 数据日期 {} 的问题单已存在，跳过", taskId, dataDate);
            return;
        }

        // 2. 补充业务上下文元数据（所属系统、负责人等）
        String taskName = taskId;
        Task task = taskMapper.selectById(taskId);
        if (task != null)
            taskName = task.getName();

        String wfName = "未知";
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
            if (!"未知".equals(wfName))
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
        log.info("已自动登记问题单，任务实例: {}", instance.getId());
    }

    /**
     * 当一个任务实例运行成功后，检查并尝试通过其下游依赖项
     */
    private void checkDownstreamTasks(ExecutorTaskInstance completedInstance) {
        // 1. 查找 sys_task_dependency 中以该任务为前置依赖的下游任务
        QueryWrapper<TaskDependency> depWrapper = new QueryWrapper<>();
        depWrapper.eq("pre_task_id", completedInstance.getTaskId());
        List<TaskDependency> downstreamDeps = taskDependencyMapper.selectList(depWrapper);

        for (TaskDependency dep : downstreamDeps) {
            String downstreamTaskId = dep.getTaskId();

            QueryWrapper<ExecutorTaskInstance> instanceWrapper = new QueryWrapper<>();
            instanceWrapper.eq("task_id", downstreamTaskId);
            instanceWrapper.eq("data_date", completedInstance.getDataDate());
            ExecutorTaskInstance downstreamInstance = taskInstanceMapper.selectOne(instanceWrapper);

            if (downstreamInstance == null) continue;

            // DEPENDENT 影子任务：直接镜像上游状态并递归传播
            if ("DEPENDENT".equals(downstreamInstance.getTaskType())) {
                promoteShadowAndPropagate(downstreamInstance, completedInstance);
                continue;
            }

            // 普通任务：PENDING → WAITING
            if (ExecutorTaskInstance.STATUS_PENDING.equals(downstreamInstance.getStatus())) {
                if (areAllDependenciesMet(downstreamTaskId, completedInstance.getDataDate())) {
                    downstreamInstance.setStatus(ExecutorTaskInstance.STATUS_WAITING);
                    downstreamInstance.setUpdateTime(LocalDateTime.now());
                    taskInstanceMapper.updateById(downstreamInstance);
                    log.info("下游任务 {} 依赖已满足，状态提升为 WAITING", downstreamInstance.getId());
                }
            }
        }

        // 2. 查找通过 content JSON 引用了该任务的 DEPENDENT 影子任务（跨工作流依赖）
        promoteShadowTasksByContentRef(completedInstance);
    }

    /**
     * 查找 content JSON 中 taskId 指向已完成任务的 DEPENDENT 影子任务，同步状态并递归传播。
     * 这是跨工作流依赖的关键：DEPENDENT 影子任务的母体关系存储在 content JSON 的 taskId 字段中，
     * 而不在 sys_task_dependency 表中。
     */
    private void promoteShadowTasksByContentRef(ExecutorTaskInstance completedInstance) {
        try {
            // 查找所有 DEPENDENT 类型的任务定义
            QueryWrapper<Task> taskQuery = new QueryWrapper<>();
            taskQuery.eq("type", "DEPENDENT");
            List<Task> dependentTasks = taskMapper.selectList(taskQuery);

            ObjectMapper mapper = new ObjectMapper();
            for (Task depTask : dependentTasks) {
                if (depTask.getContent() == null) continue;
                try {
                    JsonNode contentNode = mapper.readTree(depTask.getContent());
                    JsonNode taskIdNode = contentNode.get("taskId");
                    if (taskIdNode == null) continue;

                    // 检查该影子任务是否引用了当前完成的任务
                    if (completedInstance.getTaskId().equals(taskIdNode.asText())) {
                        // 找到同业务日期的影子任务实例
                        QueryWrapper<ExecutorTaskInstance> shadowWrapper = new QueryWrapper<>();
                        shadowWrapper.eq("task_id", depTask.getId());
                        shadowWrapper.eq("data_date", completedInstance.getDataDate());
                        ExecutorTaskInstance shadowInstance = taskInstanceMapper.selectOne(shadowWrapper);

                        if (shadowInstance != null) {
                            promoteShadowAndPropagate(shadowInstance, completedInstance);
                        }
                    }
                } catch (Exception e) {
                    log.warn("解析 DEPENDENT 任务 {} 的 content JSON 失败: {}", depTask.getId(), e.getMessage());
                }
            }
        } catch (Exception e) {
            log.error("查找跨工作流 DEPENDENT 影子任务失败: {}", e.getMessage());
        }
    }

    /**
     * 将影子任务同步为 SUCCESS 并递归传播下游
     */
    private void promoteShadowAndPropagate(ExecutorTaskInstance shadowInstance,
            ExecutorTaskInstance completedInstance) {
        if (ExecutorTaskInstance.STATUS_SUCCESS.equals(shadowInstance.getStatus())
                || ExecutorTaskInstance.STATUS_FORCE_SUCCESS.equals(shadowInstance.getStatus())) {
            return; // 已经是成功状态，无需处理
        }
        shadowInstance.setStatus(ExecutorTaskInstance.STATUS_SUCCESS);
        shadowInstance.setEndTime(completedInstance.getEndTime());
        shadowInstance.setUpdateTime(LocalDateTime.now());
        String ts = LocalDateTime.now()
                .format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        shadowInstance.setLogContent(
                "[" + ts + "] 影子任务: 上游任务 " + completedInstance.getTaskId() + " 已成功");
        taskInstanceMapper.updateById(shadowInstance);
        log.info("影子任务 {} 已同步为 SUCCESS（上游: {}）", shadowInstance.getId(),
                completedInstance.getId());
        // 递归：继续传播影子任务的下游
        checkDownstreamTasks(shadowInstance);
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

    /**
     * 解析 DEPENDENT 影子任务的母体任务ID。
     * 优先从 sys_task 的 content JSON 中获取 taskId（跨工作流依赖），
     * 如果不存在则回退到 sys_task_dependency 表。
     */
    private String resolveUpstreamTaskId(String shadowTaskId) {
        // 1. 优先从任务定义的 content JSON 获取 taskId
        Task taskDef = taskMapper.selectById(shadowTaskId);
        if (taskDef != null && taskDef.getContent() != null) {
            try {
                ObjectMapper mapper = new ObjectMapper();
                JsonNode contentNode = mapper.readTree(taskDef.getContent());
                JsonNode taskIdNode = contentNode.get("taskId");
                if (taskIdNode != null && !taskIdNode.isNull() && !taskIdNode.asText().isEmpty()) {
                    return taskIdNode.asText();
                }
            } catch (Exception e) {
                log.warn("解析任务 {} 的 content JSON 失败: {}", shadowTaskId, e.getMessage());
            }
        }

        // 2. 回退：从 sys_task_dependency 获取
        QueryWrapper<TaskDependency> depWrapper = new QueryWrapper<>();
        depWrapper.eq("task_id", shadowTaskId);
        List<TaskDependency> deps = taskDependencyMapper.selectList(depWrapper);
        if (!deps.isEmpty()) {
            return deps.get(0).getPreTaskId();
        }

        return null;
    }
}
