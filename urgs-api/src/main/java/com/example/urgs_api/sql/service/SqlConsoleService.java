package com.example.urgs_api.sql.service;

import com.example.urgs_api.sql.dto.SchemaMetadataResponse;
import com.example.urgs_api.sql.dto.SqlExecuteResponse;
import lombok.extern.slf4j.Slf4j;
import net.sf.jsqlparser.parser.CCJSqlParserUtil;
import net.sf.jsqlparser.statement.Statement;
import net.sf.jsqlparser.statement.select.PlainSelect;
import net.sf.jsqlparser.statement.select.Select;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.ColumnMapRowMapper;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.sql.DatabaseMetaData;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.*;

@Slf4j
@Service
public class SqlConsoleService {

    private static final int MAX_PAGE_SIZE = 1000;
    private static final int DEFAULT_PAGE_SIZE = 100;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private com.example.urgs_api.datasource.service.DynamicDataSourceService dynamicDataSourceService;

    public SqlExecuteResponse executeSql(String sql, Long dataSourceId, Integer page, Integer pageSize) {
        SqlExecuteResponse response = new SqlExecuteResponse();
        try {
            // 1. 空值检查
            if (!StringUtils.hasText(sql)) {
                throw new IllegalArgumentException("SQL 不能为空");
            }

            String trimmedSql = sql.trim();
            // 移除末尾分号
            if (trimmedSql.endsWith(";")) {
                trimmedSql = trimmedSql.substring(0, trimmedSql.length() - 1).trim();
            }

            // 2. 使用 JSqlParser 做安全校验
            Statement statement;
            try {
                statement = CCJSqlParserUtil.parse(trimmedSql);
            } catch (Exception e) {
                throw new IllegalArgumentException("SQL 语法错误: " + e.getMessage());
            }

            if (!(statement instanceof Select)) {
                throw new IllegalArgumentException("仅允许 SELECT 查询语句");
            }

            // 3. 移除用户 SQL 中已有的 LIMIT/OFFSET（避免双重 LIMIT 问题）
            String baseSql = removeLimitOffset(statement, trimmedSql);

            // 4. 分页参数校验
            int validPage = (page != null && page > 0) ? page : 1;
            int validPageSize = (pageSize != null && pageSize > 0) ? Math.min(pageSize, MAX_PAGE_SIZE) : DEFAULT_PAGE_SIZE;
            int offset = (validPage - 1) * validPageSize;

            // 5. 获取数据库类型和 JdbcTemplate
            String dbType = resolveDbType(dataSourceId);
            JdbcTemplate templateToUse = jdbcTemplate;
            if (dataSourceId != null) {
                templateToUse = dynamicDataSourceService.getJdbcTemplate(dataSourceId);
            }

            long startTime = System.currentTimeMillis();

            // 6. 查询总行数
            String countSql = buildCountSql(baseSql);
            long totalRows = 0;
            try {
                Long count = templateToUse.queryForObject(countSql, Long.class);
                totalRows = count != null ? count : 0;
            } catch (Exception e) {
                log.warn("Count query failed, will execute without total: {}", e.getMessage());
                totalRows = -1;
            }

            // 7. 根据数据库方言生成分页 SQL
            String pagedSql = buildPagedSql(baseSql, dbType, validPageSize, offset);
            final String finalSql = pagedSql;
            List<Map<String, Object>> rows = templateToUse.query(
                    con -> {
                        PreparedStatement ps = con.prepareStatement(finalSql);
                        ps.setMaxRows(validPageSize);
                        return ps;
                    },
                    new ColumnMapRowMapper());

            long executionTimeMs = System.currentTimeMillis() - startTime;

            // 8. 提取列名
            List<String> columns = new ArrayList<>();
            if (!rows.isEmpty()) {
                columns.addAll(rows.get(0).keySet());
            }

            response.setSuccess(true);
            response.setColumns(columns);
            response.setData(rows);
            response.setExecutionTimeMs(executionTimeMs);
            response.setPage(validPage);
            response.setPageSize(validPageSize);
            response.setTotalRows(totalRows);

        } catch (IllegalArgumentException e) {
            response.setSuccess(false);
            response.setError(e.getMessage());
        } catch (Exception e) {
            log.error("SQL execution error for dataSourceId={}: {}", dataSourceId, e.getMessage(), e);
            response.setSuccess(false);
            response.setError("查询执行失败，请检查 SQL 语法和数据源连接");
        }
        return response;
    }

    /**
     * 使用 JSqlParser 移除 SELECT 语句中已有的 LIMIT 和 OFFSET 子句，返回干净的基础 SQL。
     * 如果 AST 操作失败，则回退到正则移除。
     */
    private String removeLimitOffset(Statement statement, String originalSql) {
        try {
            if (statement instanceof Select) {
                Select select = (Select) statement;
                // JSqlParser 5.x: Select 本身可能是 PlainSelect
                if (select instanceof PlainSelect) {
                    PlainSelect ps = (PlainSelect) select;
                    if (ps.getLimit() != null || ps.getOffset() != null) {
                        ps.setLimit(null);
                        ps.setOffset(null);
                        return ps.toString();
                    }
                }
                // SetOperation / 复杂查询：getPlainSelect 可能为 null
                // 此时回退到正则移除
            }
        } catch (Exception e) {
            log.debug("AST-based LIMIT removal failed, falling back to regex: {}", e.getMessage());
        }

        // 回退方案：正则移除末尾的 LIMIT ... OFFSET ... 子句
        return originalSql.replaceAll("(?i)\\s+LIMIT\\s+\\d+(\\s+OFFSET\\s+\\d+)?\\s*$", "");
    }

    /**
     * 解析数据源的数据库类型代码，默认数据源返回 "mysql"。
     */
    private String resolveDbType(Long dataSourceId) {
        if (dataSourceId == null) {
            return "mysql"; // 本地默认数据源为 MySQL
        }
        try {
            return dynamicDataSourceService.getDbType(dataSourceId);
        } catch (Exception e) {
            log.warn("Failed to resolve db type for dataSourceId={}, defaulting to mysql: {}", dataSourceId, e.getMessage());
            return "mysql";
        }
    }

    /**
     * 构建 COUNT 查询
     */
    private String buildCountSql(String baseSql) {
        return "SELECT COUNT(*) FROM (" + baseSql + ") __count_wrapper";
    }

    /**
     * 根据数据库方言构建分页 SQL。
     *
     * 支持的方言：
     *   mysql / drds / clickhouse / postgresql  → LIMIT ... OFFSET ...
     *   oracle                                  → OFFSET ... ROWS FETCH FIRST ... ROWS ONLY (Oracle 12c+)
     *   sqlserver                               → OFFSET ... ROWS FETCH NEXT ... ROWS ONLY (需要 ORDER BY)
     *   db2                                     → LIMIT ... OFFSET ...  (DB2 for LUW 11.1+)
     *   其他                                    → LIMIT ... OFFSET ... (通用回退)
     */
    private String buildPagedSql(String baseSql, String dbType, int limit, int offset) {
        if (dbType == null) {
            dbType = "mysql";
        }

        switch (dbType.toLowerCase()) {
            case "oracle":
                // Oracle 12c+ ANSI SQL 标准分页
                return baseSql + " OFFSET " + offset + " ROWS FETCH FIRST " + limit + " ROWS ONLY";

            case "sqlserver":
                // SQL Server 2012+ 要求有 ORDER BY 才能使用 OFFSET-FETCH
                // 如果用户 SQL 没有 ORDER BY，则追加 ORDER BY (SELECT 0) 作为占位
                String upperSql = baseSql.toUpperCase();
                if (!upperSql.contains("ORDER BY")) {
                    baseSql = baseSql + " ORDER BY (SELECT 0)";
                }
                return baseSql + " OFFSET " + offset + " ROWS FETCH NEXT " + limit + " ROWS ONLY";

            case "mysql":
            case "drds":
            case "clickhouse":
            case "postgresql":
            case "db2":
            default:
                // MySQL, PostgreSQL, ClickHouse, DB2 LUW 11.1+, 以及其他未知数据库
                return baseSql + " LIMIT " + limit + " OFFSET " + offset;
        }
    }

    public SchemaMetadataResponse getSchemaMetadata(Long dataSourceId) {
        JdbcTemplate templateToUse = (dataSourceId != null)
                ? dynamicDataSourceService.getJdbcTemplate(dataSourceId) : jdbcTemplate;

        return templateToUse.execute((ConnectionCallback<SchemaMetadataResponse>) con -> {
            DatabaseMetaData meta = con.getMetaData();
            String catalog = con.getCatalog();
            SchemaMetadataResponse response = new SchemaMetadataResponse();
            List<SchemaMetadataResponse.TableMeta> tables = new ArrayList<>();

            try (ResultSet rs = meta.getTables(catalog, null, "%", new String[]{"TABLE", "VIEW"})) {
                while (rs.next()) {
                    SchemaMetadataResponse.TableMeta table = new SchemaMetadataResponse.TableMeta();
                    table.setTableName(rs.getString("TABLE_NAME"));

                    List<SchemaMetadataResponse.ColumnMeta> cols = new ArrayList<>();
                    try (ResultSet colRs = meta.getColumns(catalog, null, table.getTableName(), "%")) {
                        while (colRs.next()) {
                            SchemaMetadataResponse.ColumnMeta col = new SchemaMetadataResponse.ColumnMeta();
                            col.setColumnName(colRs.getString("COLUMN_NAME"));
                            col.setDataType(colRs.getString("TYPE_NAME"));
                            col.setComment(colRs.getString("REMARKS"));
                            cols.add(col);
                        }
                    }
                    table.setColumns(cols);
                    tables.add(table);
                }
            }
            response.setTables(tables);
            return response;
        });
    }
}
