package com.example.executor.quartz.service;

import com.alibaba.druid.pool.DruidDataSource;
import com.example.executor.quartz.constant.TaskStatusEnum;
import com.example.executor.quartz.domain.entity.QuartzTaskEntity;
import lombok.extern.slf4j.Slf4j;
import org.quartz.CronExpression;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.concurrent.locks.ReentrantLock;

@Slf4j
@Component
public class TaskDispatcherJob {

    @Autowired
    private ExecutorTaskService executorTaskService;

    @Autowired
    private TaskExecutorPool taskExecutorPool;

    @Autowired
    private DataSourceCacheManager dataSourceCacheManager;

    private volatile Date lastScanTime;

    private final ReentrantLock dispatchLock = new ReentrantLock();

    @PostConstruct
    public void init() {
        lastScanTime = new Date(System.currentTimeMillis() - 5 * 60_000);
        log.info("TaskDispatcher initialized, lastScanTime={}",
                new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(lastScanTime));
    }

    @Scheduled(cron = "0 * * * * ?")
    public void dispatch() {
        if (!dispatchLock.tryLock()) {
            log.warn("Previous dispatch cycle is still running, skip this cycle");
            return;
        }
        try {
            doDispatch();
        } finally {
            dispatchLock.unlock();
        }
    }

    private void doDispatch() {
        Date now = new Date();
        Date scanFrom = lastScanTime != null ? lastScanTime : new Date(now.getTime() - 60_000);
        List<QuartzTaskEntity> activeTasks = executorTaskService.queryAllActiveTasks();
        if (activeTasks == null || activeTasks.isEmpty()) {
            lastScanTime = now;
            return;
        }

        for (QuartzTaskEntity task : activeTasks) {
            try {
                if (TaskStatusEnum.PAUSE.getStatus().equals(task.getTaskStatus())) {
                    continue;
                }

                CronExpression cron = new CronExpression(task.getTaskCron());
                Date nextFire = cron.getNextValidTimeAfter(scanFrom);
                if (nextFire == null || nextFire.after(now)) {
                    continue;
                }

                String dataDate = calculateDataDate(task);
                String taskKey = task.getId() + "_" + dataDate;
                if (taskExecutorPool.isRunning(taskKey)) {
                    continue;
                }

                taskExecutorPool.submitTask(taskKey, () -> {
                    try {
                        DruidDataSource ds = task.getTaskType() != null && task.getTaskType() == 2
                                ? dataSourceCacheManager.getOrCreate(task)
                                : null;
                        executorTaskService.taskDispatch(task, dataDate, ds);
                    } catch (Exception e) {
                        log.error("Dispatch execute failed, taskId={}, dataDate={}", task.getId(), dataDate, e);
                    }
                });
            } catch (Exception e) {
                log.warn("Cron evaluate failed, taskId={}, cron={}", task.getId(), task.getTaskCron(), e);
            }
        }
        lastScanTime = now;
    }

    private String calculateDataDate(QuartzTaskEntity task) {
        Calendar calendar = Calendar.getInstance();
        Integer offset = task.getOffset() == null ? 0 : task.getOffset();
        calendar.add(Calendar.DATE, offset);
        return new SimpleDateFormat("yyyyMMdd").format(calendar.getTime());
    }
}
