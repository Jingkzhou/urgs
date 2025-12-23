package com.example.urgs_api.workflow.listener;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.urgs_api.workflow.entity.JobDependency;
import com.example.urgs_api.workflow.entity.JobLog;
import com.example.urgs_api.workflow.repository.JobDependencyMapper;
import com.example.urgs_api.workflow.repository.JobLogMapper;
import org.quartz.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class GlobalJobListener implements JobListener {

    @Autowired
    private JobDependencyMapper jobDependencyMapper;

    @Autowired
    private JobLogMapper jobLogMapper;

    @Autowired
    private Scheduler scheduler;

    @Override
    public String getName() {
        return "GlobalWorkflowListener";
    }

    @Override
    public void jobToBeExecuted(JobExecutionContext context) {
    }

    @Override
    public void jobExecutionVetoed(JobExecutionContext context) {
    }

    @Override
    public void jobWasExecuted(JobExecutionContext context, JobExecutionException jobException) {
        String jobName = context.getJobDetail().getKey().getName();
        String batchId = context.getMergedJobDataMap().getString("batchId");

        // 1. Log Execution
        JobLog log = new JobLog();
        log.setJobName(jobName);
        log.setBatchId(batchId);
        log.setStatus(jobException == null ? 1 : 0);
        log.setCreateTime(java.time.LocalDateTime.now());
        jobLogMapper.insert(log);

        if (jobException != null)
            return; // Stop if failed

        // 2. Find Children
        List<JobDependency> children = jobDependencyMapper.selectList(
                new QueryWrapper<JobDependency>().eq("parent_job_name", jobName));

        // 3. Check Convergence for each child
        for (JobDependency child : children) {
            String childName = child.getChildJobName();

            // Find all parents of this child
            List<JobDependency> parents = jobDependencyMapper.selectList(
                    new QueryWrapper<JobDependency>().eq("child_job_name", childName));

            boolean allParentsFinished = true;
            for (JobDependency parent : parents) {
                Long count = jobLogMapper.selectCount(
                        new QueryWrapper<JobLog>()
                                .eq("job_name", parent.getParentJobName())
                                .eq("batch_id", batchId)
                                .eq("status", 1));
                if (count == 0) {
                    allParentsFinished = false;
                    break;
                }
            }

            // 4. Trigger Child if ready
            if (allParentsFinished) {
                try {
                    JobKey childKey = new JobKey(childName, context.getJobDetail().getKey().getGroup());
                    JobDataMap dataMap = new JobDataMap();
                    dataMap.put("batchId", batchId);
                    scheduler.triggerJob(childKey, dataMap);
                } catch (SchedulerException e) {
                    e.printStackTrace();
                }
            }
        }
    }
}
