package com.example.urgs_api.sql.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import org.springframework.jdbc.core.ColumnMapRowMapper;
import java.sql.PreparedStatement;
import java.util.*;

@Service
public class SqlConsoleService {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private com.example.urgs_api.datasource.service.DynamicDataSourceService dynamicDataSourceService;

    public Map<String, Object> executeSql(String sql, Long dataSourceId) {
        Map<String, Object> result = new HashMap<>();
        try {
            // 1. Safety Check
            if (!StringUtils.hasText(sql)) {
                throw new IllegalArgumentException("SQL cannot be empty");
            }

            String trimmedSql = sql.trim();
            String upperSql = trimmedSql.toUpperCase();

            // 1. Enforce SELECT
            if (!upperSql.startsWith("SELECT")) {
                throw new IllegalArgumentException("Only SELECT statements are allowed");
            }

            // 2. Prevent Multiple Statements (SQL Injection / DDL after ;)
            // Check if there is a semicolon followed by non-whitespace content
            if (trimmedSql.matches("(?si).+;\\s*\\S.*")) {
                throw new IllegalArgumentException("Multi-statement execution allowed");
            }

            // 2. Force LIMIT (Removed: using setMaxRows instead for better compatibility
            // and strict enforcement)
            // if (!upperSql.contains("LIMIT")) {
            // sql += " LIMIT 100";
            // }

            // 3. Get JdbcTemplate (Dynamic or Default)
            JdbcTemplate templateToUse = jdbcTemplate;
            if (dataSourceId != null) {
                templateToUse = dynamicDataSourceService.getJdbcTemplate(dataSourceId);
            }

            // 4. Execute with Max Rows Limit
            List<Map<String, Object>> rows = templateToUse.query(
                    con -> {
                        PreparedStatement ps = con.prepareStatement(sql);
                        ps.setMaxRows(10); // Strict limit as per requirement
                        return ps;
                    },
                    new ColumnMapRowMapper());

            // 5. Extract Columns
            Set<String> columns = new LinkedHashSet<>();
            if (!rows.isEmpty()) {
                columns.addAll(rows.get(0).keySet());
            }

            result.put("success", true);
            result.put("columns", columns);
            result.put("data", rows);

        } catch (Exception e) {
            result.put("success", false);
            result.put("error", e.getMessage());
        }
        return result;
    }
}
