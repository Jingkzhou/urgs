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
     * 当一个任务实例运行成功后，检查并尝试推动其下游依赖任务。
     */
    private void checkDownstreamTasks(ExecutorTaskInstance completedInstance) {
        promoteEligibleDownstream(completedInstance.getTaskId(), completedInstance.getDataDate(),
                new java.util.HashSet<>());
    }

    /**
     * 穿透模式：遍历 sys_task_dependency 找下游任务。
     * 遇到 DEPENDENT 节点时不创建实例，直接递归穿透到其下游真实任务。
     */
    private void promoteEligibleDownstream(String completedTaskId, String dataDate,
            java.util.Set<String> visited) {
        if (!visited.add(completedTaskId)) return; // 防循环

        QueryWrapper<TaskDependency> depWrapper = new QueryWrapper<>();
        depWrapper.eq("pre_task_id", completedTaskId);
        List<TaskDependency> downstreamDeps = taskDependencyMapper.selectList(depWrapper);

        for (TaskDependency dep : downstreamDeps) {
            String downstreamTaskId = dep.getTaskId();

            // 检查下游是否为 DEPENDENT → 穿透
            Task downstreamDef = taskMapper.selectById(downstreamTaskId);
            if (downstreamDef != null && "DEPENDENT".equals(downstreamDef.getType())) {
                promoteEligibleDownstream(downstreamTaskId, dataDate, visited);
                continue;
            }

            // 普通任务：PENDING → WAITING
            QueryWrapper<ExecutorTaskInstance> instanceWrapper = new QueryWrapper<>();
            instanceWrapper.eq("task_id", downstreamTaskId);
            instanceWrapper.eq("data_date", dataDate);
            ExecutorTaskInstance downstreamInstance = taskInstanceMapper.selectOne(instanceWrapper);

            if (downstreamInstance == null) continue;

            if (ExecutorTaskInstance.STATUS_PENDING.equals(downstreamInstance.getStatus())) {
                if (areAllDependenciesMet(downstreamTaskId, dataDate)) {
                    downstreamInstance.setStatus(ExecutorTaskInstance.STATUS_WAITING);
                    downstreamInstance.setUpdateTime(LocalDateTime.now());
                    taskInstanceMapper.updateById(downstreamInstance);
                    log.info("下游任务 {} 依赖已满足，状态提升为 WAITING", downstreamInstance.getId());
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
        QueryWrapper<ExecutorTaskInstance> preInstanceWrapper = new QueryWrapper<>();
        preInstanceWrapper.eq("task_id", preTaskId);
        preInstanceWrapper.eq("data_date", dataDate);
        ExecutorTaskInstance preInstance = taskInstanceMapper.selectOne(preInstanceWrapper);

        if (preInstance != null) {
            return ExecutorTaskInstance.STATUS_SUCCESS.equals(preInstance.getStatus())
                    || ExecutorTaskInstance.STATUS_FORCE_SUCCESS.equals(preInstance.getStatus());
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
}
