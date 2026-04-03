package com.example.executor.quartz.task;

import com.example.executor.quartz.dao.QuartzTaskStatusDao;
import com.example.executor.quartz.domain.entity.QuartzTaskEntity;
import com.example.executor.quartz.domain.entity.QuartzTaskStatusEntity;
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
    private QuartzTaskStatusDao quartzTaskStatusDao;

    @Scheduled(fixedDelay = 30000, initialDelay = 10000)
    public void checkDependencies() {
        try {
            List<QuartzTaskStatusEntity> waitingList = quartzTaskStatusDao.getWaitingList();
            if (waitingList == null || waitingList.isEmpty()) {
                return;
            }
            for (QuartzTaskStatusEntity waitingStatus : waitingList) {
                QuartzTaskEntity task = executorTaskService.getByTaskId(waitingStatus.getPlanId());
                if (task == null) {
                    continue;
                }
                if (executorTaskService.checkPredecessors(task, waitingStatus.getDataDate())) {
                    executorTaskService.submitTaskToPool(task, waitingStatus.getDataDate());
                }
            }
        } catch (Exception e) {
            log.error("Dependency check failed", e);
        }
    }
}
