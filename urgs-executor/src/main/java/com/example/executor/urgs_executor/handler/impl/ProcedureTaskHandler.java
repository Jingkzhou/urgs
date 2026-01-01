package com.example.executor.urgs_executor.handler.impl;

import com.example.executor.urgs_executor.entity.DataSourceConfig;
import com.example.executor.urgs_executor.entity.DataSourceMeta;
import com.example.executor.urgs_executor.entity.ExecutorTaskInstance;
import com.example.executor.urgs_executor.handler.TaskHandler;
import com.example.executor.urgs_executor.mapper.DataSourceConfigMapper;
import com.example.executor.urgs_executor.mapper.DataSourceMetaMapper;
import com.example.executor.urgs_executor.util.PlaceholderUtils;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.util.Map;

@Slf4j
@Component("PROCEDURE")
public class ProcedureTaskHandler implements TaskHandler {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    private DataSourceConfigMapper dataSourceConfigMapper;

    @Autowired
    private DataSourceMetaMapper dataSourceMetaMapper;

    @Override
    public String execute(ExecutorTaskInstance instance) throws Exception {
        String script = "";
        String resourceId = null;

        if (instance.getContentSnapshot() != null) {
            JsonNode node = objectMapper.readTree(instance.getContentSnapshot());
            if (node.has("script")) {
                script = node.get("script").asText();
            }
            if (node.has("resource")) {
                resourceId = node.get("resource").asText();
            }
        }

        if (script.isEmpty()) {
            log.warn("Procedure task {} has no script content", instance.getId());
            return "No script content";
        }

        // Replace $dataDate with actual date
        script = PlaceholderUtils.replaceDataDate(script, instance.getDataDate());

        if (resourceId == null || resourceId.isEmpty()) {
            throw new RuntimeException("Procedure task requires a valid resource ID");
        }

        log.info("Executing Procedure Task {}: {}", instance.getId(), script);

        return executeProcedure(instance, script, resourceId);
    }

    private String executeProcedure(ExecutorTaskInstance instance, String script, String resourceId) throws Exception {
        DataSourceConfig config = dataSourceConfigMapper.selectById(resourceId);
        if (config == null) {
            throw new RuntimeException("Resource not found: " + resourceId);
        }

        DataSourceMeta meta = dataSourceMetaMapper.selectById(config.getMetaId());
        if (meta == null) {
            throw new RuntimeException("Resource metadata not found for config: " + resourceId);
        }

        Map<String, Object> params = config.getConnectionParams();
        String url = constructJdbcUrl(meta.getCode(), params);
        String username = (String) params.get("username");
        String password = (String) params.get("password");

        StringBuilder logBuilder = new StringBuilder();
        logBuilder.append("Executing Procedure Task ").append(instance.getId()).append("\n");
        logBuilder.append("Target: ").append(url).append("\n");
        logBuilder.append("Procedure: ").append(script).append("\n\n");

        try (Connection conn = DriverManager.getConnection(url, username, password);
                CallableStatement cstmt = conn.prepareCall(script)) {

            boolean hasResults = cstmt.execute();

            if (hasResults) {
                try (ResultSet rs = cstmt.getResultSet()) {
                    int colCount = rs.getMetaData().getColumnCount();
                    while (rs.next()) {
                        StringBuilder row = new StringBuilder();
                        for (int i = 1; i <= colCount; i++) {
                            row.append(rs.getObject(i)).append("\t");
                        }
                        log.info("[Procedure-{}] {}", instance.getId(), row);
                        logBuilder.append(row).append("\n");
                    }
                }
            } else {
                int updateCount = cstmt.getUpdateCount();
                logBuilder.append("Update Count: ").append(updateCount).append("\n");
            }

            logBuilder.append("\nProcedure executed successfully.");
        } catch (Exception e) {
            log.error("Procedure execution failed", e);
            logBuilder.append("\nExecution failed: ").append(e.getMessage());
            throw e;
        }

        return logBuilder.toString();
    }

    private String constructJdbcUrl(String dbType, Map<String, Object> params) {
        String host = (String) params.get("host");
        Integer port = (Integer) params.get("port");
        String database = (String) params.get("database");
        // Handle different param names if necessary (e.g. serviceName for Oracle)

        switch (dbType.toLowerCase()) {
            case "mysql":
                return String.format("jdbc:mysql://%s:%d/%s?useSSL=false&serverTimezone=UTC", host, port, database);
            case "postgresql":
                return String.format("jdbc:postgresql://%s:%d/%s", host, port, database);
            case "oracle":
                String serviceName = (String) params.get("serviceName");
                return String.format("jdbc:oracle:thin:@//%s:%d/%s", host, port,
                        serviceName != null ? serviceName : database);
            case "sqlserver":
                return String.format("jdbc:sqlserver://%s:%d;databaseName=%s;encrypt=false", host, port, database);
            case "clickhouse":
                return String.format("jdbc:clickhouse://%s:%d/%s", host, port, database);
            default:
                throw new UnsupportedOperationException("Unsupported database type for procedure execution: " + dbType);
        }
    }
}
