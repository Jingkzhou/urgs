package com.example.executor.urgs_executor.handler.impl;

import com.example.executor.urgs_executor.entity.DataSourceConfig;
import com.example.executor.urgs_executor.entity.DataSourceMeta;
import com.example.executor.urgs_executor.entity.TaskInstance;
import com.example.executor.urgs_executor.handler.TaskHandler;
import com.example.executor.urgs_executor.mapper.DataSourceConfigMapper;
import com.example.executor.urgs_executor.mapper.DataSourceMetaMapper;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Component("DataX")
public class DataXTaskHandler implements TaskHandler {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    private DataSourceConfigMapper dataSourceConfigMapper;

    @Autowired
    private DataSourceMetaMapper dataSourceMetaMapper;

    @Value("${datax.home:/opt/datax}")
    private String dataxHome;

    @Override
    public String execute(TaskInstance instance) throws Exception {
        log.info("Executing DataX Task {}", instance.getId());

        if (instance.getContentSnapshot() == null) {
            throw new IllegalArgumentException("DataX task content is empty");
        }

        // Replace $dataDate with actual date
        String contentSnapshot = instance.getContentSnapshot().replace("$dataDate", instance.getDataDate());

        JsonNode contentNode = objectMapper.readTree(contentSnapshot);

        // 1. Build DataX JSON Configuration
        ObjectNode jobConfig = objectMapper.createObjectNode();
        ObjectNode job = jobConfig.putObject("job");

        // Setting (Speed, Error Limit) - Default values if not provided
        ObjectNode setting = job.putObject("setting");
        ObjectNode speed = setting.putObject("speed");
        speed.put("channel", contentNode.path("setting").path("speed").path("channel").asInt(1));

        ObjectNode content = job.putArray("content").addObject();

        // Reader
        JsonNode readerNode = contentNode.path("reader");
        content.set("reader", buildPluginConfig(readerNode, true));

        // Writer
        JsonNode writerNode = contentNode.path("writer");
        content.set("writer", buildPluginConfig(writerNode, false));

        // 2. Write to temporary file
        String jsonString = objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(jobConfig);
        Path tempFile = Files.createTempFile("datax-job-" + instance.getId() + "-" + UUID.randomUUID(), ".json");
        Files.write(tempFile, jsonString.getBytes());

        log.info("Generated DataX Config: \n{}", jsonString);

        // 3. Execute DataX
        StringBuilder logBuilder = new StringBuilder();
        logBuilder.append("Executing DataX Task ").append(instance.getId()).append("\n");

        try {
            ProcessBuilder pb = new ProcessBuilder("python3", dataxHome + "/bin/datax.py",
                    tempFile.toAbsolutePath().toString());
            pb.redirectErrorStream(true);
            Process process = pb.start();

            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    log.info("[DataX-{}] {}", instance.getId(), line);
                    logBuilder.append(line).append("\n");
                }
            }

            int exitCode = process.waitFor();
            if (exitCode != 0) {
                logBuilder.append("\nDataX process exited with code ").append(exitCode);
                throw new RuntimeException(
                        "DataX execution failed with code " + exitCode + "\nLogs:\n" + logBuilder.toString());
            }

            logBuilder.append("\nDataX execution successful.");

        } finally {
            // Cleanup
            try {
                Files.deleteIfExists(tempFile);
            } catch (Exception e) {
                log.warn("Failed to delete temp file: {}", tempFile, e);
            }
        }

        return logBuilder.toString();
    }

    private ObjectNode buildPluginConfig(JsonNode node, boolean isReader) {
        ObjectNode pluginConfig = objectMapper.createObjectNode();
        String name = null;
        ObjectNode parameter = objectMapper.createObjectNode();

        // Merge user provided parameters first
        if (node.has("parameter")) {
            parameter.setAll((ObjectNode) node.get("parameter"));
        }

        // If datasourceId is provided, fetch config and merge
        if (node.has("datasourceId")) {
            Long dsId = node.get("datasourceId").asLong();
            DataSourceConfig dsConfig = dataSourceConfigMapper.selectById(dsId);
            if (dsConfig == null) {
                throw new RuntimeException("DataSource not found: " + dsId);
            }
            DataSourceMeta meta = dataSourceMetaMapper.selectById(dsConfig.getMetaId());
            if (meta == null) {
                throw new RuntimeException("DataSource Meta not found: " + dsConfig.getMetaId());
            }

            // Determine Plugin Name
            name = getPluginName(meta.getCode(), isReader);

            // Merge Connection Parameters
            Map<String, Object> connParams = dsConfig.getConnectionParams();
            fillPluginParameters(name, parameter, connParams, isReader);
        } else if (node.has("name")) {
            name = node.get("name").asText();
        }

        if (name == null) {
            throw new IllegalArgumentException(
                    "DataX plugin name could not be determined. Provide 'datasourceId' or 'name'.");
        }

        pluginConfig.put("name", name);
        pluginConfig.set("parameter", parameter);
        return pluginConfig;
    }

    private String getPluginName(String dbType, boolean isReader) {
        String suffix = isReader ? "reader" : "writer";
        String type = dbType.toLowerCase();

        switch (type) {
            // RDBMS
            case "mysql":
                return "mysql" + suffix;
            case "oracle":
                return "oracle" + suffix;
            case "sqlserver":
                return "sqlserver" + suffix;
            case "postgresql":
                return "postgresql" + suffix;
            case "clickhouse":
                return "clickhouse" + suffix;
            case "db2":
                return "db2" + suffix;
            case "kingbasees":
                return "kingbasees" + suffix;
            case "dm":
                return "dm" + suffix;

            // Big Data
            case "hdfs":
                return "hdfs" + suffix;
            case "hive":
                return "hdfs" + suffix; // Hive uses hdfs reader/writer
            case "hbase":
                return "hbase11x" + suffix; // Defaulting to 1.1x
            case "kudu":
                return "kudu" + suffix;

            // NoSQL
            case "mongodb":
                return "mongodb" + suffix;
            case "elasticsearch":
                return "elasticsearch" + suffix;
            case "redis":
                if (isReader)
                    throw new UnsupportedOperationException("Redis reader is not typically supported in DataX");
                return "rediswriter";
            case "cassandra":
                return "cassandra" + suffix;

            // File
            case "txtfile":
                return "txtfile" + suffix;
            case "ftp":
                return "ftp" + suffix;
            case "sftp":
                return "ftp" + suffix; // SFTP often uses ftp plugin with protocol param
            case "oss":
                return "oss" + suffix;
            case "s3":
                return "s3" + suffix;
            case "stream":
                return "stream" + suffix;

            default:
                return type + suffix; // Fallback
        }
    }

    private void fillPluginParameters(String pluginName, ObjectNode parameter, Map<String, Object> connParams,
            boolean isReader) {
        // Common RDBMS logic
        if (pluginName.contains("mysql") || pluginName.contains("oracle") || pluginName.contains("sqlserver")
                || pluginName.contains("postgresql") || pluginName.contains("clickhouse") || pluginName.contains("db2")
                || pluginName.contains("kingbase") || pluginName.contains("dm")) {

            parameter.put("username", (String) connParams.get("username"));
            parameter.put("password", (String) connParams.get("password"));

            // Connection Array
            ArrayNode connection = parameter.putArray("connection");
            ObjectNode connItem = connection.addObject();

            // JDBC URL
            String jdbcUrl = constructJdbcUrl(pluginName, connParams);
            connItem.putArray("jdbcUrl").add(jdbcUrl);

            // Table (should be provided in task content parameter, but if missing, check
            // connParams?)
            // Usually table is task specific, not datasource specific.
            // But we leave it to be merged from 'parameter' node passed in
            // buildPluginConfig if present.
            // If the user put 'table' in datasource config (unlikely), we could map it.
            // Here we just ensure the structure exists.
            if (parameter.has("table")) {
                connItem.set("table", parameter.get("table"));
                parameter.remove("table"); // Move table inside connection for RDBMS
            }
        }

        // HDFS / Hive
        else if (pluginName.contains("hdfs")) {
            parameter.put("defaultFS", (String) connParams.get("defaultFS"));
            // path, fileType, etc. should come from task params
        }

        // MongoDB
        else if (pluginName.contains("mongodb")) {
            parameter.put("address", (String) connParams.get("address")); // e.g. 127.0.0.1:27017
            parameter.put("userName", (String) connParams.get("username"));
            parameter.put("userPassword", (String) connParams.get("password"));
            parameter.put("dbName", (String) connParams.get("database"));
        }

        // FTP/SFTP
        else if (pluginName.contains("ftp")) {
            parameter.put("host", (String) connParams.get("host"));
            parameter.put("port", (Integer) connParams.get("port"));
            parameter.put("username", (String) connParams.get("username"));
            parameter.put("password", (String) connParams.get("password"));
            parameter.put("protocol", (String) connParams.getOrDefault("protocol", "sftp"));
        }

        // Add other specific mappings as needed
    }

    private String constructJdbcUrl(String pluginName, Map<String, Object> params) {
        String host = (String) params.get("host");
        Integer port = (Integer) params.get("port");
        String database = (String) params.get("database");

        if (pluginName.contains("mysql"))
            return String.format("jdbc:mysql://%s:%d/%s?useSSL=false", host, port, database);
        if (pluginName.contains("postgresql"))
            return String.format("jdbc:postgresql://%s:%d/%s", host, port, database);
        if (pluginName.contains("oracle")) {
            String serviceName = (String) params.get("serviceName");
            return String.format("jdbc:oracle:thin:@//%s:%d/%s", host, port,
                    serviceName != null ? serviceName : database);
        }
        if (pluginName.contains("sqlserver"))
            return String.format("jdbc:sqlserver://%s:%d;databaseName=%s", host, port, database);
        if (pluginName.contains("clickhouse"))
            return String.format("jdbc:clickhouse://%s:%d/%s", host, port, database);

        // Fallback or generic
        return (String) params.get("jdbcUrl");
    }
}
