package com.example.urgs_api.workflow.service;

import org.quartz.Job;
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class WorkflowJob implements Job {
    private static final Logger log = LoggerFactory.getLogger(WorkflowJob.class);

    @Override
    public void execute(JobExecutionContext context) throws JobExecutionException {
        String jobName = context.getJobDetail().getKey().getName();
        String batchId = context.getMergedJobDataMap().getString("batchId");

        // If Root Node, generate batchId if missing
        if (batchId == null) {
            batchId = java.time.format.DateTimeFormatter.ofPattern("yyyyMMddHHmmss")
                    .format(java.time.LocalDateTime.now());
            context.getJobDetail().getJobDataMap().put("batchId", batchId);
        }

        log.info("Executing Job: {}, Batch: {}", jobName, batchId);

        // Actual task logic would go here (Shell, HTTP, etc.)
        try {
            Thread.sleep(1000); // Simulate work
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
