package com.example.urgs_api.datasource.service;

import com.example.urgs_api.datasource.dto.ResolvedDataSourceConfigDTO;
import com.example.urgs_api.datasource.entity.DataSourceConfig;
import com.example.urgs_api.datasource.entity.DataSourceMeta;
import com.example.urgs_api.datasource.repository.DataSourceConfigMapper;
import com.example.urgs_api.datasource.repository.DataSourceMetaMapper;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.jcraft.jsch.ChannelSftp;
import com.jcraft.jsch.JSch;
import com.jcraft.jsch.Session;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.net.ftp.FTPClient;
import org.apache.commons.net.ftp.FTPReply;
import org.springframework.beans.factory.DisposableBean;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.SimpleDriverDataSource;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLClassLoader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Driver;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
public class DynamicDataSourceService implements DisposableBean {

    private static final long CACHE_TTL_MS = 30 * 60 * 1000; // 30 minutes
    private static final List<String> CHILD_FIRST_JDBC_DRIVER_PREFIXES = List.of(
            "org.apache.hive.",
            "org.apache.hadoop.hive.",
            "io.transwarp.");

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final ConcurrentHashMap<Long, CachedDataSource> dataSourceCache = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, URLClassLoader> jdbcDriverClassLoaders = new ConcurrentHashMap<>();
    private final PathMatchingResourcePatternResolver resourceResolver = new PathMatchingResourcePatternResolver();
    private final List<Path> extractedDriverJars = Collections.synchronizedList(new ArrayList<>());

    @Autowired
    private DataSourceConfigMapper configMapper;

    @Autowired
    private DataSourceMetaMapper metaMapper;

    private static class CachedDataSource {
        final HikariDataSource dataSource;
        final JdbcTemplate jdbcTemplate;
        final long createdAt;

        CachedDataSource(HikariDataSource ds) {
            this.dataSource = ds;
            this.jdbcTemplate = new JdbcTemplate(ds);
            this.createdAt = System.currentTimeMillis();
        }
    }

    /**
     * 获取数据源的数据库类型代码（如 mysql, postgresql, oracle, sqlserver, db2, clickhouse）
     */
    public String getDbType(Long dataSourceId) {
        DataSourceConfig config = configMapper.selectById(dataSourceId);
        if (config == null) {
            throw new IllegalArgumentException("DataSource not found: " + dataSourceId);
        }
        DataSourceMeta meta = metaMapper.selectById(config.getMetaId());
        if (meta == null) {
            throw new IllegalArgumentException("DataSource Meta not found for ID: " + config.getMetaId());
        }
        return meta.getCode() == null ? "" : meta.getCode().toLowerCase();
    }

    public JdbcTemplate getJdbcTemplate(Long dataSourceId) {
        CachedDataSource cached = dataSourceCache.get(dataSourceId);

        // 检查缓存是否过期
        if (cached != null && System.currentTimeMillis() - cached.createdAt > CACHE_TTL_MS) {
            dataSourceCache.remove(dataSourceId);
            try { cached.dataSource.close(); } catch (Exception e) { log.warn("Error closing expired pool: {}", e.getMessage()); }
            cached = null;
        }

        if (cached == null) {
            cached = dataSourceCache.computeIfAbsent(dataSourceId, this::createCachedDataSource);
        }

        return cached.jdbcTemplate;
    }

    public ResolvedDataSourceConfigDTO resolveConfig(Long dataSourceId) {
        DataSourceConfig config = configMapper.selectById(dataSourceId);
        if (config == null) {
            throw new IllegalArgumentException("DataSource not found: " + dataSourceId);
        }

        DataSourceMeta meta = metaMapper.selectById(config.getMetaId());
        if (meta == null) {
            throw new IllegalArgumentException("DataSource Meta not found for ID: " + config.getMetaId());
        }

        Map<String, Object> params = config.getConnectionParams();
        String type = meta.getCode() == null ? "" : meta.getCode().toLowerCase();

        ResolvedDataSourceConfigDTO dto = new ResolvedDataSourceConfigDTO();
        dto.setId(config.getId());
        dto.setName(config.getName());
        dto.setMetaId(config.getMetaId());
        dto.setTypeName(meta.getName());
        dto.setTypeCode(meta.getCode());
        dto.setCategory(meta.getCategory());
        dto.setStatus(config.getStatus());
        dto.setUrl(buildJdbcUrl(type, params));
        dto.setUsername(getString(params, "username"));
        dto.setPassword(getString(params, "password"));
        dto.setDriver(buildDriverClass(type, params));
        dto.setHost(getString(params, "host"));
        dto.setPort(getInt(params, "port", 22));
        dto.setConnectionParams(params);
        return dto;
    }

    private CachedDataSource createCachedDataSource(Long dataSourceId) {
        DataSourceConfig config = configMapper.selectById(dataSourceId);
        if (config == null) {
            throw new IllegalArgumentException("DataSource not found: " + dataSourceId);
        }

        DataSourceMeta meta = metaMapper.selectById(config.getMetaId());
        if (meta == null) {
            throw new IllegalArgumentException("DataSource Meta not found for ID: " + config.getMetaId());
        }

        Map<String, Object> params = config.getConnectionParams();
        String type = meta.getCode();

        String url = buildJdbcUrl(type, params);
        String driverClass = buildDriverClass(type, params);

        if (url.isEmpty()) {
            throw new UnsupportedOperationException("Unsupported or non-JDBC data source type: " + type);
        }

        String username = getString(params, "username");
        String password = getString(params, "password");

        HikariConfig hikariConfig = new HikariConfig();
        if (isInceptorType(type)) {
            hikariConfig.setDataSource(createDriverDataSource(type, url, driverClass, username, password));
        } else {
            hikariConfig.setJdbcUrl(url);
            hikariConfig.setDriverClassName(driverClass);
            hikariConfig.setUsername(username);
            hikariConfig.setPassword(password);
        }
        hikariConfig.setMaximumPoolSize(5);
        hikariConfig.setMinimumIdle(1);
        hikariConfig.setIdleTimeout(300_000);     // 5 minutes
        hikariConfig.setMaxLifetime(600_000);     // 10 minutes
        hikariConfig.setConnectionTimeout(10_000); // 10 seconds
        hikariConfig.setPoolName("dynamic-ds-" + dataSourceId);

        log.info("Creating connection pool for dataSourceId={}, type={}", dataSourceId, type);
        return new CachedDataSource(createHikariDataSource(type, hikariConfig));
    }

    /**
     * 清除指定数据源的缓存连接池（数据源配置更新/删除时调用）
     */
    public void evict(Long dataSourceId) {
        CachedDataSource removed = dataSourceCache.remove(dataSourceId);
        if (removed != null) {
            try { removed.dataSource.close(); } catch (Exception e) { log.warn("Error closing evicted pool: {}", e.getMessage()); }
            log.info("Evicted connection pool for dataSourceId={}", dataSourceId);
        }
    }

    @Scheduled(fixedRate = 60_000)
    public void evictExpiredPools() {
        long now = System.currentTimeMillis();
        dataSourceCache.entrySet().removeIf(entry -> {
            if (now - entry.getValue().createdAt > CACHE_TTL_MS) {
                try { entry.getValue().dataSource.close(); } catch (Exception e) { log.warn("Error closing expired pool: {}", e.getMessage()); }
                log.info("Evicted expired connection pool for dataSourceId={}", entry.getKey());
                return true;
            }
            return false;
        });
    }

    @Override
    public void destroy() {
        log.info("Shutting down {} dynamic connection pools", dataSourceCache.size());
        dataSourceCache.values().forEach(c -> {
            try { c.dataSource.close(); } catch (Exception e) { log.warn("Error closing pool on shutdown: {}", e.getMessage()); }
        });
        dataSourceCache.clear();
        jdbcDriverClassLoaders.values().forEach(loader -> {
            try { loader.close(); } catch (Exception e) { log.warn("Error closing JDBC driver loader: {}", e.getMessage()); }
        });
        jdbcDriverClassLoaders.clear();
        extractedDriverJars.forEach(path -> {
            try { Files.deleteIfExists(path); } catch (Exception e) { log.warn("Error deleting extracted JDBC driver jar {}: {}", path, e.getMessage()); }
        });
        extractedDriverJars.clear();
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

            // JDBC test: use a temporary connection (not from pool)
            String url = buildJdbcUrl(type, params);
            String driverClass = buildDriverClass(type, params);
            log.info("Testing JDBC connection type={}, driver={}, url={}", type, driverClass, url);
            testJdbcConnection(type, params, url, driverClass);
        } catch (Exception e) {
            throw new RuntimeException("Connection failed: " + e.getMessage(), e);
        }
    }

    private HikariDataSource createHikariDataSource(String type, HikariConfig hikariConfig) {
        if (!isInceptorType(type)) {
            return new HikariDataSource(hikariConfig);
        }
        ClassLoader originalClassLoader = Thread.currentThread().getContextClassLoader();
        Thread.currentThread().setContextClassLoader(resolveJdbcDriverClassLoader(type));
        try {
            return new HikariDataSource(hikariConfig);
        } finally {
            Thread.currentThread().setContextClassLoader(originalClassLoader);
        }
    }

    private void testJdbcConnection(String type, Map<String, Object> params, String url, String driverClass) throws Exception {
        ClassLoader originalClassLoader = Thread.currentThread().getContextClassLoader();
        if (isInceptorType(type)) {
            Thread.currentThread().setContextClassLoader(resolveJdbcDriverClassLoader(type));
        }
        try {
            if (isInceptorType(type)) {
                DataSource ds = createDriverDataSource(
                        type,
                        url,
                        driverClass,
                        getString(params, "username"),
                        getString(params, "password"));
                ds.getConnection().close();
                return;
            }
            org.springframework.jdbc.datasource.DriverManagerDataSource driverManagerDataSource =
                    new org.springframework.jdbc.datasource.DriverManagerDataSource();
            driverManagerDataSource.setDriverClassName(driverClass);
            driverManagerDataSource.setUrl(url);
            driverManagerDataSource.setUsername(getString(params, "username"));
            driverManagerDataSource.setPassword(getString(params, "password"));
            driverManagerDataSource.getConnection().close();
        } finally {
            Thread.currentThread().setContextClassLoader(originalClassLoader);
        }
    }

    private DataSource createDriverDataSource(
            String type,
            String url,
            String driverClass,
            String username,
            String password) {
        Driver driver = createJdbcDriver(type, driverClass);
        try {
            if (driver.acceptsURL(url)) {
                return new SimpleDriverDataSource(driver, url, username, password);
            }
        } catch (Exception e) {
            throw new IllegalStateException("Failed to validate JDBC url " + url + " with driver " + driverClass, e);
        }
        throw new IllegalStateException("JDBC driver " + driverClass + " does not accept url: " + url);
    }

    private String buildJdbcUrl(String type, Map<String, Object> params) {
        String host = getString(params, "host");
        String database = getString(params, "database");

        if ("mysql".equalsIgnoreCase(type) || "drds".equalsIgnoreCase(type)) {
            int port = getInt(params, "port", 3306);
            String jdbcParams = getString(params, "jdbcParams");
            if (jdbcParams == null || jdbcParams.isBlank()) {
                jdbcParams = "useSSL=false&serverTimezone=UTC";
            }
            return String.format("jdbc:mysql://%s:%d/%s?%s", host, port, database, jdbcParams);
        } else if ("postgresql".equalsIgnoreCase(type)) {
            int port = getInt(params, "port", 5432);
            return String.format("jdbc:postgresql://%s:%d/%s", host, port, database);
        } else if ("oracle".equalsIgnoreCase(type)) {
            int port = getInt(params, "port", 1521);
            String serviceName = getString(params, "serviceName");
            return String.format("jdbc:oracle:thin:@%s:%d:%s", host, port, serviceName);
        } else if ("sqlserver".equalsIgnoreCase(type)) {
            int port = getInt(params, "port", 1433);
            return String.format("jdbc:sqlserver://%s:%d;databaseName=%s", host, port, database);
        } else if ("db2".equalsIgnoreCase(type)) {
            int port = getInt(params, "port", 50000);
            return String.format("jdbc:db2://%s:%d/%s", host, port, database);
        } else if ("clickhouse".equalsIgnoreCase(type)) {
            int port = getInt(params, "port", 8123);
            return String.format("jdbc:clickhouse://%s:%d/%s", host, port, database);
        } else if (isInceptorType(type)) {
            String jdbcUrl = getString(params, "jdbcUrl");
            if (jdbcUrl != null && !jdbcUrl.isBlank()) {
                return normalizeInceptorJdbcUrl(jdbcUrl, getString(params, "jdbcParams"));
            }
            int port = getInt(params, "port", 10000);
            String jdbcParams = getString(params, "jdbcParams");
            if (jdbcParams == null || jdbcParams.isBlank()) {
                jdbcParams = "auth=noSasl";
            }
            String url = String.format("jdbc:inceptor2://%s:%d/%s", host, port, database);
            return normalizeInceptorJdbcUrl(url, jdbcParams);
        } else if ("generic".equalsIgnoreCase(type)) {
            return getString(params, "jdbcUrl");
        }
        return "";
    }

    private String normalizeInceptorJdbcUrl(String jdbcUrl, String jdbcParams) {
        String normalizedUrl = jdbcUrl.trim();
        if (normalizedUrl.startsWith("jdbc:hive2://")) {
            normalizedUrl = "jdbc:inceptor2://" + normalizedUrl.substring("jdbc:hive2://".length());
        }

        String normalizedParams = jdbcParams == null || jdbcParams.isBlank() ? "auth=noSasl" : jdbcParams.trim();
        String lowerUrl = normalizedUrl.toLowerCase();
        if (lowerUrl.contains(";auth=") || lowerUrl.endsWith(";auth") || lowerUrl.contains(";principal=")) {
            return normalizedUrl;
        }
        return normalizedUrl + (normalizedUrl.endsWith(";") ? "" : ";") + normalizedParams;
    }

    private String buildDriverClass(String type, Map<String, Object> params) {
        if ("mysql".equalsIgnoreCase(type) || "drds".equalsIgnoreCase(type)) {
            return "com.mysql.cj.jdbc.Driver";
        } else if ("postgresql".equalsIgnoreCase(type)) {
            return "org.postgresql.Driver";
        } else if ("oracle".equalsIgnoreCase(type)) {
            return "oracle.jdbc.OracleDriver";
        } else if ("sqlserver".equalsIgnoreCase(type)) {
            return "com.microsoft.sqlserver.jdbc.SQLServerDriver";
        } else if ("db2".equalsIgnoreCase(type)) {
            return "com.ibm.db2.jcc.DB2Driver";
        } else if ("clickhouse".equalsIgnoreCase(type)) {
            return "com.clickhouse.jdbc.ClickHouseDriver";
        } else if (isInceptorType(type)) {
            String driverClass = getString(params, "driverClass");
            return driverClass == null || driverClass.isBlank()
                    ? "org.apache.hive.jdbc.HiveDriver"
                    : driverClass;
        } else if ("generic".equalsIgnoreCase(type)) {
            return getString(params, "driverClass");
        }
        return "";
    }

    private ClassLoader resolveJdbcDriverClassLoader(String type) {
        if (!isInceptorType(type)) {
            return Thread.currentThread().getContextClassLoader();
        }
        String normalizedType = normalizeInceptorType(type);
        URLClassLoader loader = jdbcDriverClassLoaders.computeIfAbsent(normalizedType, this::createJdbcDriverClassLoader);
        return loader == null ? Thread.currentThread().getContextClassLoader() : loader;
    }

    private Driver createJdbcDriver(String type, String driverClass) {
        try {
            ClassLoader loader = resolveJdbcDriverClassLoader(type);
            Class<?> driverType = Class.forName(driverClass, true, loader);
            Object driver = driverType.getDeclaredConstructor().newInstance();
            if (!(driver instanceof Driver)) {
                throw new IllegalArgumentException(driverClass + " is not a java.sql.Driver");
            }
            return (Driver) driver;
        } catch (ClassNotFoundException e) {
            throw new IllegalStateException("JDBC driver class not found: " + driverClass
                    + ". Put the Inceptor driver jar under src/main/resources/db_deploy/drivers/xinghuan/ or use a driverClass that exists in the runtime classpath.", e);
        } catch (Exception e) {
            throw new IllegalStateException("Failed to initialize JDBC driver " + driverClass + " for " + type, e);
        }
    }

    private URLClassLoader createJdbcDriverClassLoader(String type) {
        List<URL> urls = new ArrayList<>();
        for (String driverType : resolveDriverResourceTypes(type)) {
            String pattern = "classpath*:db_deploy/drivers/" + driverType + "/*.jar";
            try {
                Resource[] resources = resourceResolver.getResources(pattern);
                for (Resource resource : resources) {
                    URL url = toDriverJarUrl(resource);
                    if (url != null) {
                        urls.add(url);
                    }
                }
            } catch (IOException e) {
                log.warn("Failed to scan JDBC driver resources for {}: {}", driverType, e.getMessage());
            }
        }

        if (urls.isEmpty()) {
            log.warn("No JDBC driver jars found under db_deploy/drivers/{} for dynamic datasource", type);
            return new URLClassLoader(new URL[0], Thread.currentThread().getContextClassLoader());
        }

        log.info("Loaded {} JDBC driver jar(s) for dynamic datasource type {}", urls.size(), type);
        return new ChildFirstJdbcDriverClassLoader(urls.toArray(new URL[0]), Thread.currentThread().getContextClassLoader());
    }

    private URL toDriverJarUrl(Resource resource) {
        try {
            if (resource.isFile()) {
                return resource.getFile().toURI().toURL();
            }
            Path tempJar = Files.createTempFile("urgs-jdbc-driver-", ".jar");
            try (InputStream inputStream = resource.getInputStream()) {
                Files.copy(inputStream, tempJar, java.nio.file.StandardCopyOption.REPLACE_EXISTING);
            }
            tempJar.toFile().deleteOnExit();
            extractedDriverJars.add(tempJar);
            return tempJar.toUri().toURL();
        } catch (IOException e) {
            log.warn("Failed to load JDBC driver jar resource {}: {}", resource.getDescription(), e.getMessage());
            return null;
        }
    }

    private List<String> resolveDriverResourceTypes(String type) {
        String normalizedType = normalizeInceptorType(type);
        if ("inceptor".equals(normalizedType)) {
            return List.of("xinghuan", "transwarp", "inceptor");
        }
        return List.of(normalizedType);
    }

    private String normalizeInceptorType(String type) {
        return type == null ? "" : type.trim().toLowerCase();
    }

    private boolean isInceptorType(String type) {
        return "inceptor".equalsIgnoreCase(type)
                || "xinghuan".equalsIgnoreCase(type)
                || "transwarp".equalsIgnoreCase(type);
    }

    private static class ChildFirstJdbcDriverClassLoader extends URLClassLoader {
        ChildFirstJdbcDriverClassLoader(URL[] urls, ClassLoader parent) {
            super(urls, parent);
        }

        @Override
        protected Class<?> loadClass(String name, boolean resolve) throws ClassNotFoundException {
            if (!shouldLoadChildFirst(name)) {
                return super.loadClass(name, resolve);
            }
            synchronized (getClassLoadingLock(name)) {
                Class<?> loadedClass = findLoadedClass(name);
                if (loadedClass == null) {
                    try {
                        loadedClass = findClass(name);
                    } catch (ClassNotFoundException ignored) {
                        loadedClass = super.loadClass(name, false);
                    }
                }
                if (resolve) {
                    resolveClass(loadedClass);
                }
                return loadedClass;
            }
        }

        private static boolean shouldLoadChildFirst(String className) {
            return CHILD_FIRST_JDBC_DRIVER_PREFIXES.stream().anyMatch(className::startsWith);
        }
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
