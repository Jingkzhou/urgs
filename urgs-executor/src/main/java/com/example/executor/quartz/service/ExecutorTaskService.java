package com.example.executor.quartz.service;

import com.alibaba.druid.pool.DruidDataSource;
import com.example.executor.datasource.DataSourceConfigClient;
import com.example.executor.datasource.ResolvedDataSourceConfig;
import com.example.executor.notification.TaskNotificationService;
import com.example.executor.quartz.constant.TaskExeStatusEnum;
import com.example.executor.quartz.dao.QuartzTaskDao;
import com.example.executor.quartz.dao.QuartzTaskStatusDao;
import com.example.executor.quartz.domain.entity.QuartzTaskEntity;
import com.example.executor.quartz.domain.entity.QuartzTaskStatusEntity;
import com.example.executor.quartz.service.task.ShellScriptExecutor;
import com.example.executor.quartz.service.task.SqlTaskExecutor;
import com.example.executor.quartz.service.task.TaskExecutor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;

/**
 * 任务执行调度服务。
 * <p>
 * 负责：任务状态管理、依赖检查、重试逻辑、线程池提交。
 * 具体执行逻辑委托给 {@link TaskExecutor} 的具体实现：
 * <ul>
 *   <li>taskType=2 → {@link SqlTaskExecutor}（多段 SQL 脚本）</li>
 *   <li>taskType=1（默认）→ {@link ShellScriptExecutor}（Shell 脚本）</li>
 * </ul>
 */
@Slf4j
@Service
public class ExecutorTaskService {

    @Autowired
    private QuartzTaskDao quartzTaskDao;

    @Autowired
    private QuartzTaskStatusDao quartzTaskStatusDao;

    @Autowired
    private TaskExecutorPool taskExecutorPool;

    @Autowired
    private DataSourceCacheManager dataSourceCacheManager;

    @Autowired
    private TaskExecutionLogService taskExecutionLogService;

    @Autowired
    private DataSourceConfigClient dataSourceConfigClient;

    @Autowired
    private TaskNotificationService taskNotificationService;

    @Autowired
    private ProblemTransferClient problemTransferClient;

    // ===== 对外查询接口 =====

    public List<QuartzTaskEntity> queryAllActiveTasks() {
        return quartzTaskDao.queryActiveTasks();
    }

    public QuartzTaskEntity getByTaskId(Long taskId) {
        return quartzTaskDao.selectById(taskId);
    }

    public boolean isTaskRunning(Long planId, String dataDate) {
        return taskExecutorPool.hasTask(buildTaskKey(planId, dataDate));
    }

    public boolean stopTask(Long planId, String dataDate) {
        return taskExecutorPool.cancelTask(buildTaskKey(planId, dataDate));
    }

    public String validateTaskReadyForSubmit(QuartzTaskEntity task) {
        if (task == null) {
            return "任务不存在";
        }
        if (task.getDatasourceId() == null) {
            return "任务未绑定数据源，请先在任务配置中选择数据源";
        }
        ResolvedDataSourceConfig config;
        try {
            config = dataSourceConfigClient.getResolvedConfig(task.getDatasourceId());
        } catch (Exception e) {
            return "加载数据源配置失败: " + trimTo500(e.getMessage());
        }
        if (config == null || config.getId() == null) {
            return "数据源配置不存在或不可用，请检查任务绑定的数据源";
        }
        if (isSqlTask(task)) {
            if (isBlank(config.getUrl()) || isBlank(config.getDriver())) {
                return "SQL 任务数据源缺少 JDBC URL 或驱动配置";
            }
            return null;
        }
        if (isBlank(config.getHost()) || isBlank(config.getUsername())) {
            return "Shell 任务数据源缺少主机或用户名配置";
        }
        return null;
    }

    public boolean checkPredecessors(QuartzTaskEntity task, String dataDate) {
        List<Long> dependIds = quartzTaskDao.getPreTaskIdsByTaskId(task.getId());
        if (dependIds == null || dependIds.isEmpty()) {
            return true;
        }
        int finishCount = quartzTaskStatusDao.getFinishCount(dependIds, dataDate);
        return dependIds.size() == finishCount;
    }

    // ===== 任务提交 =====

    /**
     * 将任务提交到线程池异步执行。
     * 若同一 planId+dataDate 已在运行，则跳过（幂等）。
     */
    public void submitTaskToPool(QuartzTaskEntity task, String dataDate) {
        submitTaskToPool(task, dataDate, "schedule");
    }

    /**
     * 将任务提交到线程池异步执行。
     * 若同一 planId+dataDate 已在运行，则跳过（幂等）。
     */
    public void submitTaskToPool(QuartzTaskEntity task, String dataDate, String triggerType) {
        String taskKey = buildTaskKey(task.getId(), dataDate);
        String normalizedTriggerType = normalizeTriggerType(triggerType);
        taskExecutorPool.submitTask(taskKey, () -> {
            try {
                ResolvedDataSourceConfig resolvedDataSourceConfig = task.getDatasourceId() == null
                        ? null
                        : dataSourceConfigClient.getResolvedConfig(task.getDatasourceId());
                if (resolvedDataSourceConfig != null) {
                    log.info("{} resolved datasource: id={}, url={}, driver={}",
                            taskTag(task, dataDate),
                            resolvedDataSourceConfig.getId(),
                            resolvedDataSourceConfig.getUrl(),
                            resolvedDataSourceConfig.getDriver());
                }
                // 需要数据源时在线程内懒获取，避免提交时阻塞
                DruidDataSource ds = isSqlTask(task) ? dataSourceCacheManager.getOrCreate(resolvedDataSourceConfig) : null;
                TaskExecutor executor = createExecutor(task, ds, resolvedDataSourceConfig);
                // 注册 cancel 资源：调用 cancelTask() 时会触发 executor.cancel()
                taskExecutorPool.registerResource(taskKey, executor::cancel);
                taskDispatch(task, dataDate, executor, normalizedTriggerType);
            } catch (Exception e) {
                log.error("{} task execute failed", taskTag(task, dataDate), e);
                recordStartupFailure(task, dataDate, e);
            }
        });
    }

    // ===== 内部调度核心 =====

    /**
     * 任务调度主流程：状态流转 + 依赖检查 + 执行 + 重试。
     */
    void taskDispatch(QuartzTaskEntity task, String dataDate, TaskExecutor executor) {
        taskDispatch(task, dataDate, executor, "schedule");
    }

    /**
     * 任务调度主流程：状态流转 + 依赖检查 + 执行 + 重试。
     */
    void taskDispatch(QuartzTaskEntity task, String dataDate, TaskExecutor executor, String triggerType) {
        // 已在运行或已成功则跳过（防止重复执行）
        Integer currentStatus = quartzTaskStatusDao.getStatusByPlanIdAndDate(task.getId(), dataDate);
        if (currentStatus != null
                && (TaskExeStatusEnum.RUNNING.getCode().equals(currentStatus)
                || TaskExeStatusEnum.SUCCESS.getCode().equals(currentStatus))) {
            log.info("{} already running/success, skip", taskTag(task, dataDate));
            return;
        }

        // 初始化状态记录。重跑场景下 API 会先把同一实例重置为等待中，
        // 这里避免 DELETE+INSERT 和批量重跑/扫描线程争抢同一行锁。
        QuartzTaskStatusEntity status = buildStatus(task.getId(), dataDate,
                TaskExeStatusEnum.WAITING.getCode(), "等待执行");
        resetOrInsertStatus(status, currentStatus);

        // 依赖检查：前置任务未完成则等待
        if (!checkPredecessors(task, dataDate)) {
            status.setMsg("等待前置任务完成");
            updateStatus(status);
            return;
        }

        // 切换为执行中
        status.setStatus(TaskExeStatusEnum.RUNNING.getCode());
        status.setMsg("执行中");
        updateStatus(status);

        TaskExecutionLogService.ExecutionLogContext logContext = taskExecutionLogService.start(task, dataDate, triggerType);
        Consumer<String> logConsumer = line -> taskExecutionLogService.append(logContext, line);

        // 执行（含重试）
        Map<String, String> result = executeWithRetry(task, dataDate, executor, status, logConsumer);

        // 根据结果更新最终状态
        applyFinalStatus(status, result);
        updateStatus(status);
        if (shouldTransferFailedInstance(status)) {
            problemTransferClient.transferFailedInstance(task, status);
        }
        taskExecutionLogService.finish(logContext, isSuccess(result), status.getMsg());
        taskNotificationService.notifyTaskResult(task, status, logConsumer);
    }

    private String normalizeTriggerType(String triggerType) {
        if ("manual".equals(triggerType) || "rerun".equals(triggerType) || "schedule".equals(triggerType)) {
            return triggerType;
        }
        return "schedule";
    }

    /**
     * 执行任务，失败时按 period 间隔重试最多 3 次。
     */
    private Map<String, String> executeWithRetry(QuartzTaskEntity task, String dataDate,
                                                  TaskExecutor executor,
                                                  QuartzTaskStatusEntity status,
                                                  Consumer<String> logConsumer) {
        Map<String, String> result = Collections.emptyMap();
        final int maxRetries = 3;
        try {
            result = executor.execute(task, dataDate, logConsumer);
            for (int retry = 1;
                 !isSuccess(result) && task.getPeriod() != null && retry <= maxRetries;
                 retry++) {
                log.warn("{} 执行失败，{}ms 后开始第 {}/{} 次重试，错误: {}",
                        taskTag(task, dataDate), task.getPeriod(), retry, maxRetries, result.get("msg"));
                if (logConsumer != null) {
                    logConsumer.accept(String.format("[RETRY] 第%d/%d次重试，等待%dms，错误: %s",
                            retry, maxRetries, task.getPeriod(), trimTo500(result.get("msg"))));
                }
                Thread.sleep(task.getPeriod());
                status.setMsg(String.format("第%d/%d次重试，错误: %s",
                        retry, maxRetries, result.get("msg")));
                updateStatus(status);
                result = executor.execute(task, dataDate, logConsumer);
            }
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
            if (logConsumer != null) {
                logConsumer.accept("[ERROR] 任务执行线程被中断");
            }
            return failureResult("任务已被中断");
        } catch (Exception e) {
            log.error("{} dispatch error", taskTag(task, dataDate), e);
            if (logConsumer != null) {
                logConsumer.accept("[ERROR] 执行异常: " + trimTo500(e.getMessage()));
            }
            return failureResult("执行异常: " + trimTo500(e.getMessage()));
        }
        return result;
    }

    // ===== 工厂方法 =====

    /**
     * 根据任务类型创建对应的执行器实例（每次新建，避免状态复用）。
     */
    private TaskExecutor createExecutor(QuartzTaskEntity task, DruidDataSource ds, ResolvedDataSourceConfig resolvedDataSourceConfig) {
        if (isSqlTask(task)) {
            return new SqlTaskExecutor(ds);
        }
        return new ShellScriptExecutor(resolvedDataSourceConfig);
    }

    private boolean isSqlTask(QuartzTaskEntity task) {
        return task.getTaskType() != null && task.getTaskType() == 2;
    }

    // ===== 状态管理 =====

    private QuartzTaskStatusEntity buildStatus(Long planId, String dataDate, int statusCode, String msg) {
        QuartzTaskStatusEntity entity = new QuartzTaskStatusEntity();
        entity.setPlanId(planId);
        entity.setDataDate(dataDate);
        entity.setStatus(statusCode);
        entity.setMsg(msg);
        return entity;
    }

    private void insertStatus(QuartzTaskStatusEntity entity) {
        Date now = new Date();
        entity.setCreateTime(now);
        entity.setUpdateTime(now);
        quartzTaskStatusDao.insertStatus(entity);
    }

    private void resetOrInsertStatus(QuartzTaskStatusEntity entity, Integer currentStatus) {
        if (currentStatus == null) {
            insertStatus(entity);
            return;
        }
        if (TaskExeStatusEnum.WAITING.getCode().equals(currentStatus)) {
            return;
        }
        Date now = new Date();
        entity.setUpdateTime(now);
        quartzTaskStatusDao.resetStatusForDispatch(entity);
    }

    private void updateStatus(QuartzTaskStatusEntity entity) {
        Date now = new Date();
        entity.setUpdateTime(now);
        if (TaskExeStatusEnum.RUNNING.getCode().equals(entity.getStatus())) {
            entity.setBeginTime(now);
        }
        if (TaskExeStatusEnum.FAILED.getCode().equals(entity.getStatus())
                || TaskExeStatusEnum.SUCCESS.getCode().equals(entity.getStatus())) {
            entity.setEndTime(now);
        }
        quartzTaskStatusDao.updateStatus(entity);
    }

    private void recordStartupFailure(QuartzTaskEntity task, String dataDate, Exception e) {
        try {
            QuartzTaskStatusEntity status = buildStatus(
                    task.getId(),
                    dataDate,
                    TaskExeStatusEnum.FAILED.getCode(),
                    "任务启动失败: " + trimTo500(e.getMessage())
            );
            Date now = new Date();
            status.setBeginTime(now);
            status.setEndTime(now);
            Integer currentStatus = quartzTaskStatusDao.getStatusByPlanIdAndDate(task.getId(), dataDate);
            if (currentStatus == null) {
                insertStatus(status);
            } else {
                updateStatus(status);
            }
        } catch (Exception statusException) {
            log.warn("{} record startup failure status failed, error={}", taskTag(task, dataDate), statusException.getMessage());
        }
    }

    private void applyFinalStatus(QuartzTaskStatusEntity status, Map<String, String> result) {
        if (result == null || result.get("code") == null) {
            status.setStatus(TaskExeStatusEnum.FAILED.getCode());
            status.setMsg("执行器未返回结果");
        } else if (isSuccess(result)) {
            status.setStatus(TaskExeStatusEnum.SUCCESS.getCode());
            status.setMsg(result.get("msg"));
        } else {
            status.setStatus(TaskExeStatusEnum.FAILED.getCode());
            status.setMsg(trimTo500(result.get("msg")));
        }
    }

    // ===== 工具方法 =====

    private boolean isSuccess(Map<String, String> result) {
        return result != null && "0".equals(result.get("code"));
    }

    private boolean shouldTransferFailedInstance(QuartzTaskStatusEntity status) {
        if (!TaskExeStatusEnum.FAILED.getCode().equals(status.getStatus())) {
            return false;
        }
        String msg = status.getMsg();
        return msg == null
                || (!msg.contains("任务已被停止")
                && !msg.contains("任务已被中断")
                && !msg.contains("强制停止"));
    }

    private Map<String, String> failureResult(String msg) {
        return Map.of("code", "-1", "msg", msg);
    }

    private String buildTaskKey(Long planId, String dataDate) {
        return planId + "_" + dataDate;
    }

    private String taskTag(QuartzTaskEntity task, String dataDate) {
        return "[taskId=" + task.getId() + "][taskName=" + task.getTaskName() + "][dataDate=" + dataDate + "]";
    }

    private String trimTo500(String value) {
        if (value == null) return null;
        return value.length() > 500 ? value.substring(0, 500) : value;
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
