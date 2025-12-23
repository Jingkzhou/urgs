package com.example.urgs_api.sql.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.*;

@Service
public class SqlConsoleService {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private static final String[] FORBIDDEN_KEYWORDS = {
            "DELETE", "UPDATE", "DROP", "INSERT", "TRUNCATE", "ALTER", "GRANT", "REVOKE", "CREATE"
    };

    @Autowired
    private com.example.urgs_api.datasource.service.DynamicDataSourceService dynamicDataSourceService;

    public Map<String, Object> executeSql(String sql, Long dataSourceId) {
        Map<String, Object> result = new HashMap<>();
        try {
            // 1. Safety Check
            if (!StringUtils.hasText(sql)) {
                throw new IllegalArgumentException("SQL cannot be empty");
            }

            String upperSql = sql.trim().toUpperCase();
            for (String keyword : FORBIDDEN_KEYWORDS) {
                if (upperSql.contains(keyword)) {
                    throw new IllegalArgumentException("Operation not allowed: " + keyword);
                }
            }

            if (!upperSql.startsWith("SELECT")) {
                throw new IllegalArgumentException("Only SELECT statements are allowed");
            }

            // 2. Force LIMIT
            if (!upperSql.contains("LIMIT")) {
                sql += " LIMIT 100";
            }

            // 3. Get JdbcTemplate (Dynamic or Default)
            JdbcTemplate templateToUse = jdbcTemplate;
            if (dataSourceId != null) {
                templateToUse = dynamicDataSourceService.getJdbcTemplate(dataSourceId);
            }

            // 4. Execute
            List<Map<String, Object>> rows = templateToUse.queryForList(sql);

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
