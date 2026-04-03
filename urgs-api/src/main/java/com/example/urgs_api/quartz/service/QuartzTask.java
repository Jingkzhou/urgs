package net.lab1024.smartadmin.module.support.quartz.service;

import com.alibaba.druid.pool.DruidDataSource;
import lombok.extern.slf4j.Slf4j;
import net.lab1024.smartadmin.common.domain.ITask;
import net.lab1024.smartadmin.module.support.quartz.constant.QuartzConst;
import net.lab1024.smartadmin.module.support.quartz.constant.TaskResultEnum;
import net.lab1024.smartadmin.module.support.quartz.domain.entity.QuartzTaskEntity;
import net.lab1024.smartadmin.module.support.quartz.domain.entity.QuartzTaskLogEntity;
import net.lab1024.smartadmin.third.SmartApplicationContext;
import net.lab1024.smartadmin.util.SmartIPUtil;
import net.lab1024.smartadmin.util.SmartQuartzUtil;
import org.quartz.*;
import org.springframework.scheduling.quartz.QuartzJobBean;

import org.slf4j.MDC;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.Date;

/**
 * 已废弃 - 新架构使用 TaskDispatcherJob + TaskExecutorPool 替代。
 * 保留此类仅供参考，不再被调度器使用。
 *
 * @deprecated 使用 {@link TaskDispatcherJob} 替代
 */
@Slf4j
@Deprecated
public class QuartzTask extends QuartzJobBean implements InterruptableJob {

    private volatile  Thread thisThread;
    private DruidDataSource druidDataSource ;

    @Override
    protected void executeInternal(JobExecutionContext context) throws JobExecutionException {
        thisThread = Thread.currentThread();
        JobDetail jobDetail = context.getJobDetail();
        Object params = context.getMergedJobDataMap().get(QuartzConst.QUARTZ_PARAMS_KEY);
        JobKey jobKey = jobDetail.getKey();

        Long taskId = SmartQuartzUtil.getTaskIdByJobKey(jobKey);
        QuartzTaskService quartzTaskService = (QuartzTaskService) SmartApplicationContext.getBean("quartzTaskService");
        QuartzTaskEntity quartzTaskEntity = quartzTaskService.getByTaskId(taskId);
        String dataDate = (String) context.getMergedJobDataMap().get("dataDate");
        quartzTaskEntity.setDataDate(dataDate);

        // 设置 MDC traceId，贯穿整个任务执行链路
        String traceId = taskId + "-" + (dataDate != null ? dataDate : "none") + "-" + System.currentTimeMillis();
        MDC.put("traceId", traceId);
        log.info("[taskId={}][taskName={}][dataDate={}] Job开始执行, traceId={}", taskId, quartzTaskEntity.getTaskName(), dataDate, traceId);

        try {
            QuartzTaskLogService quartzTaskLogService = (QuartzTaskLogService) SmartApplicationContext.getBean("quartzTaskLogService");

            QuartzTaskLogEntity taskLogEntity = new QuartzTaskLogEntity();
            taskLogEntity.setTaskId(taskId);
            taskLogEntity.setIpAddress(SmartIPUtil.getLocalHostIP());
            if (quartzTaskEntity.getTaskType() == 2){
                druidDataSource = quartzTaskService.getDataSource(quartzTaskEntity);
            }
            try {
                taskLogEntity.setTaskName(quartzTaskEntity.getTaskName());
            } catch (Exception e) {
                log.error("[taskId={}] 设置任务名称异常", taskId, e);
            }
            String paramsStr = null;
            if (params != null) {
                paramsStr = params.toString();
                taskLogEntity.setTaskParams(paramsStr);
            }
            taskLogEntity.setUpdateTime(new Date());
            taskLogEntity.setCreateTime(new Date());
            //任务开始时间
            long startTime = System.currentTimeMillis();
            try {
                ITask taskClass = (ITask) SmartApplicationContext.getBean(quartzTaskEntity.getTaskBean());
                taskClass.execute(quartzTaskEntity, druidDataSource);
                taskLogEntity.setProcessStatus(TaskResultEnum.SUCCESS.getStatus());
            } catch (Exception e) {
                log.error("[taskId={}][taskName={}] 任务执行异常", taskId, quartzTaskEntity.getTaskName(), e);
                StringWriter sw = new StringWriter();
                PrintWriter pw = new PrintWriter(sw, true);
                e.printStackTrace(pw);
                pw.flush();
                sw.flush();
                taskLogEntity.setProcessStatus(TaskResultEnum.FAIL.getStatus());
                taskLogEntity.setProcessLog(sw.toString());
            } finally {
                long times = System.currentTimeMillis() - startTime;
                taskLogEntity.setProcessDuration(times);
                quartzTaskLogService.save(taskLogEntity);
                log.info("[taskId={}][taskName={}] Job执行完毕, 耗时={}ms, 状态={}", taskId, quartzTaskEntity.getTaskName(), times,
                        taskLogEntity.getProcessStatus() == TaskResultEnum.SUCCESS.getStatus() ? "成功" : "失败");
                // 关闭数据源，防止连接泄漏
                if (druidDataSource != null) {
                    try {
                        druidDataSource.close();
                    } catch (Exception e) {
                        log.error("[taskId={}] 关闭数据源异常", taskId, e);
                    }
                }
            }
        } finally {
            MDC.remove("traceId");
        }
    }

    @Override
    public void interrupt()  {
        try {
            if(this.druidDataSource != null ) {
                this.druidDataSource.close();
            }
            log.info("终止当前进程: thread={}", thisThread.getName());
            thisThread.interrupt();
        }catch (Exception e){
            log.error("终止进程异常, thread={}", thisThread != null ? thisThread.getName() : "null", e);
        }
    }
}
