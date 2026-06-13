package com.example.executor.quartz.service;

import com.example.executor.quartz.domain.dto.ExecutorPoolStatsDTO;
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

    private final int queueCapacity;
    private final ThreadPoolExecutor executor;
    private final ConcurrentHashMap<String, TrackingFutureTask> submittedTasks = new ConcurrentHashMap<>();
    private final ConcurrentHashMap.KeySetView<String, Boolean> activeTaskKeys = ConcurrentHashMap.newKeySet();

    private final ConcurrentHashMap<String, List<Closeable>> taskResources = new ConcurrentHashMap<>();

    public TaskExecutorPool(
            @Value("${task.executor.pool-size:500}") int poolSize,
            @Value("${task.executor.queue-capacity:10000}") int queueCapacity) {
        if (poolSize <= 0) {
            throw new IllegalArgumentException("task.executor.pool-size must be greater than 0");
        }
        if (queueCapacity <= 0) {
            throw new IllegalArgumentException("task.executor.queue-capacity must be greater than 0");
        }
        this.queueCapacity = queueCapacity;
        AtomicInteger threadNum = new AtomicInteger(1);
        this.executor = new ThreadPoolExecutor(
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
        if (submittedTasks.putIfAbsent(taskKey, futureTask) != null) {
            log.info("Task {} is already running, skip duplicate submit", taskKey);
            return false;
        }
        try {
            executor.execute(futureTask);
            return true;
        } catch (RejectedExecutionException e) {
            submittedTasks.remove(taskKey, futureTask);
            throw e;
        }
    }

    public void registerResource(String taskKey, Closeable resource) {
        TrackingFutureTask task = submittedTasks.get(taskKey);
        if (task == null) {
            closeResource(taskKey, resource);
            return;
        }

        boolean closeImmediately;
        synchronized (task) {
            closeImmediately = submittedTasks.get(taskKey) != task
                    || task.isDone()
                    || task.isCancellationRequested();
            if (!closeImmediately) {
                taskResources.computeIfAbsent(taskKey, key -> new CopyOnWriteArrayList<>()).add(resource);
            }
        }
        if (closeImmediately) {
            closeResource(taskKey, resource);
        }
    }

    public boolean cancelTask(String taskKey) {
        TrackingFutureTask futureTask = submittedTasks.get(taskKey);
        if (futureTask == null) {
            return false;
        }

        List<Closeable> resources;
        synchronized (futureTask) {
            if (submittedTasks.get(taskKey) != futureTask) {
                return false;
            }
            futureTask.requestCancellation();
            resources = taskResources.remove(taskKey);
        }
        if (resources != null) {
            for (Closeable resource : resources) {
                closeResource(taskKey, resource);
            }
        }

        boolean removedFromQueue = executor.remove(futureTask);
        boolean cancelled = futureTask.cancel(true);
        if (removedFromQueue) {
            cleanupTask(taskKey, futureTask);
        }
        return cancelled || futureTask.isDone();
    }

    public boolean isRunning(String taskKey) {
        return submittedTasks.containsKey(taskKey);
    }

    public boolean hasTask(String taskKey) {
        return submittedTasks.containsKey(taskKey);
    }

    public ExecutorPoolStatsDTO getPoolStats() {
        List<String> runningTaskKeys = new ArrayList<>(activeTaskKeys);
        Collections.sort(runningTaskKeys);
        List<String> queuedTaskKeys = executor.getQueue().stream()
                .filter(TrackingFutureTask.class::isInstance)
                .map(TrackingFutureTask.class::cast)
                .filter(task -> !task.isCancelled())
                .map(TrackingFutureTask::getTaskKey)
                .sorted()
                .toList();
        return new ExecutorPoolStatsDTO(
                runningTaskKeys.size(),
                executor.getPoolSize(),
                executor.getMaximumPoolSize(),
                queuedTaskKeys.size(),
                queueCapacity,
                executor.getCompletedTaskCount(),
                runningTaskKeys,
                queuedTaskKeys
        );
    }

    private void closeResource(String taskKey, Closeable resource) {
        try {
            resource.close();
        } catch (Exception e) {
            log.warn("Close resource failed, taskKey={}, error={}", taskKey, e.getMessage());
        }
    }

    private void cleanupTask(String taskKey, TrackingFutureTask task) {
        synchronized (task) {
            taskResources.remove(taskKey);
            submittedTasks.remove(taskKey, task);
        }
    }

    private class TrackingFutureTask extends FutureTask<Void> {

        private final String taskKey;
        private boolean cancellationRequested;

        private TrackingFutureTask(String taskKey, Runnable task) {
            super(task, null);
            this.taskKey = taskKey;
        }

        private String getTaskKey() {
            return taskKey;
        }

        private boolean isCancellationRequested() {
            return cancellationRequested;
        }

        private void requestCancellation() {
            cancellationRequested = true;
        }

        @Override
        public void run() {
            activeTaskKeys.add(taskKey);
            try {
                super.run();
            } finally {
                activeTaskKeys.remove(taskKey);
                cleanupTask(taskKey, this);
            }
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
