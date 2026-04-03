package com.example.executor.quartz.service;

import com.alibaba.druid.pool.DruidDataSource;
import com.example.executor.quartz.domain.entity.QuartzTaskEntity;
import jakarta.annotation.PreDestroy;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Component
public class DataSourceCacheManager {

    private final ConcurrentHashMap<String, DruidDataSource> cache = new ConcurrentHashMap<>();

    public DruidDataSource getOrCreate(QuartzTaskEntity task) {
        String key = task.getUrl() + "|" + task.getUsername();
        return cache.computeIfAbsent(key, k -> {
            DruidDataSource ds = new DruidDataSource();
            ds.setUsername(task.getUsername());
            ds.setPassword(task.getPassword());
            ds.setUrl(task.getUrl());
            ds.setDriverClassName(task.getDriver());
            ds.setInitialSize(2);
            ds.setMinIdle(2);
            ds.setMaxActive(20);
            ds.setMaxWait(60000);
            ds.setTimeBetweenEvictionRunsMillis(60000);
            ds.setMinEvictableIdleTimeMillis(300000);
            ds.setValidationQuery("SELECT 1 FROM DUAL");
            ds.setTestWhileIdle(true);
            ds.setTestOnBorrow(true);
            ds.setTestOnReturn(false);
            ds.setPoolPreparedStatements(true);
            log.info("Create shared data source: {}", key);
            return ds;
        });
    }

    @PreDestroy
    public void shutdown() {
        cache.values().forEach(ds -> {
            try {
                ds.close();
            } catch (Exception e) {
                log.warn("Close datasource failed: {}", e.getMessage());
            }
        });
        cache.clear();
    }
}
