package com.example.executor.quartz.service;

import com.example.executor.quartz.domain.dto.ExecutorPoolStatsDTO;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class TaskExecutorPoolTest {

    private TaskExecutorPool pool;

    @AfterEach
    void tearDown() {
        if (pool != null) {
            pool.shutdown();
        }
    }

    @Test
    void separatesRunningAndQueuedTaskKeys() throws Exception {
        pool = new TaskExecutorPool(1, 2);
        CountDownLatch activeStarted = new CountDownLatch(1);
        CountDownLatch releaseActive = new CountDownLatch(1);

        assertTrue(pool.submitTask("active-task", () -> await(activeStarted, releaseActive)));
        assertTrue(activeStarted.await(2, TimeUnit.SECONDS));
        assertTrue(pool.submitTask("queued-task", () -> { }));

        awaitStats(stats -> stats.activeCount() == 1 && stats.queueSize() == 1);
        ExecutorPoolStatsDTO stats = pool.getPoolStats();
        assertEquals(1, stats.activeCount());
        assertEquals(1, stats.queueSize());
        assertEquals(java.util.List.of("active-task"), stats.runningTaskKeys());
        assertEquals(java.util.List.of("queued-task"), stats.queuedTaskKeys());

        releaseActive.countDown();
        awaitStats(next -> next.activeCount() == 0 && next.queueSize() == 0);
    }

    @Test
    void cancelRemovesQueuedTaskFromSnapshot() throws Exception {
        pool = new TaskExecutorPool(1, 1);
        CountDownLatch activeStarted = new CountDownLatch(1);
        CountDownLatch releaseActive = new CountDownLatch(1);

        assertTrue(pool.submitTask("active-task", () -> await(activeStarted, releaseActive)));
        assertTrue(activeStarted.await(2, TimeUnit.SECONDS));
        assertTrue(pool.submitTask("queued-task", () -> { }));
        awaitStats(stats -> stats.queueSize() == 1);

        assertTrue(pool.cancelTask("queued-task"));
        awaitStats(stats -> stats.queueSize() == 0);
        assertFalse(pool.hasTask("queued-task"));
        assertTrue(pool.getPoolStats().queuedTaskKeys().isEmpty());

        releaseActive.countDown();
    }

    @Test
    void rejectsDuplicateTaskKeyUntilOriginalCompletes() throws Exception {
        pool = new TaskExecutorPool(1, 1);
        CountDownLatch activeStarted = new CountDownLatch(1);
        CountDownLatch releaseActive = new CountDownLatch(1);

        assertTrue(pool.submitTask("same-task", () -> await(activeStarted, releaseActive)));
        assertTrue(activeStarted.await(2, TimeUnit.SECONDS));
        assertFalse(pool.submitTask("same-task", () -> { }));

        releaseActive.countDown();
        awaitStats(stats -> !pool.hasTask("same-task"));
        assertTrue(pool.submitTask("same-task", () -> { }));
    }

    @Test
    void closesResourceRegisteredAfterTaskCompletion() throws Exception {
        pool = new TaskExecutorPool(1, 1);
        AtomicBoolean closed = new AtomicBoolean(false);

        assertTrue(pool.submitTask("completed-task", () -> { }));
        awaitStats(stats -> !pool.hasTask("completed-task"));
        pool.registerResource("completed-task", () -> closed.set(true));

        assertTrue(closed.get());
    }

    @Test
    void cancelClosesRegisteredResourceAndRemovesTask() throws Exception {
        pool = new TaskExecutorPool(1, 1);
        CountDownLatch activeStarted = new CountDownLatch(1);
        CountDownLatch releaseActive = new CountDownLatch(1);
        AtomicBoolean closed = new AtomicBoolean(false);

        assertTrue(pool.submitTask("active-task", () -> await(activeStarted, releaseActive)));
        assertTrue(activeStarted.await(2, TimeUnit.SECONDS));
        pool.registerResource("active-task", () -> {
            closed.set(true);
            releaseActive.countDown();
        });

        assertTrue(pool.cancelTask("active-task"));
        assertTrue(closed.get());
        awaitStats(stats -> !pool.hasTask("active-task"));
    }

    @Test
    void keepsTaskKeyUntilCancelledTaskActuallyExits() throws Exception {
        pool = new TaskExecutorPool(1, 1);
        CountDownLatch activeStarted = new CountDownLatch(1);
        CountDownLatch releaseActive = new CountDownLatch(1);

        assertTrue(pool.submitTask("slow-cancel-task", () -> {
            activeStarted.countDown();
            while (releaseActive.getCount() > 0) {
                try {
                    releaseActive.await(50, TimeUnit.MILLISECONDS);
                } catch (InterruptedException ignored) {
                    // Simulate a task implementation that needs time to react to cancellation.
                }
            }
        }));
        assertTrue(activeStarted.await(2, TimeUnit.SECONDS));

        assertTrue(pool.cancelTask("slow-cancel-task"));
        assertTrue(pool.hasTask("slow-cancel-task"));
        assertFalse(pool.submitTask("slow-cancel-task", () -> { }));

        releaseActive.countDown();
        awaitStats(stats -> !pool.hasTask("slow-cancel-task"));
        assertTrue(pool.submitTask("slow-cancel-task", () -> { }));
    }

    @Test
    void closesResourceRegisteredAfterCancellationWasRequested() throws Exception {
        pool = new TaskExecutorPool(1, 1);
        CountDownLatch taskStarted = new CountDownLatch(1);
        CountDownLatch allowResourceRegistration = new CountDownLatch(1);
        CountDownLatch resourceRegistered = new CountDownLatch(1);
        CountDownLatch releaseTask = new CountDownLatch(1);
        AtomicBoolean closed = new AtomicBoolean(false);

        assertTrue(pool.submitTask("registration-race-task", () -> {
            taskStarted.countDown();
            awaitIgnoringInterrupts(allowResourceRegistration);
            pool.registerResource("registration-race-task", () -> closed.set(true));
            resourceRegistered.countDown();
            awaitIgnoringInterrupts(releaseTask);
        }));
        assertTrue(taskStarted.await(2, TimeUnit.SECONDS));

        assertTrue(pool.cancelTask("registration-race-task"));
        allowResourceRegistration.countDown();
        assertTrue(resourceRegistered.await(2, TimeUnit.SECONDS));
        assertTrue(closed.get());

        releaseTask.countDown();
        awaitStats(stats -> !pool.hasTask("registration-race-task"));
    }

    private void awaitStats(java.util.function.Predicate<ExecutorPoolStatsDTO> condition) throws Exception {
        long deadline = System.nanoTime() + Duration.ofSeconds(2).toNanos();
        while (System.nanoTime() < deadline) {
            if (condition.test(pool.getPoolStats())) {
                return;
            }
            Thread.sleep(10);
        }
        throw new AssertionError("Timed out waiting for executor pool stats: " + pool.getPoolStats());
    }

    private static void await(CountDownLatch started, CountDownLatch release) {
        started.countDown();
        try {
            release.await(2, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private static void awaitIgnoringInterrupts(CountDownLatch latch) {
        boolean interrupted = false;
        while (latch.getCount() > 0) {
            try {
                latch.await(50, TimeUnit.MILLISECONDS);
            } catch (InterruptedException e) {
                interrupted = true;
            }
        }
        if (interrupted) {
            Thread.currentThread().interrupt();
        }
    }
}
