package net.lab1024.smartadmin.module.support.quartz.service;

import com.alibaba.druid.pool.DruidDataSource;
import lombok.extern.slf4j.Slf4j;
import net.lab1024.smartadmin.module.support.quartz.domain.entity.QuartzTaskEntity;
import org.springframework.stereotype.Component;

import javax.annotation.PreDestroy;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 数据源连接池缓存管理器
 * 按 url + username 共享 DruidDataSource，避免每个任务创建独立连接池。
 * 多个任务连接同一个数据库时复用同一个连接池。
 */
@Slf4j
@Component
public class DataSourceCacheManager {

    /**
     * Key = "url|username" -> 共享的 DruidDataSource
     */
    private final ConcurrentHashMap<String, DruidDataSource> cache = new ConcurrentHashMap<>();

    /**
     * 获取或创建共享数据源
     *
     * @param task 任务实体（包含 url, username, password, driver）
     * @return 共享的 DruidDataSource
     */
    public DruidDataSource getOrCreate(QuartzTaskEntity task) {
        String key = task.getUrl() + "|" + task.getUsername();
        return cache.computeIfAbsent(key, k -> {
            log.info("创建共享数据源: key={}", key);
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
            return ds;
        });
    }

    @PreDestroy
    public void shutdown() {
        log.info("关闭所有共享数据源, 数量={}", cache.size());
        cache.values().forEach(ds -> {
            try {
                ds.close();
            } catch (Exception e) {
                log.error("关闭数据源异常: {}", e.getMessage());
            }
        });
        cache.clear();
    }
}
