package com.example.executor.quartz.task;

import com.example.executor.quartz.dao.QuartzTaskDao;
import com.example.executor.quartz.domain.entity.QuartzTaskEntity;
import com.example.executor.quartz.service.ExecutorTaskService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

@Slf4j
@Component
public class DependencyCheckTask {

    @Autowired
    private ExecutorTaskService executorTaskService;

    @Autowired
    private QuartzTaskDao quartzTaskDao;

    @Scheduled(fixedDelay = 3000, initialDelay = 10000)
    public void checkDependencies() {
        try {
            List<QuartzTaskEntity> readyTasks = quartzTaskDao.queryReadyWaitingTasks();
            if (readyTasks == null || readyTasks.isEmpty()) {
                return;
            }
            for (QuartzTaskEntity task : readyTasks) {
                executorTaskService.submitTaskToPool(task, task.getDataDate());
            }
        } catch (Exception e) {
            log.error("Dependency check failed", e);
        }
    }
}
