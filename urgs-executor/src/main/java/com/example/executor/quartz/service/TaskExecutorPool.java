package com.example.executor.quartz.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;
import java.io.Closeable;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

@Slf4j
@Component
public class TaskExecutorPool {

    private ThreadPoolExecutor executor;

    private final ConcurrentHashMap<String, Future<?>> runningTasks = new ConcurrentHashMap<>();

    private final ConcurrentHashMap<String, List<Closeable>> taskResources = new ConcurrentHashMap<>();

    @PostConstruct
    public void init() {
        AtomicInteger threadNum = new AtomicInteger(1);
        executor = new ThreadPoolExecutor(
                200,
                200,
                60,
                TimeUnit.SECONDS,
                new LinkedBlockingQueue<>(2000),
                r -> {
                    Thread t = new Thread(r);
                    t.setName("executor-task-" + threadNum.getAndIncrement());
                    t.setDaemon(false);
                    return t;
                },
                new ThreadPoolExecutor.CallerRunsPolicy()
        );
        executor.allowCoreThreadTimeOut(true);
        log.info("TaskExecutorPool initialized: core=200, max=200, queue=2000");
    }

    public boolean submitTask(String taskKey, Runnable task) {
        if (runningTasks.containsKey(taskKey)) {
            log.info("Task {} is already running, skip duplicate submit", taskKey);
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

    public void registerResource(String taskKey, Closeable resource) {
        taskResources.computeIfAbsent(taskKey, k -> new CopyOnWriteArrayList<>()).add(resource);
    }

    public boolean cancelTask(String taskKey) {
        List<Closeable> resources = taskResources.remove(taskKey);
        if (resources != null) {
            for (Closeable resource : resources) {
                try {
                    resource.close();
                } catch (Exception e) {
                    log.warn("Close resource failed, taskKey={}, error={}", taskKey, e.getMessage());
                }
            }
        }

        Future<?> future = runningTasks.remove(taskKey);
        if (future == null) {
            return false;
        }
        return future.cancel(true);
    }

    public boolean isRunning(String taskKey) {
        return runningTasks.containsKey(taskKey);
    }

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
        log.info("TaskExecutorPool shutting down...");
        executor.shutdown();
        try {
            if (!executor.awaitTermination(60, TimeUnit.SECONDS)) {
                executor.shutdownNow();
            }
        } catch (InterruptedException e) {
            executor.shutdownNow();
            Thread.currentThread().interrupt();
        }
    }
}
