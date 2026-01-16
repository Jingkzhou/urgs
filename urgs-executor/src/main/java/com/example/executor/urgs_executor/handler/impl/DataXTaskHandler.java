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
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.JsonNodeFactory;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.UUID;

/**
 * DataX 任务执行处理器
 * 负责解析任务配置，生成 DataX 所需的 JSON 配置文件，并调用本地 DataX (Python) 进行数据同步。
 */
@Slf4j
@Component("DATAX")
public class DataXTaskHandler implements TaskHandler {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    private DataSourceConfigMapper dataSourceConfigMapper;

    @Autowired
    private DataSourceMetaMapper dataSourceMetaMapper;

    /**
     * DataX 安装目录，默认从配置文件读取，默认为 /opt/datax
     */
    @Value("${app.datax.home:/opt/datax}")
    private String dataxHome;

    @Override
    public String execute(ExecutorTaskInstance instance) throws Exception {
        log.info(">>>> CODE VERSION: SQL-FIX-V5-FILE-VERIFY STARTING EXECUTION <<<<");
        log.info("开始执行 DataX 任务: {}", instance.getId());

        // 验证任务内容是否存在
        if (instance.getContentSnapshot() == null) {
            throw new IllegalArgumentException("DataX 任务内容为空");
        }

        // 替换占位符 $dataDate 为实际的任务数据日期
        String contentSnapshot = PlaceholderUtils.replaceDataDate(instance.getContentSnapshot(),
                instance.getDataDate());

        // 解析任务内容的 JSON 配置
        JsonNode contentNode = objectMapper.readTree(contentSnapshot);
        log.info("[Debug] Raw content snapshot: {}", contentSnapshot);

        // 兼容前端扁平化结构：如果 contentNode 中没有 reader/writer，则尝试从 flattened fields 构建
        if (!contentNode.has("reader") || !contentNode.has("writer")) {
            contentNode = normalizeContent(contentNode);
        }
        log.info("[Debug] Normalized content node: {}", contentNode);

        // 1. 构建 DataX JSON 配置文件结构
        ObjectNode jobConfig = objectMapper.createObjectNode();
        ObjectNode job = jobConfig.putObject("job");

        // 设置全局参数（速度控制、错误控制等）- 若未提供则使用默认值
        ObjectNode setting = job.putObject("setting");
        ObjectNode speed = setting.putObject("speed");
        speed.put("channel", contentNode.path("setting").path("speed").path("channel").asInt(1));

        // 构建任务内容主体 (Reader 和 Writer)
        ObjectNode content = job.putArray("content").addObject();

        // 配置 Reader (数据读取端)
        JsonNode readerNode = contentNode.path("reader");
        content.set("reader", buildPluginConfig(readerNode, true));

        // 配置 Writer (数据写入端)
        JsonNode writerNode = contentNode.path("writer");
        content.set("writer", buildPluginConfig(writerNode, false));

        // 2. 将生成的 JSON 配置写入临时文件，供 DataX 进程调用
        String jsonString = objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(jobConfig);

        // 检查是否指定了执行节点 (contentNode.path("executionNodeId"))
        long executionNodeId = contentNode.path("executionNodeId").asLong(0);

        if (executionNodeId > 0) {
            return runRemote(instance, executionNodeId, jsonString);
        } else {
            return runLocal(instance, jsonString);
        }
    }

    private String runLocal(ExecutorTaskInstance instance, String jsonString) throws Exception {
        Path tempFile = Files.createTempFile("datax-job-" + instance.getId() + "-" + UUID.randomUUID(), ".json");
        Files.write(tempFile, jsonString.getBytes());

        log.info("生成的 DataX 配置 (Local): \n{}", jsonString);

        // 3. 开启子进程执行 DataX (调用 python datax.py)
        StringBuilder logBuilder = new StringBuilder();
        String timeStart = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        logBuilder.append("[").append(timeStart).append("] ").append("正在本机执行 DataX 任务 ").append(instance.getId())
                .append("\n");

        try {
            // DataX 通常通过 python 脚本启动
            ProcessBuilder pb = new ProcessBuilder("python3", dataxHome + "/bin/datax.py",
                    tempFile.toAbsolutePath().toString());
            pb.redirectErrorStream(true); // 合并标准输出和错误输出流
            Process process = pb.start();

            // 实时读取并打印 DataX 日志输出
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    log.info("[DataX-{}] {}", instance.getId(), line);
                    logBuilder.append(line).append("\n");
                }
            }

            // 等待进程结束并获取退出状态码
            int exitCode = process.waitFor();
            if (exitCode != 0) {
                String timeErr = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
                logBuilder.append("\n[").append(timeErr).append("] ").append("DataX 进程异常退出，状态码: ").append(exitCode);
                throw new RuntimeException(
                        "DataX 执行失败，代码: " + exitCode + "\n日志摘要:\n" + logBuilder.toString());
            }

            String timeEnd = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            logBuilder.append("\n[").append(timeEnd).append("] ").append("DataX 执行成功。");

        } finally {
            // 执行完毕后删除临时 JSON 配置文件
            try {
                Files.deleteIfExists(tempFile);
            } catch (Exception e) {
                log.warn("清理临时配置文件失败: {}", tempFile, e);
            }
        }
        return logBuilder.toString();
    }

    private String runRemote(ExecutorTaskInstance instance, long nodeId, String jsonString) throws Exception {
        // 获取 SSH 节点配置
        DataSourceConfig nodeConfig = dataSourceConfigMapper.selectById(nodeId);
        if (nodeConfig == null) {
            throw new RuntimeException("指定的 DataX 执行节点不存在: " + nodeId);
        }
        Map<String, Object> params = nodeConfig.getConnectionParams();
        String host = (String) params.get("host");
        Integer port = (Integer) params.get("port");
        String username = (String) params.get("username");
        String password = (String) params.get("password");
        String remoteDataxHome = (String) params.get("dataxHome");

        if (remoteDataxHome == null || remoteDataxHome.isEmpty()) {
            throw new RuntimeException("远程节点未配置 'dataxHome' 路径");
        }
        if (remoteDataxHome.endsWith("/")) {
            remoteDataxHome = remoteDataxHome.substring(0, remoteDataxHome.length() - 1);
        }

        StringBuilder logBuilder = new StringBuilder();
        String timeStart = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        logBuilder.append("[").append(timeStart).append("] ").append("正在远程节点 ").append(host).append(" 执行 DataX 任务 ")
                .append(instance.getId()).append("\n");

        com.jcraft.jsch.Session session = null;
        String remoteTempFile = "/tmp/datax-job-" + instance.getId() + "-" + UUID.randomUUID() + ".json";

        try {
            session = com.example.executor.urgs_executor.util.SshUtils.connect(host, port != null ? port : 22, username,
                    password);

            // 1. 上传 JSON 配置文件
            log.info("不再本地生成文件，直接上传配置到远程: {}", remoteTempFile);
            log.info("[Debug] Generated DataX Config (Remote): \n{}", jsonString);
            com.example.executor.urgs_executor.util.SshUtils.scpTo(session, jsonString, remoteTempFile);

            // DEBUG: Read back the file to verify what was actually written
            String verifyCmd = "cat " + remoteTempFile;
            String fileContent = com.example.executor.urgs_executor.util.SshUtils.exec(session, verifyCmd);
            log.info("[Debug] ACTUAL FILE CONTENT on remote server: \n{}", fileContent);

            // 2. 执行 DataX 命令
            String command = String.format("python3 %s/bin/datax.py %s", remoteDataxHome, remoteTempFile);
            log.info("远程执行命令: {}", command);

            // 注意：SshUtils.exec 目前是等待执行完毕并一次性返回，对于 DataX 这种长任务可能不适合实时日志。
            // 简单起见，我们暂且认为 log 可以在结束后一次性获取，或者后续优化 SshUtils 支持流式读取。
            // 但为了兼容现有接口契约，我们这里等待结果。
            String output = com.example.executor.urgs_executor.util.SshUtils.exec(session, command);
            logBuilder.append(output);

            String timeEnd = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            logBuilder.append("\n[").append(timeEnd).append("] ").append("远程 DataX 执行成功。");

        } catch (Exception e) {
            String timeErr = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            logBuilder.append("\n[").append(timeErr).append("] ").append("远程执行失败: ").append(e.getMessage());
            throw e;
        } finally {
            if (session != null && session.isConnected()) {
                // 3. 清理远程文件
                try {
                    com.example.executor.urgs_executor.util.SshUtils.exec(session, "rm -f " + remoteTempFile);
                    session.disconnect();
                } catch (Exception e) {
                    log.warn("清理远程临时文件失败", e);
                }
            }
        }

        return logBuilder.toString();
    }

    /**
     * 根据任务配置构建 DataX 插件 (Reader/Writer) 的详细配置
     */
    private ObjectNode buildPluginConfig(JsonNode node, boolean isReader) {
        ObjectNode pluginConfig = objectMapper.createObjectNode();
        String name = null;
        ObjectNode parameter = objectMapper.createObjectNode();

        // 首先合并用户在任务中直接填写的参数
        if (node.has("parameter")) {
            parameter.setAll((ObjectNode) node.get("parameter"));
        }

        // 如果配置了数据源 ID (datasourceId)，则从数据库获取连接配置并合并
        if (node.has("datasourceId")) {
            Long dsId = node.get("datasourceId").asLong();
            DataSourceConfig dsConfig = dataSourceConfigMapper.selectById(dsId);
            if (dsConfig == null) {
                throw new RuntimeException("未找到数据源: " + dsId);
            }
            DataSourceMeta meta = dataSourceMetaMapper.selectById(dsConfig.getMetaId());
            if (meta == null) {
                throw new RuntimeException("未找到数据源元数据: " + dsConfig.getMetaId());
            }

            // 自动判断 DataX 插件名称 (例如：mysqlreader, oraclewriter)
            name = getPluginName(meta.getCode(), isReader);

            // 合并数据库连接参数 (URL, 用户名, 密码等)
            Map<String, Object> connParams = dsConfig.getConnectionParams();
            fillPluginParameters(name, parameter, connParams, isReader);
        } else if (node.has("name")) {
            // 如果没配置数据源 ID，则要求手动指定插件名
            name = node.get("name").asText();
        }

        if (name == null) {
            throw new IllegalArgumentException(
                    "无法确定 DataX 插件名称。请提供 'datasourceId' 或手动指定 'name'。");
        }

        pluginConfig.put("name", name);
        pluginConfig.set("parameter", parameter);
        return pluginConfig;
    }

    private JsonNode normalizeContent(JsonNode flatNode) {
        ObjectNode root = (ObjectNode) flatNode;
        ObjectMapper mapper = new ObjectMapper();

        // 1. Construct Reader
        if (!root.has("reader") && root.has("sourceId")) {
            ObjectNode reader = mapper.createObjectNode();
            reader.put("datasourceId", root.get("sourceId").asLong());

            ObjectNode param = mapper.createObjectNode();

            // Common RDBMS fields
            // Priority: SQL > Table
            if (root.has("sql") && !root.get("sql").asText().isEmpty()) {
                // QuerySQL Mode: ignore table/column
                ArrayNode sqlArray = mapper.createArrayNode();
                sqlArray.add(root.get("sql").asText());
                param.set("sql", sqlArray);
            } else {
                // Table Mode
                if (root.has("table")) {
                    param.set("table", root.get("table"));
                }

                if (root.has("column")) {
                    // Convert "col1,col2" string to ["col1", "col2"] array
                    String colStr = root.get("column").asText();
                    ArrayNode colArray = mapper.createArrayNode();
                    if (colStr != null && !colStr.isEmpty()) {
                        if (colStr.equals("*")) {
                            colArray.add("*");
                        } else {
                            for (String c : colStr.split(",")) {
                                colArray.add(c.trim());
                            }
                        }
                    } else {
                        colArray.add("*"); // Explicit empty column string -> *
                    }
                    param.set("column", colArray);
                } else if (!root.has("streamColumn") && !root.has("path")) {
                    // Default to ["*"] for RDBMS if no column specified (and not stream/file)
                    ArrayNode colArray = mapper.createArrayNode();
                    colArray.add("*");
                    param.set("column", colArray);
                }
            }

            if (root.has("where"))
                param.set("where", root.get("where"));
            if (root.has("splitPk"))
                param.set("splitPk", root.get("splitPk"));

            // File
            if (root.has("path")) {
                ArrayNode pathArray = mapper.createArrayNode();
                pathArray.add(root.get("path").asText());
                param.set("path", pathArray);
            }
            if (root.has("fileType"))
                param.set("fileType", root.get("fileType"));
            if (root.has("fieldDelimiter"))
                param.set("fieldDelimiter", root.get("fieldDelimiter"));

            // Stream
            // Check explicit sourceType to ensure we handle Stream defaults
            String sourceType = root.has("sourceType") ? root.get("sourceType").asText().toUpperCase() : "";

            if (root.has("sliceRecordCount")) {
                param.set("sliceRecordCount", root.get("sliceRecordCount"));
            } else if ("STREAM".equals(sourceType)) {
                param.put("sliceRecordCount", 100); // Default count
            }

            if (root.has("streamColumn")) {
                try {
                    String streamColStr = root.get("streamColumn").asText();
                    if (streamColStr != null && !streamColStr.isEmpty()) {
                        JsonNode parsedCol = mapper.readTree(streamColStr);
                        param.set("column", parsedCol);
                    }
                } catch (Exception e) {
                    log.error("Failed to parse streamColumn key", e);
                }
            } else if ("STREAM".equals(sourceType)) {
                // Inject default column for Stream reader if missing
                ArrayNode defaultCol = mapper.createArrayNode();
                ObjectNode colObj = mapper.createObjectNode();
                colObj.put("type", "string");
                colObj.put("value", "default_stream_value");
                defaultCol.add(colObj);
                param.set("column", defaultCol);
            }

            reader.set("parameter", param);
            root.set("reader", reader);
        }

        // 2. Construct Writer
        if (!root.has("writer") && root.has("targetId")) {
            ObjectNode writer = mapper.createObjectNode();
            writer.put("datasourceId", root.get("targetId").asLong());

            ObjectNode param = mapper.createObjectNode();

            // RDBMS
            if (root.has("targetTable")) {
                ArrayNode tables = mapper.createArrayNode();
                tables.add(root.get("targetTable").asText());
                param.set("table", tables); // Writer 'table' is usually an array too [table]
            }
            if (root.has("targetColumn")) {
                String colStr = root.get("targetColumn").asText();
                ArrayNode colArray = mapper.createArrayNode();
                if (colStr != null && !colStr.isEmpty()) {
                    if (colStr.equals("*")) {
                        colArray.add("*");
                    } else {
                        for (String c : colStr.split(",")) {
                            colArray.add(c.trim());
                        }
                    }
                } else {
                    colArray.add("*");
                }
                param.set("column", colArray);
            }
            if (root.has("writeMode"))
                param.set("writeMode", root.get("writeMode"));
            if (root.has("preSql")) {
                ArrayNode pre = mapper.createArrayNode();
                pre.add(root.get("preSql").asText());
                param.set("preSql", pre);
            }
            if (root.has("postSql")) {
                ArrayNode post = mapper.createArrayNode();
                post.add(root.get("postSql").asText());
                param.set("postSql", post);
            }

            // File
            if (root.has("targetPath"))
                param.set("path", root.get("targetPath"));
            if (root.has("fileName"))
                param.set("fileName", root.get("fileName"));
            if (root.has("fileType"))
                param.set("fileType", root.get("fileType"));
            if (root.has("fieldDelimiter"))
                param.set("fieldDelimiter", root.get("fieldDelimiter"));

            // Stream Writer (usually no specific params or 'print')
            if (root.has("print"))
                param.put("print", root.get("print").asBoolean());

            writer.set("parameter", param);
            root.set("writer", writer);
        }

        return root;
    }

    /**
     * 根据数据库类型获取对应的 DataX 插件名后缀
     */
    private String getPluginName(String dbType, boolean isReader) {
        String suffix = isReader ? "reader" : "writer";
        String type = dbType.toLowerCase();

        switch (type) {
            // 关系型数据库 (RDBMS)
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

            // 大数据组件 (Big Data)
            case "hdfs":
                return "hdfs" + suffix;
            case "hive":
                return "hdfs" + suffix; // Hive 通常使用 HDFS 读取/写入
            case "hbase":
                return "hbase11x" + suffix; // 默认使用 1.1x 版本
            case "kudu":
                return "kudu" + suffix;

            // NoSQL 数据库
            case "mongodb":
                return "mongodb" + suffix;
            case "elasticsearch":
                return "elasticsearch" + suffix;
            case "redis":
                if (isReader)
                    throw new UnsupportedOperationException("目前不支持作为 DataX Reader 使用 Redis");
                return "rediswriter";
            case "cassandra":
                return "cassandra" + suffix;

            // 文件及存储
            case "txtfile":
                return "txtfile" + suffix;
            case "ftp":
                return "ftp" + suffix;
            case "sftp":
                return "ftp" + suffix; // SFTP 通常重用 FTP 插件，通过 protocol 参数区分
            case "oss":
                return "oss" + suffix;
            case "s3":
                return "s3" + suffix;
            case "stream":
                return "stream" + suffix;

            default:
                return type + suffix; // 兜底方案
        }
    }

    /**
     * 将解析出的数据库连接参数填充到 DataX 插件参数 JSON 中
     */
    private void fillPluginParameters(String pluginName, ObjectNode parameter, Map<String, Object> connParams,
            boolean isReader) {
        // 1. 通用 RDBMS (关系型数据库) 逻辑
        if (pluginName.contains("mysql") || pluginName.contains("oracle") || pluginName.contains("sqlserver")
                || pluginName.contains("postgresql") || pluginName.contains("clickhouse") || pluginName.contains("db2")
                || pluginName.contains("kingbase") || pluginName.contains("dm")) {

            parameter.put("username", (String) connParams.get("username"));
            parameter.put("password", (String) connParams.get("password"));

            // DataX RDBMS 插件通常要求 connection 数组结构
            ArrayNode connection = parameter.putArray("connection");
            ObjectNode connItem = connection.addObject();

            // 构建符合 DataX 规范的 JDBC URL
            String jdbcUrl = constructJdbcUrl(pluginName, connParams);
            // WORKAROUND V4: User requested to use ArrayNode.
            // "jdbcUrl" in DataX usually requires a List.
            // Previous error "No suitable driver found for ['...']" might be due to
            // implicit string conversion or logging artifact.
            // We revert to explicit ArrayNode.
            connItem.putArray("jdbcUrl").add(jdbcUrl);

            // 处理 'table' 参数：如果顶级参数中有 table，则移动到 connection 内部
            if (parameter.has("table")) {
                connItem.set("table", parameter.get("table"));
                parameter.remove("table");
            }

            // 处理 'sql' 参数：如果顶级参数中有 sql，则移动到 connection 内部并重命名为 querySql
            if (parameter.has("sql")) {
                connItem.set("querySql", parameter.get("sql"));
                parameter.remove("sql");
            }
        }

        // 2. HDFS / Hive 逻辑
        else if (pluginName.contains("hdfs")) {
            parameter.put("defaultFS", (String) connParams.get("defaultFS"));
            // 具体 path、fileType 等参数期望在任务定义中的 parameter 节点提供
        }

        // 3. MongoDB 逻辑
        else if (pluginName.contains("mongodb")) {
            parameter.put("address", (String) connParams.get("address")); // 例如 127.0.0.1:27017
            parameter.put("userName", (String) connParams.get("username"));
            parameter.put("userPassword", (String) connParams.get("password"));
            parameter.put("dbName", (String) connParams.get("database"));
        }

        // 4. FTP/SFTP 逻辑
        else if (pluginName.contains("ftp")) {
            parameter.put("host", (String) connParams.get("host"));
            parameter.put("port", (Integer) connParams.get("port"));
            parameter.put("username", (String) connParams.get("username"));
            parameter.put("password", (String) connParams.get("password"));
            parameter.put("protocol", (String) connParams.getOrDefault("protocol", "sftp"));
        }

        // TODO: 根据需要添加其他特定数据源的映射逻辑
    }

    private ArrayNode ensureArray(JsonNode node) {
        ArrayNode arr = JsonNodeFactory.instance.arrayNode();
        if (node == null || node.isNull()) {
            return arr;
        }
        if (node.isArray()) {
            return (ArrayNode) node;
        }
        // 字符串、数字、对象都包成单元素数组
        arr.add(node);
        return arr;
    }

    /**
     * 根据数据源参数分类型构建 JDBC 连接串
     */
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

        // 如果参数中已经包含完整的 jdbcUrl，则作为最后的兜底
        return (String) params.get("jdbcUrl");
    }
}
