package com.example.urgs_api.config;

import org.neo4j.driver.AuthTokens;
import org.neo4j.driver.Config;
import org.neo4j.driver.Driver;
import org.neo4j.driver.GraphDatabase;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Duration;
import java.util.concurrent.TimeUnit;

/**
 * Neo4j 数据库连接配置
 * 
 * 配置连接池参数以优化性能：
 * - 连接池大小
 * - 连接超时
 * - 连接存活时间
 * - 查询超时
 */
@Configuration
public class Neo4jConfig {

    @Value("${spring.neo4j.uri:bolt://localhost:7687}")
    private String uri;

    @Value("${spring.neo4j.authentication.username:neo4j}")
    private String username;

    @Value("${spring.neo4j.authentication.password:}")
    private String password;

    // 连接池配置
    @Value("${spring.neo4j.pool.max-connection-pool-size:100}")
    private int maxConnectionPoolSize;

    @Value("${spring.neo4j.pool.connection-acquisition-timeout-seconds:60}")
    private long connectionAcquisitionTimeout;

    @Value("${spring.neo4j.pool.max-connection-lifetime-minutes:60}")
    private long maxConnectionLifetime;

    @Value("${spring.neo4j.pool.idle-time-before-connection-test-seconds:120}")
    private long idleTimeBeforeConnectionTest;

    // 查询超时配置
    @Value("${spring.neo4j.transaction-timeout-seconds:60}")
    private long transactionTimeout;

    @Bean
    public Driver neo4jDriver() {
        Config config = Config.builder()
                // 连接池配置
                .withMaxConnectionPoolSize(maxConnectionPoolSize)
                .withConnectionAcquisitionTimeout(connectionAcquisitionTimeout, TimeUnit.SECONDS)
                .withMaxConnectionLifetime(maxConnectionLifetime, TimeUnit.MINUTES)
                .withConnectionLivenessCheckTimeout(idleTimeBeforeConnectionTest, TimeUnit.SECONDS)
                // 日志配置 - 记录泄漏的会话（调试用）
                .withLeakedSessionsLogging()
                // 连接超时
                .withConnectionTimeout(30, TimeUnit.SECONDS)
                .build();

        return GraphDatabase.driver(uri, AuthTokens.basic(username, password), config);
    }
}
