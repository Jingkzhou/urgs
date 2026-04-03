package net.lab1024.smartadmin.module.support.quartz.service;

import com.alibaba.druid.pool.DruidDataSource;
import lombok.extern.slf4j.Slf4j;
import net.lab1024.smartadmin.module.support.quartz.constant.TaskStatusEnum;
import net.lab1024.smartadmin.module.support.quartz.domain.entity.QuartzTaskEntity;
import org.quartz.CronExpression;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.concurrent.locks.ReentrantLock;

/**
 * 任务调度扫描器
 * 每分钟执行一次，扫描 t_quartz_task 表中所有活跃任务，
 * 评估 cron 表达式是否到期，到期的任务提交到 TaskExecutorPool 执行。
 *
 * 使用 Spring @Scheduled 替代 Quartz Job，避免 JDBC JobStore 集群问题。
 *
 * 防漏任务机制：
 * 1. lastScanTime 动态回溯窗口 —— 每次从上次扫描时间点开始评估 cron，窗口连续无间隙
 * 2. ReentrantLock 防并发重入 —— 多线程调度器下防止 dispatch() 并发执行
 * 3. @PostConstruct 启动回溯 5 分钟 —— 覆盖应用重启期间可能遗漏的任务
 */
@Slf4j
@Component
public class TaskDispatcherJob {

    @Autowired
    private QuartzTaskService quartzTaskService;

    @Autowired
    private TaskExecutorPool taskExecutorPool;

    @Autowired
    private DataSourceCacheManager dataSourceCacheManager;

    /**
     * 记录上一次扫描完成的时间戳，用于计算下次扫描的回溯窗口起点。
     * 使用 volatile 保证多线程可见性（多线程调度器场景下）。
     *
     * 核心作用：替代固定的 "now - 60秒" 回溯窗口，确保即使某次调度被跳过或延迟，
     * 下次扫描也能从上次扫描时间接续，不遗漏任何时间窗口内的任务。
     */
    private volatile Date lastScanTime;

    /**
     * 防止 dispatch() 并发执行的重入锁。
     *
     * 背景：配置多线程 TaskScheduler 后，如果上一次 dispatch() 还没结束，
     * 到了下一个整点调度器可能再次触发 dispatch()。
     * 使用 tryLock() 非阻塞跳过，配合 lastScanTime 确保跳过不会导致漏任务。
     */
    private final ReentrantLock dispatchLock = new ReentrantLock();

    /**
     * 应用启动时初始化 lastScanTime。
     * 回溯 5 分钟作为初始扫描起点，覆盖应用重启/部署期间可能遗漏的任务窗口。
     * 即使回溯范围内的任务已经执行过，也不会重复下发
     * （TaskExecutorPool.isRunning + taskDispatch reentry check 兜底）。
     */
    @PostConstruct
    public void init() {
        lastScanTime = new Date(System.currentTimeMillis() - 5 * 60_000);
        log.info("TaskDispatcher 初始化完成, 初始扫描起点 lastScanTime={}",
                new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(lastScanTime));
    }

    @Scheduled(cron = "0 * * * * ?")
    public void dispatch() {
        // ===== 防并发重入：尝试获取锁，如果上一轮还在执行则直接跳过 =====
        // 不会漏任务：下一轮成功获取锁时，lastScanTime 会从上一轮的扫描起点接续
        if (!dispatchLock.tryLock()) {
            log.warn("====== TaskDispatcher 上一轮扫描仍在执行，本轮跳过（不会漏任务，下轮会补扫） ======");
            return;
        }
        try {
            doDispatch();
        } finally {
            dispatchLock.unlock();
        }
    }

    /**
     * 实际的扫描调度逻辑（从 dispatch() 中提取，便于锁管理）
     */
    private void doDispatch() {
        Date now = new Date();

        // ===== 动态回溯窗口：从上次扫描时间开始，而非固定回溯 1 分钟 =====
        // 这是防漏任务的核心：即使上一轮执行超过 1 分钟导致某次调度被跳过，
        // scanFrom 也会从上次扫描的时间点开始，覆盖中间所有被跳过的时间窗口。
        Date scanFrom = (lastScanTime != null) ? lastScanTime : new Date(now.getTime() - 60_000);

        String scanFromStr = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(scanFrom);
        String scanToStr = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(now);
        log.info("====== TaskDispatcher 开始扫描 [scanFrom={}, scanTo={}] ======", scanFromStr, scanToStr);

        // 1. 查询所有活跃任务 (status=0)
        List<QuartzTaskEntity> activeTasks = quartzTaskService.queryAllActiveTasks();
        if (activeTasks == null || activeTasks.isEmpty()) {
            log.info("====== TaskDispatcher 扫描结束: 无活跃任务 ======");
            // 即使无活跃任务也要更新 lastScanTime，保持窗口连续
            lastScanTime = now;
            return;
        }
        log.info("TaskDispatcher 加载活跃任务: {}个", activeTasks.size());

        // 输出线程池当前状态
        Map<String, Object> poolStats = taskExecutorPool.getPoolStats();
        log.info("TaskDispatcher 线程池状态: active={}, poolSize={}, queue={}, completed={}",
                poolStats.get("activeCount"), poolStats.get("poolSize"),
                poolStats.get("queueSize"), poolStats.get("completedTaskCount"));

        int dispatched = 0;
        int skippedPause = 0;
        int skippedRunning = 0;

        for (QuartzTaskEntity task : activeTasks) {
            try {
                // 跳过暂停状态的任务
                if (TaskStatusEnum.PAUSE.getStatus().equals(task.getTaskStatus())) {
                    skippedPause++;
                    log.debug("[taskId={}][taskName={}] 已暂停，跳过", task.getId(), task.getTaskName());
                    continue;
                }

                // 2. 评估 cron 表达式：该任务在 scanFrom ~ now 窗口内是否应该触发
                //    使用 scanFrom（上次扫描时间）替代固定的 oneMinuteAgo，确保窗口连续
                CronExpression cron = new CronExpression(task.getTaskCron());
                Date nextFire = cron.getNextValidTimeAfter(scanFrom);

                log.debug("[taskId={}][taskName={}] cron={}, 计划触发时间={}, 扫描窗口=[{} ~ {}]",
                        task.getId(), task.getTaskName(), task.getTaskCron(),
                        nextFire != null ? new SimpleDateFormat("HH:mm:ss").format(nextFire) : "null",
                        new SimpleDateFormat("HH:mm:ss").format(scanFrom),
                        new SimpleDateFormat("HH:mm:ss").format(now));

                // nextFire 落在 (scanFrom, now] 区间内，说明该任务应该被触发
                if (nextFire != null && !nextFire.after(now)) {
                    // 3. 计算 dataDate
                    String dataDate = calculateDataDate(task);
                    String taskKey = task.getId() + "_" + dataDate;

                    // 检查是否已在执行中
                    if (taskExecutorPool.isRunning(taskKey)) {
                        skippedRunning++;
                        log.info("[taskId={}][taskName={}] dataDate={} 已在执行中，跳过重复提交",
                                task.getId(), task.getTaskName(), dataDate);
                        continue;
                    }

                    log.info("[taskId={}][taskName={}] 触发执行, dataDate={}, taskType={}, taskKey={}",
                            task.getId(), task.getTaskName(), dataDate,
                            task.getTaskType() == 1 ? "脚本" : "存储过程", taskKey);

                    // 4. 提交到线程池执行
                    boolean submitted = taskExecutorPool.submitTask(taskKey, () -> {
                        try {
                            DruidDataSource ds = null;
                            if (task.getTaskType() == 2) {
                                ds = dataSourceCacheManager.getOrCreate(task);
                            }
                            quartzTaskService.taskDispatch(task, dataDate, ds);
                        } catch (Exception e) {
                            log.error("[taskId={}][taskName={}] 任务执行异常", task.getId(), task.getTaskName(), e);
                        }
                    });

                    if (submitted) {
                        dispatched++;
                        log.info("[taskId={}][taskName={}] 已提交到线程池, dataDate={}", task.getId(), task.getTaskName(), dataDate);
                    } else {
                        log.warn("[taskId={}][taskName={}] 提交线程池失败（可能队列已满）", task.getId(), task.getTaskName());
                    }
                }
            } catch (Exception e) {
                log.warn("[taskId={}][taskName={}] 评估cron异常, cron={}, error={}",
                        task.getId(), task.getTaskName(), task.getTaskCron(), e.getMessage());
            }
        }

        // ===== 更新 lastScanTime：标记本次扫描完成的时间点 =====
        // 下次调度时将从此时间点开始回溯，确保扫描窗口连续、无间隙
        lastScanTime = now;

        log.info("====== TaskDispatcher 扫描结束: 活跃={}, 触发={}, 跳过(暂停)={}, 跳过(执行中)={}, 下次scanFrom={} ======",
                activeTasks.size(), dispatched, skippedPause, skippedRunning,
                new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(lastScanTime));
    }

    /**
     * 根据任务的 offset 计算数据日期
     * 与 BSPTask 中的 dataDate 计算逻辑一致
     */
    private String calculateDataDate(QuartzTaskEntity task) {
        Calendar calendar = Calendar.getInstance();
        calendar.add(Calendar.DATE, task.getOffset());
        return new SimpleDateFormat("yyyyMMdd").format(calendar.getTime());
    }
}
