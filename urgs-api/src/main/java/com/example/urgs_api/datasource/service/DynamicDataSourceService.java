package com.example.urgs_api.datasource.service;

import com.example.urgs_api.datasource.entity.DataSourceConfig;
import com.example.urgs_api.datasource.entity.DataSourceMeta;
import com.example.urgs_api.datasource.repository.DataSourceConfigMapper;
import com.example.urgs_api.datasource.repository.DataSourceMetaMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class DynamicDataSourceService {

    @Autowired
    private DataSourceConfigMapper configMapper;

    @Autowired
    private DataSourceMetaMapper metaMapper;

    public JdbcTemplate getJdbcTemplate(Long dataSourceId) {
        DataSourceConfig config = configMapper.selectById(dataSourceId);
        if (config == null) {
            throw new IllegalArgumentException("DataSource not found: " + dataSourceId);
        }

        DataSourceMeta meta = metaMapper.selectById(config.getMetaId());
        if (meta == null) {
            throw new IllegalArgumentException("DataSource Meta not found for config: " + dataSourceId);
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
}
