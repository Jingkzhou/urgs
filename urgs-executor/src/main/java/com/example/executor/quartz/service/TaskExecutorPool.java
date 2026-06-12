package com.example.executor.quartz.service;

import com.example.executor.quartz.domain.dto.ExecutorPoolStatsDTO;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import java.io.Closeable;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

@Slf4j
@Component
public class TaskExecutorPool {

    @Value("${task.executor.pool-size:500}")
    private int poolSize;

    @Value("${task.executor.queue-capacity:10000}")
    private int queueCapacity;

    private ThreadPoolExecutor executor;

    private final ConcurrentHashMap<String, Future<?>> runningTasks = new ConcurrentHashMap<>();

    private final ConcurrentHashMap<String, List<Closeable>> taskResources = new ConcurrentHashMap<>();

    @PostConstruct
    public void init() {
        AtomicInteger threadNum = new AtomicInteger(1);
        executor = new ThreadPoolExecutor(
                poolSize,
                poolSize,
                60,
                TimeUnit.SECONDS,
                new LinkedBlockingQueue<>(queueCapacity),
                r -> {
                    Thread t = new Thread(r);
                    t.setName("executor-task-" + threadNum.getAndIncrement());
                    t.setDaemon(false);
                    return t;
                },
                new ThreadPoolExecutor.CallerRunsPolicy()
        );
        executor.allowCoreThreadTimeOut(true);
        log.info("TaskExecutorPool initialized: core={}, max={}, queue={}",
                poolSize, poolSize, queueCapacity);
    }

    public boolean submitTask(String taskKey, Runnable task) {
        TrackingFutureTask futureTask = new TrackingFutureTask(taskKey, task);
        if (runningTasks.putIfAbsent(taskKey, futureTask) != null) {
            log.info("Task {} is already running, skip duplicate submit", taskKey);
            return false;
        }
        try {
            executor.execute(futureTask);
            return true;
        } catch (RejectedExecutionException e) {
            runningTasks.remove(taskKey, futureTask);
            throw e;
        }
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

    public boolean hasTask(String taskKey) {
        return runningTasks.containsKey(taskKey);
    }

    public ExecutorPoolStatsDTO getPoolStats() {
        List<String> runningTaskKeys = new ArrayList<>(runningTasks.keySet());
        Collections.sort(runningTaskKeys);
        return new ExecutorPoolStatsDTO(
                executor.getActiveCount(),
                executor.getPoolSize(),
                executor.getMaximumPoolSize(),
                executor.getQueue().size(),
                queueCapacity,
                executor.getCompletedTaskCount(),
                runningTaskKeys
        );
    }

    private class TrackingFutureTask extends FutureTask<Void> {

        private final String taskKey;

        private TrackingFutureTask(String taskKey, Runnable task) {
            super(task, null);
            this.taskKey = taskKey;
        }

        @Override
        protected void done() {
            runningTasks.remove(taskKey, this);
            taskResources.remove(taskKey);
        }
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
