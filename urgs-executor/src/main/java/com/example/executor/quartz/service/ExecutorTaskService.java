package com.example.executor.quartz.service;

import com.alibaba.druid.pool.DruidDataSource;
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
        String taskKey = buildTaskKey(task.getId(), dataDate);
        taskExecutorPool.submitTask(taskKey, () -> {
            try {
                // 需要数据源时在线程内懒获取，避免提交时阻塞
                DruidDataSource ds = isSqlTask(task) ? dataSourceCacheManager.getOrCreate(task) : null;
                TaskExecutor executor = createExecutor(task, ds);
                // 注册 cancel 资源：调用 cancelTask() 时会触发 executor.cancel()
                taskExecutorPool.registerResource(taskKey, executor::cancel);
                taskDispatch(task, dataDate, executor);
            } catch (Exception e) {
                log.error("{} task execute failed", taskTag(task, dataDate), e);
            }
        });
    }

    // ===== 内部调度核心 =====

    /**
     * 任务调度主流程：状态流转 + 依赖检查 + 执行 + 重试。
     */
    void taskDispatch(QuartzTaskEntity task, String dataDate, TaskExecutor executor) {
        // 已在运行或已成功则跳过（防止重复执行）
        Integer currentStatus = quartzTaskStatusDao.getStatusByPlanIdAndDate(task.getId(), dataDate);
        if (currentStatus != null
                && (TaskExeStatusEnum.RUNNING.getCode().equals(currentStatus)
                || TaskExeStatusEnum.SUCCESS.getCode().equals(currentStatus))) {
            log.info("{} already running/success, skip", taskTag(task, dataDate));
            return;
        }

        // 初始化状态记录
        quartzTaskStatusDao.deleteByPlanIdAndDataDate(task.getId(), dataDate);
        QuartzTaskStatusEntity status = buildStatus(task.getId(), dataDate,
                TaskExeStatusEnum.WAITING.getCode(), "等待执行");
        insertStatus(status);

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

        // 执行（含重试）
        Map<String, String> result = executeWithRetry(task, dataDate, executor, status);

        // 根据结果更新最终状态
        applyFinalStatus(status, result);
        updateStatus(status);
    }

    /**
     * 执行任务，失败时按 period 间隔重试最多 3 次。
     */
    private Map<String, String> executeWithRetry(QuartzTaskEntity task, String dataDate,
                                                  TaskExecutor executor,
                                                  QuartzTaskStatusEntity status) {
        Map<String, String> result = Collections.emptyMap();
        final int maxRetries = 3;
        try {
            result = executor.execute(task, dataDate);
            for (int retry = 1;
                 !isSuccess(result) && task.getPeriod() != null && retry <= maxRetries;
                 retry++) {
                log.warn("{} 执行失败，{}ms 后开始第 {}/{} 次重试，错误: {}",
                        taskTag(task, dataDate), task.getPeriod(), retry, maxRetries, result.get("msg"));
                Thread.sleep(task.getPeriod());
                status.setMsg(String.format("第%d/%d次重试，错误: %s",
                        retry, maxRetries, result.get("msg")));
                updateStatus(status);
                result = executor.execute(task, dataDate);
            }
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
            return failureResult("任务已被中断");
        } catch (Exception e) {
            log.error("{} dispatch error", taskTag(task, dataDate), e);
            return failureResult("执行异常: " + trimTo500(e.getMessage()));
        }
        return result;
    }

    // ===== 工厂方法 =====

    /**
     * 根据任务类型创建对应的执行器实例（每次新建，避免状态复用）。
     */
    private TaskExecutor createExecutor(QuartzTaskEntity task, DruidDataSource ds) {
        if (isSqlTask(task)) {
            return new SqlTaskExecutor(ds);
        }
        return new ShellScriptExecutor();
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

    private void updateStatus(QuartzTaskStatusEntity entity) {
        entity.setUpdateTime(new Date());
        if (TaskExeStatusEnum.RUNNING.getCode().equals(entity.getStatus())) {
            entity.setBeginTime(new Date());
        }
        if (TaskExeStatusEnum.FAILED.getCode().equals(entity.getStatus())
                || TaskExeStatusEnum.SUCCESS.getCode().equals(entity.getStatus())) {
            entity.setEndTime(new Date());
        }
        quartzTaskStatusDao.updateStatus(entity);
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
}
