package com.example.urgs_api.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.Executor;
import java.util.concurrent.ThreadPoolExecutor;

@Configuration
public class AiAsyncConfig {

    @Bean(name = "aiTaskExecutor")
    public Executor aiTaskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        // 核心线程数：根据 CPU 核心数调整，AI 任务耗时较长，不宜设置过大
        executor.setCorePoolSize(4);
        // 最大线程数：防止过多并发任务吃满资源
        executor.setMaxPoolSize(8);
        // 队列容量：允许堆积一定数量的任务
        executor.setQueueCapacity(200);
        // 线程前缀
        executor.setThreadNamePrefix("ai-task-");
        // 拒绝策略：由调用者所在线程执行（Backpressure 机制）
        executor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        executor.initialize();
        return executor;
    }
}
