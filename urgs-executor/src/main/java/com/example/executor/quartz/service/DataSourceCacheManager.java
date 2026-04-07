package com.example.executor.quartz.service;

import com.alibaba.druid.pool.DruidDataSource;
import com.example.executor.datasource.ResolvedDataSourceConfig;
import jakarta.annotation.PreDestroy;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Component
public class DataSourceCacheManager {

    private final ConcurrentHashMap<String, DruidDataSource> cache = new ConcurrentHashMap<>();

    public DruidDataSource getOrCreate(ResolvedDataSourceConfig config) {
        if (config == null || config.getId() == null) {
            throw new IllegalArgumentException("数据源配置不能为空");
        }
        String key = String.valueOf(config.getId());
        return cache.computeIfAbsent(key, k -> {
            DruidDataSource ds = new DruidDataSource();
            ds.setUsername(config.getUsername());
            ds.setPassword(config.getPassword());
            ds.setUrl(config.getUrl());
            ds.setDriverClassName(config.getDriver());
            ds.setInitialSize(2);
            ds.setMinIdle(2);
            ds.setMaxActive(20);
            ds.setMaxWait(60000);
            ds.setTimeBetweenEvictionRunsMillis(60000);
            ds.setMinEvictableIdleTimeMillis(300000);
            ds.setValidationQuery("SELECT 1");
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
