package com.example.executor.urgs_executor.config;

import com.example.executor.urgs_executor.job.TaskGeneratorJob;
import org.quartz.*;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class QuartzConfig {

    @Bean
    public JobDetail taskGeneratorJobDetail() {
        return JobBuilder.newJob(TaskGeneratorJob.class)
                .withIdentity("taskGeneratorJob")
                .storeDurably()
                .build();
    }

    @Bean
    public Trigger taskGeneratorJobTrigger() {
        SimpleScheduleBuilder scheduleBuilder = SimpleScheduleBuilder.simpleSchedule()
                .withIntervalInSeconds(60) // Run every minute
                .repeatForever();

        return TriggerBuilder.newTrigger()
                .forJob(taskGeneratorJobDetail())
                .withIdentity("taskGeneratorJobTrigger")
                .withSchedule(scheduleBuilder)
                .build();
    }
}
