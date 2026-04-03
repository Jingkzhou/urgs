package net.lab1024.smartadmin.module.support.quartz.task.test;

import lombok.extern.slf4j.Slf4j;
import net.lab1024.smartadmin.module.support.quartz.dao.QuartzTaskDao;
import net.lab1024.smartadmin.module.support.quartz.dao.QuartzTaskStatusDao;
import net.lab1024.smartadmin.module.support.quartz.domain.entity.QuartzTaskEntity;
import net.lab1024.smartadmin.module.support.quartz.domain.entity.QuartzTaskStatusEntity;
import net.lab1024.smartadmin.module.support.quartz.service.QuartzTaskService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * 依赖检查器
 * 每30秒扫描所有 status=1（等待中）的任务，检查前置依赖是否满足，满足则全部提交到线程池执行。
 * 使用 Spring @Scheduled(fixedDelay) 独立于 Quartz 运行，上一轮完成后才开始下一轮，不会重叠。
 */
@Slf4j
@Component
@EnableScheduling
public class DependencyCheckTask {

    @Autowired
    private QuartzTaskService quartzTaskService;

    @Autowired
    private QuartzTaskStatusDao quartzTaskStatusDao;

    @Autowired
    private QuartzTaskDao quartzTaskDao;

    @Scheduled(fixedDelay = 30000, initialDelay = 10000)
    public void checkDependencies() {
        try {
            List<QuartzTaskStatusEntity> waitingList = quartzTaskStatusDao.getWaitingList();
            if (waitingList == null || waitingList.isEmpty()) {
                return;
            }
            log.info("依赖检查器：发现{}个等待中的任务", waitingList.size());
            int triggered = 0;
            for (QuartzTaskStatusEntity waitingStatus : waitingList) {
                try {
                    QuartzTaskEntity task = quartzTaskDao.selectById(waitingStatus.getPlanId());
                    if (task == null) {
                        continue;
                    }
                    if (quartzTaskService.checkPredecessors(task, waitingStatus.getDataDate())) {
                        log.info("依赖检查器：触发任务序号：{}任务名称:{} dataDate={}", task.getId(), task.getTaskName(), waitingStatus.getDataDate());
                        quartzTaskService.submitTaskToPool(task, waitingStatus.getDataDate());
                        triggered++;
                    }
                } catch (Exception e) {
                    log.error("依赖检查器：处理任务planId={}异常", waitingStatus.getPlanId(), e);
                }
            }
            if (triggered > 0) {
                log.info("依赖检查器：本轮触发{}个任务", triggered);
            }
        } catch (Exception e) {
            log.error("依赖检查器执行异常", e);
        }
    }
}
