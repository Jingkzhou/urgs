package com.example.urgs_api.config;

import com.example.urgs_api.workflow.listener.GlobalJobListener;
import org.quartz.Scheduler;
import org.quartz.SchedulerException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;

import jakarta.annotation.PostConstruct;

@Configuration
public class QuartzConfig {

    @Autowired
    private Scheduler scheduler;

    @Autowired
    private GlobalJobListener globalJobListener;

    @PostConstruct
    public void init() throws SchedulerException {
        scheduler.getListenerManager().addJobListener(globalJobListener);
    }
}
