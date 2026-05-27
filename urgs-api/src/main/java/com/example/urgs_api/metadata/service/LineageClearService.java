package com.example.urgs_api.metadata.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.neo4j.driver.Driver;
import org.neo4j.driver.Result;
import org.neo4j.driver.Session;
import org.neo4j.driver.exceptions.Neo4jException;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.locks.ReentrantLock;

@Slf4j
@Service
@RequiredArgsConstructor
public class LineageClearService {

    private static final int CLEAR_RELATIONSHIP_BATCH_SIZE = 500;
    private static final int CLEAR_NODE_BATCH_SIZE = 500;
    private static final int MAX_TRANSIENT_RETRIES = 5;
    private static final long TRANSIENT_RETRY_BACKOFF_MILLIS = 200L;

    private static final String DELETE_RELATIONSHIPS_QUERY = """
            MATCH ()-[r]->()
            WITH r LIMIT $batchSize
            DELETE r
            RETURN count(*) AS deleted
            """;

    private static final String DELETE_NODES_QUERY = """
            MATCH (n)
            WITH n LIMIT $batchSize
            DELETE n
            RETURN count(*) AS deleted
            """;

    private final Driver driver;
    private final LineageEngineService lineageEngineService;
    private final ReentrantLock clearLock = new ReentrantLock();

    public Map<String, Object> clearAll() {
        if (!clearLock.tryLock()) {
            return failure("清空任务正在执行，请稍后重试");
        }

        try {
            Object engineStatus = lineageEngineService.status().get("status");
            if ("running".equals(engineStatus) || "starting".equals(engineStatus)) {
                return failure("血缘引擎正在运行，请先停止引擎再清空 Neo4j 数据");
            }

            try (Session session = driver.session()) {
                long totalRelationshipsDeleted = deleteInBatches(
                        session,
                        DELETE_RELATIONSHIPS_QUERY,
                        CLEAR_RELATIONSHIP_BATCH_SIZE,
                        "关系");
                long totalNodesDeleted = deleteInBatches(
                        session,
                        DELETE_NODES_QUERY,
                        CLEAR_NODE_BATCH_SIZE,
                        "节点");

                log.info("Neo4j 数据库已清空，共删除 {} 个节点、{} 条关系", totalNodesDeleted, totalRelationshipsDeleted);
                Map<String, Object> result = new HashMap<>();
                result.put("success", true);
                result.put("message", "数据库已清空，共删除 " + totalNodesDeleted + " 个节点、" + totalRelationshipsDeleted + " 条关系");
                result.put("deletedCount", totalNodesDeleted);
                result.put("deletedRelationshipCount", totalRelationshipsDeleted);
                return result;
            }
        } catch (Exception e) {
            log.error("清空 Neo4j 数据库失败", e);
            return failure("清空失败: " + e.getMessage());
        } finally {
            clearLock.unlock();
        }
    }

    private long deleteInBatches(Session session, String query, int batchSize, String label) {
        long totalDeleted = 0;
        while (true) {
            long deleted = runDeleteBatch(session, query, batchSize, label);
            totalDeleted += deleted;
            if (deleted == 0) {
                return totalDeleted;
            }
        }
    }

    private long runDeleteBatch(Session session, String query, int batchSize, String label) {
        int attempt = 0;
        while (true) {
            try {
                return session.executeWrite(tx -> {
                    Result result = tx.run(query, Map.of("batchSize", batchSize));
                    return result.single().get("deleted").asLong();
                });
            } catch (Neo4jException e) {
                attempt++;
                if (!isTransientLockFailure(e) || attempt >= MAX_TRANSIENT_RETRIES) {
                    throw e;
                }
                log.warn("Neo4j 清空{}时遇到临时锁冲突，准备第 {} 次重试: code={}, message={}",
                        label, attempt, e.code(), e.getMessage());
                sleepBeforeRetry(attempt);
            }
        }
    }

    private boolean isTransientLockFailure(Neo4jException e) {
        String code = e.code();
        if (code != null && (code.startsWith("Neo.TransientError.") || code.contains("DeadlockDetected"))) {
            return true;
        }
        String message = e.getMessage();
        return message != null
                && (message.contains("ForsetiClient")
                || message.toLowerCase(Locale.ROOT).contains("deadlock"));
    }

    private void sleepBeforeRetry(int attempt) {
        try {
            Thread.sleep(TRANSIENT_RETRY_BACKOFF_MILLIS * attempt);
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("等待 Neo4j 清空重试时被中断", interrupted);
        }
    }

    private Map<String, Object> failure(String message) {
        Map<String, Object> result = new HashMap<>();
        result.put("success", false);
        result.put("message", message);
        return result;
    }
}
