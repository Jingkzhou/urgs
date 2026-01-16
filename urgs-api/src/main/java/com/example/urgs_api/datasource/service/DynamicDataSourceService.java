package com.example.urgs_api.datasource.service;

import com.example.urgs_api.datasource.entity.DataSourceConfig;
import com.example.urgs_api.datasource.entity.DataSourceMeta;
import com.example.urgs_api.datasource.repository.DataSourceConfigMapper;
import com.example.urgs_api.datasource.repository.DataSourceMetaMapper;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.jcraft.jsch.ChannelSftp;
import com.jcraft.jsch.JSch;
import com.jcraft.jsch.Session;
import org.apache.commons.net.ftp.FTPClient;
import org.apache.commons.net.ftp.FTPReply;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

@Service
public class DynamicDataSourceService {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    private DataSourceConfigMapper configMapper;

    @Autowired
    private DataSourceMetaMapper metaMapper;

    public JdbcTemplate getJdbcTemplate(Long dataSourceId) {
        DataSourceConfig config = configMapper.selectById(dataSourceId);
        if (config == null) {
            throw new IllegalArgumentException("DataSource not found: " + dataSourceId);
        }
        return buildJdbcTemplate(config);
    }

    public void testConnection(DataSourceConfig config) {
        if (config == null) {
            throw new IllegalArgumentException("DataSource config is required");
        }

        DataSourceMeta meta = metaMapper.selectById(config.getMetaId());
        if (meta == null) {
            throw new IllegalArgumentException("DataSource Meta not found for ID: " + config.getMetaId());
        }

        Map<String, Object> params = config.getConnectionParams();
        if (params == null) {
            throw new IllegalArgumentException("Connection params is required");
        }

        String type = meta.getCode() == null ? "" : meta.getCode().toLowerCase();
        try {
            if ("http".equals(type)) {
                testHttpConnection(params);
                return;
            }
            if ("ssh".equals(type)) {
                testSshConnection(params);
                return;
            }
            if ("ftp".equals(type)) {
                testFtpConnection(params);
                return;
            }
            if ("sftp".equals(type)) {
                testSftpConnection(params);
                return;
            }
            if ("elasticsearch".equals(type) || "opentsdb".equals(type) || "tsdb".equals(type)) {
                testHttpEndpoint(params);
                return;
            }

            JdbcTemplate jdbcTemplate = buildJdbcTemplate(config);
            // Short timeout for testing
            jdbcTemplate.getDataSource().getConnection().close();
        } catch (Exception e) {
            throw new RuntimeException("Connection failed: " + e.getMessage(), e);
        }
    }

    private JdbcTemplate buildJdbcTemplate(DataSourceConfig config) {
        DataSourceMeta meta = metaMapper.selectById(config.getMetaId());
        if (meta == null) {
            throw new IllegalArgumentException("DataSource Meta not found for ID: " + config.getMetaId());
        }

        Map<String, Object> params = config.getConnectionParams();
        String type = meta.getCode();

        DriverManagerDataSource dataSource = new DriverManagerDataSource();

        // Basic RDBMS support
        String host = getString(params, "host");
        String database = getString(params, "database");
        String username = getString(params, "username");
        String password = getString(params, "password");

        // Handle JDBC URL construction based on type
        String url = "";
        String driverClass = "";

        if ("mysql".equalsIgnoreCase(type) || "drds".equalsIgnoreCase(type)) {
            int port = getInt(params, "port", 3306);
            String jdbcParams = getString(params, "jdbcParams");
            if (jdbcParams == null || jdbcParams.isBlank()) {
                jdbcParams = "useSSL=false&serverTimezone=UTC";
            }
            url = String.format("jdbc:mysql://%s:%d/%s?%s", host, port, database, jdbcParams);
            driverClass = "com.mysql.cj.jdbc.Driver";
        } else if ("postgresql".equalsIgnoreCase(type)) {
            int port = getInt(params, "port", 5432);
            url = String.format("jdbc:postgresql://%s:%d/%s", host, port, database);
            driverClass = "org.postgresql.Driver";
        } else if ("oracle".equalsIgnoreCase(type)) {
            int port = getInt(params, "port", 1521);
            String serviceName = getString(params, "serviceName");
            url = String.format("jdbc:oracle:thin:@%s:%d:%s", host, port, serviceName);
            driverClass = "oracle.jdbc.OracleDriver";
        } else if ("sqlserver".equalsIgnoreCase(type)) {
            int port = getInt(params, "port", 1433);
            url = String.format("jdbc:sqlserver://%s:%d;databaseName=%s", host, port, database);
            driverClass = "com.microsoft.sqlserver.jdbc.SQLServerDriver";
        } else if ("db2".equalsIgnoreCase(type)) {
            int port = getInt(params, "port", 50000);
            url = String.format("jdbc:db2://%s:%d/%s", host, port, database);
            driverClass = "com.ibm.db2.jcc.DB2Driver";
        } else if ("clickhouse".equalsIgnoreCase(type)) {
            int port = getInt(params, "port", 8123);
            url = String.format("jdbc:clickhouse://%s:%d/%s", host, port, database);
            driverClass = "com.clickhouse.jdbc.ClickHouseDriver";
        } else if ("generic".equalsIgnoreCase(type)) {
            url = getString(params, "jdbcUrl");
            driverClass = getString(params, "driverClass");
        }

        if (url.isEmpty()) {
            throw new UnsupportedOperationException("Unsupported or non-JDBC data source type: " + type);
        }

        dataSource.setDriverClassName(driverClass);
        dataSource.setUrl(url);
        dataSource.setUsername(username);
        dataSource.setPassword(password);

        return new JdbcTemplate(dataSource);
    }

    private String getString(Map<String, Object> params, String key) {
        Object val = params.get(key);
        if (val == null) {
            return null;
        }
        return String.valueOf(val);
    }

    private int getInt(Map<String, Object> params, String key, int defaultValue) {
        Object val = params.get(key);
        if (val == null) {
            return defaultValue;
        }
        if (val instanceof Number) {
            return ((Number) val).intValue();
        }
        try {
            return Integer.parseInt(String.valueOf(val));
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }

    private void testHttpConnection(Map<String, Object> params) throws Exception {
        String url = getString(params, "url");
        if (url == null || url.isBlank()) {
            throw new IllegalArgumentException("HTTP url is required");
        }
        String method = getString(params, "method");
        if (method == null || method.isBlank()) {
            method = "GET";
        }
        Map<String, String> headers = parseHeaders(getString(params, "headers"));
        sendHttpRequest(url, method.toUpperCase(), headers);
    }

    private void testHttpEndpoint(Map<String, Object> params) throws Exception {
        String endpoint = getString(params, "endpoint");
        if (endpoint == null || endpoint.isBlank()) {
            throw new IllegalArgumentException("Endpoint is required");
        }
        Map<String, String> headers = new HashMap<>();
        String username = getString(params, "username");
        String password = getString(params, "password");
        if (username != null && !username.isBlank() && password != null) {
            String token = Base64.getEncoder().encodeToString(
                    (username + ":" + password).getBytes(StandardCharsets.UTF_8));
            headers.put("Authorization", "Basic " + token);
        }
        sendHttpRequest(endpoint, "GET", headers);
    }

    private void sendHttpRequest(String url, String method, Map<String, String> headers) throws Exception {
        HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
        conn.setConnectTimeout(5000);
        conn.setReadTimeout(5000);
        conn.setRequestMethod(method);
        conn.setInstanceFollowRedirects(true);

        if (headers != null) {
            for (Map.Entry<String, String> entry : headers.entrySet()) {
                if (entry.getKey() != null && entry.getValue() != null) {
                    conn.setRequestProperty(entry.getKey(), entry.getValue());
                }
            }
        }

        int code = conn.getResponseCode();
        InputStream stream = code >= 400 ? conn.getErrorStream() : conn.getInputStream();
        if (stream != null) {
            stream.close();
        }
        conn.disconnect();

        if (code >= 400) {
            throw new RuntimeException("HTTP request failed with status " + code);
        }
    }

    private Map<String, String> parseHeaders(String headersJson) {
        if (headersJson == null || headersJson.isBlank()) {
            return Collections.emptyMap();
        }
        try {
            Map<String, Object> raw = objectMapper.readValue(headersJson,
                    new TypeReference<Map<String, Object>>() {
                    });
            Map<String, String> headers = new HashMap<>();
            for (Map.Entry<String, Object> entry : raw.entrySet()) {
                if (entry.getValue() != null) {
                    headers.put(entry.getKey(), String.valueOf(entry.getValue()));
                }
            }
            return headers;
        } catch (Exception e) {
            throw new IllegalArgumentException("Headers JSON parse failed: " + e.getMessage(), e);
        }
    }

    private void testSshConnection(Map<String, Object> params) throws Exception {
        String host = getString(params, "host");
        String username = getString(params, "username");
        String password = getString(params, "password");
        int port = getInt(params, "port", 22);

        if (host == null || username == null) {
            throw new IllegalArgumentException("SSH host and username are required");
        }

        JSch jsch = new JSch();
        Session session = jsch.getSession(username, host, port);
        if (password != null && !password.isBlank()) {
            session.setPassword(password);
        }

        // Fix for "Auth fail": Explicitly allow keyboard-interactive and password
        // Some servers behave differently or default to one over the other
        java.util.Properties config = new java.util.Properties();
        config.put("StrictHostKeyChecking", "no");
        config.put("PreferredAuthentications", "publickey,keyboard-interactive,password");
        session.setConfig(config);

        try {
            session.connect(10000);
        } finally {
            if (session.isConnected()) {
                session.disconnect();
            }
        }
    }

    private void testSftpConnection(Map<String, Object> params) throws Exception {
        String host = getString(params, "host");
        String username = getString(params, "username");
        String password = getString(params, "password");
        int port = getInt(params, "port", 22);
        String rootPath = getString(params, "rootPath");

        if (host == null || username == null) {
            throw new IllegalArgumentException("SFTP host and username are required");
        }

        JSch jsch = new JSch();
        Session session = jsch.getSession(username, host, port);
        if (password != null && !password.isBlank()) {
            session.setPassword(password);
        }
        if (password != null && !password.isBlank()) {
            session.setPassword(password);
        }

        // Fix for "Auth fail": Explicitly allow keyboard-interactive and password
        java.util.Properties config = new java.util.Properties();
        config.put("StrictHostKeyChecking", "no");
        config.put("PreferredAuthentications", "publickey,keyboard-interactive,password");
        session.setConfig(config);

        ChannelSftp channel = null;

        try {
            session.connect(10000);
            channel = (ChannelSftp) session.openChannel("sftp");
            channel.connect(10000);
            if (rootPath != null && !rootPath.isBlank()) {
                channel.cd(rootPath);
            }
        } finally {
            if (channel != null && channel.isConnected()) {
                channel.disconnect();
            }
            if (session.isConnected()) {
                session.disconnect();
            }
        }
    }

    private void testFtpConnection(Map<String, Object> params) throws Exception {
        String host = getString(params, "host");
        String username = getString(params, "username");
        String password = getString(params, "password");
        int port = getInt(params, "port", 21);
        String rootPath = getString(params, "rootPath");

        if (host == null || username == null) {
            throw new IllegalArgumentException("FTP host and username are required");
        }

        FTPClient client = new FTPClient();
        client.setConnectTimeout(10000);

        try {
            client.connect(host, port);
            int replyCode = client.getReplyCode();
            if (!FTPReply.isPositiveCompletion(replyCode)) {
                throw new RuntimeException("FTP connect failed: " + client.getReplyString());
            }
            if (!client.login(username, password)) {
                throw new RuntimeException("FTP login failed: " + client.getReplyString());
            }
            client.enterLocalPassiveMode();
            if (rootPath != null && !rootPath.isBlank() && !client.changeWorkingDirectory(rootPath)) {
                throw new RuntimeException("FTP root path not found: " + rootPath);
            }
        } finally {
            if (client.isConnected()) {
                try {
                    client.logout();
                } finally {
                    client.disconnect();
                }
            }
        }
    }
}
