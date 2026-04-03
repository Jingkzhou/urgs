package net.lab1024.smartadmin.module.support.quartz.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;
import java.io.Closeable;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * 任务执行线程池
 * 替代 Quartz 线程池，统一管理所有任务的并发执行。
 * 支持防重复提交、任务取消（含强制关闭IO资源）、线程池状态监控。
 */
@Slf4j
@Component
public class TaskExecutorPool {

    private ThreadPoolExecutor executor;

    /**
     * 跟踪正在执行的任务，防止重复提交
     * key = "taskId_dataDate"
     */
    private final ConcurrentHashMap<String, Future<?>> runningTasks = new ConcurrentHashMap<>();

    /**
     * 跟踪任务关联的可关闭资源（SSH Session/Channel、JDBC Statement 等）
     * 停止任务时先关闭这些资源，使阻塞的IO操作立即抛异常退出
     * key = "taskId_dataDate"
     */
    private final ConcurrentHashMap<String, List<Closeable>> taskResources = new ConcurrentHashMap<>();

    @PostConstruct
    public void init() {
        AtomicInteger threadNum = new AtomicInteger(1);
        executor = new ThreadPoolExecutor(
                500,                                   // corePoolSize: 500线程并发处理任务
                500,                                   // maxPoolSize: 与core一致
                60, TimeUnit.SECONDS,                  // keepAliveTime: 空闲线程60秒回收
                new LinkedBlockingQueue<>(3000),       // 队列：超出500并发的任务排队
                r -> {
                    Thread t = new Thread(r);
                    t.setName("task-exec-" + threadNum.getAndIncrement());
                    t.setDaemon(false);
                    return t;
                },
                new ThreadPoolExecutor.CallerRunsPolicy()  // 队列满时由调用线程执行(背压)
        );
        executor.allowCoreThreadTimeOut(true);          // 空闲时core线程也回收，释放资源
        log.info("任务执行线程池初始化完成: core=500, max=500, queue=3000");
    }

    /**
     * 提交任务到线程池
     *
     * @param taskKey 任务唯一标识 (taskId_dataDate)
     * @param task    任务执行逻辑
     * @return true=成功提交, false=任务已在执行中
     */
    public boolean submitTask(String taskKey, Runnable task) {
        if (runningTasks.containsKey(taskKey)) {
            log.info("任务 {} 已在执行中，跳过重复提交", taskKey);
            return false;
        }
        Future<?> future = executor.submit(() -> {
            try {
                task.run();
            } finally {
                runningTasks.remove(taskKey);
                taskResources.remove(taskKey);
            }
        });
        runningTasks.put(taskKey, future);
        return true;
    }

    /**
     * 注册任务关联的可关闭资源（SSH Session、Channel、Statement 等）
     * 任务执行过程中调用，停止任务时会自动关闭这些资源
     */
    public void registerResource(String taskKey, Closeable resource) {
        taskResources.computeIfAbsent(taskKey, k -> new CopyOnWriteArrayList<>()).add(resource);
    }

    /**
     * 取消正在执行的任务
     * 1. 先关闭注册的IO资源（使阻塞的 readLine/execute 立即抛异常退出）
     * 2. 再中断线程（处理 sleep/wait 等可中断阻塞）
     *
     * @param taskKey 任务唯一标识
     * @return true=成功取消
     */
    public boolean cancelTask(String taskKey) {
        // 1. 先关闭IO资源，打断阻塞的IO操作
        List<Closeable> resources = taskResources.remove(taskKey);
        if (resources != null) {
            for (Closeable resource : resources) {
                try {
                    resource.close();
                    log.info("关闭任务 {} 的资源: {}", taskKey, resource.getClass().getSimpleName());
                } catch (Exception e) {
                    log.warn("关闭任务 {} 的资源异常: {}", taskKey, e.getMessage());
                }
            }
        }

        // 2. 再取消Future，中断线程
        Future<?> future = runningTasks.remove(taskKey);
        if (future != null) {
            boolean cancelled = future.cancel(true);
            log.info("取消任务 {}: {}", taskKey, cancelled ? "成功" : "失败");
            return cancelled;
        }
        log.info("取消任务 {}: 未找到运行中的任务", taskKey);
        return false;
    }

    /**
     * 检查任务是否正在执行
     */
    public boolean isRunning(String taskKey) {
        return runningTasks.containsKey(taskKey);
    }

    /**
     * 获取线程池运行状态（供监控使用）
     */
    public Map<String, Object> getPoolStats() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("activeCount", executor.getActiveCount());
        stats.put("poolSize", executor.getPoolSize());
        stats.put("queueSize", executor.getQueue().size());
        stats.put("completedTaskCount", executor.getCompletedTaskCount());
        stats.put("runningTaskKeys", runningTasks.size());
        return stats;
    }

    @PreDestroy
    public void shutdown() {
        log.info("任务执行线程池开始关闭...");
        executor.shutdown();
        try {
            if (!executor.awaitTermination(60, TimeUnit.SECONDS)) {
                executor.shutdownNow();
                log.warn("任务执行线程池强制关闭");
            }
        } catch (InterruptedException e) {
            executor.shutdownNow();
            Thread.currentThread().interrupt();
        }
        log.info("任务执行线程池已关闭");
    }
}
