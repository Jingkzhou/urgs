package com.example.executor.quartz.service.task;

import com.alibaba.druid.pool.DruidDataSource;
import com.example.executor.quartz.domain.entity.QuartzTaskEntity;
import lombok.extern.slf4j.Slf4j;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Statement;
import java.sql.Types;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * SQL 任务执行器。
 * <p>
 * 将 exePath 字段视为多段 SQL 脚本（以 ; 分隔），逐条执行。
 * 脚本中可使用 $datadate 或 ${datadate} 作为数据日期占位符。
 * <p>
 * 停止机制：调用 cancel() 后：
 *   1. 设置 cancelled 标志，execute() 在下一条语句前检查并提前返回；
 *   2. 对当前正在执行的 Statement 调用 cancel()，使 JDBC 驱动中止当前查询。
 */
@Slf4j
public class SqlTaskExecutor implements TaskExecutor {

    private static final Pattern CALL_PATTERN = Pattern.compile(
            "^call\\s+([\\w$.]+)\\s*\\((.*)\\)\\s*$",
            Pattern.CASE_INSENSITIVE | Pattern.DOTALL
    );

    private final DruidDataSource dataSource;

    /** 当前正在执行的 Statement，用于跨线程取消 */
    private volatile Statement currentStatement;

    /** 取消标志，cancel() 设置后 execute() 尽快退出 */
    private volatile boolean cancelled = false;

    public SqlTaskExecutor(DruidDataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    public Map<String, String> execute(QuartzTaskEntity task, String dataDate, Consumer<String> logConsumer) throws Exception {
        String sqlScript = task.getExePath();
        if (sqlScript == null || sqlScript.trim().isEmpty()) {
            return failure("SQL 脚本内容为空");
        }

        // 替换日期占位符
        String processed = sqlScript
                .replace("${datadate}", dataDate)
                .replace("$datadate", dataDate);

        // 按分号拆分，过滤空语句和纯注释段落
        List<String> statements = Arrays.stream(processed.split(";"))
                .map(String::trim)
                .filter(s -> !s.isEmpty() && !isCommentOnly(s))
                .collect(Collectors.toList());

        if (statements.isEmpty()) {
            return failure("SQL 脚本中未找到有效语句");
        }

        log.info("[taskId={}][dataDate={}] 开始执行 SQL 脚本，共 {} 条语句",
                task.getId(), dataDate, statements.size());
        if (logConsumer != null) {
            logConsumer.accept(String.format("[SQL] 开始执行，共 %d 条语句", statements.size()));
        }

        try (Connection conn = dataSource.getConnection()) {
            for (int i = 0; i < statements.size(); i++) {
                if (cancelled || Thread.currentThread().isInterrupted()) {
                    if (logConsumer != null) {
                        logConsumer.accept("[SQL] 任务已被停止");
                    }
                    return failure("任务已被停止");
                }

                String stmt = statements.get(i);
                log.debug("[taskId={}][dataDate={}] 执行第 {}/{} 条语句: {}",
                        task.getId(), dataDate, i + 1, statements.size(),
                        stmt.length() > 200 ? stmt.substring(0, 200) + "..." : stmt);
                if (logConsumer != null) {
                    String compactSql = stmt.replaceAll("\\s+", " ").trim();
                    logConsumer.accept(String.format("[SQL] 执行第 %d/%d 条: %s", i + 1, statements.size(),
                            compactSql.length() > 400 ? compactSql.substring(0, 400) + "..." : compactSql));
                }

                try {
                    executeStatement(conn, stmt, dataDate, logConsumer);
                    if (logConsumer != null) {
                        logConsumer.accept(String.format("[SQL] 第 %d/%d 条执行成功", i + 1, statements.size()));
                    }
                } catch (Exception e) {
                    currentStatement = null;
                    if (cancelled || Thread.currentThread().isInterrupted()) {
                        if (logConsumer != null) {
                            logConsumer.accept("[SQL] 任务已被停止");
                        }
                        return failure("任务已被停止");
                    }
                    if (logConsumer != null) {
                        logConsumer.accept(String.format("[SQL] 第 %d/%d 条执行失败: %s",
                                i + 1, statements.size(), trimTo500(e.getMessage())));
                    }
                    return failure(String.format("第 %d/%d 条 SQL 执行失败: %s",
                            i + 1, statements.size(), trimTo500(e.getMessage())));
                }
                currentStatement = null;
            }
        }

        String msg = String.format("SQL 脚本执行完成，共执行 %d 条语句", statements.size());
        log.info("[taskId={}][dataDate={}] {}", task.getId(), dataDate, msg);
        if (logConsumer != null) {
            logConsumer.accept("[SQL] " + msg);
        }
        return success(msg);
    }

    @Override
    public void cancel() {
        cancelled = true;
        Statement s = currentStatement;
        if (s != null) {
            try {
                s.cancel();
                log.info("SQL statement cancel() called");
            } catch (Exception e) {
                log.warn("Cancel SQL statement failed: {}", e.getMessage());
            }
        }
    }

    private void executeStatement(Connection conn, String stmt, String dataDate, Consumer<String> logConsumer) throws Exception {
        Matcher matcher = CALL_PATTERN.matcher(stmt.trim());
        if (matcher.matches()) {
            executeCallable(conn, matcher.group(1), matcher.group(2), dataDate, logConsumer);
            return;
        }

        try (Statement s = conn.createStatement()) {
            currentStatement = s;
            s.execute(stmt);
        } finally {
            currentStatement = null;
        }
    }

    private void executeCallable(Connection conn, String procedureName, String argsText, String dataDate, Consumer<String> logConsumer) throws Exception {
        int paramCount = countParams(argsText);
        String callableSql = buildCallableSql(procedureName, paramCount);
        try (CallableStatement cs = conn.prepareCall(callableSql)) {
            currentStatement = cs;
            bindCallableParams(cs, paramCount, dataDate);
            cs.execute();
            String resultCode = readOutParam(cs, 2, paramCount);
            String errMsg = readOutParam(cs, 3, paramCount);
            logCallableOutParams(resultCode, errMsg, logConsumer);
            if (paramCount >= 2 && !"0".equals(resultCode)) {
                String message = (errMsg == null || errMsg.isBlank())
                        ? "存储过程返回失败状态: " + resultCode
                        : errMsg;
                throw new RuntimeException(message);
            }
        } finally {
            currentStatement = null;
        }
    }

    private void bindCallableParams(CallableStatement cs, int paramCount, String dataDate) throws Exception {
        if (paramCount >= 1) {
            cs.setString(1, dataDate);
        }
        if (paramCount >= 2) {
            cs.registerOutParameter(2, Types.VARCHAR);
        }
        if (paramCount >= 3) {
            cs.registerOutParameter(3, Types.VARCHAR);
        }
        for (int i = 4; i <= paramCount; i++) {
            cs.registerOutParameter(i, Types.VARCHAR);
        }
    }

    private void logCallableOutParams(String resultCode, String errMsg, Consumer<String> logConsumer) {
        if (logConsumer == null) {
            return;
        }
        logConsumer.accept("[SQL] 输出参数 p_result: " + trimTo500(resultCode));
        logConsumer.accept("[SQL] 输出参数 p_errmsg: " + trimTo500(errMsg));
    }

    private String readOutParam(CallableStatement cs, int index, int paramCount) throws Exception {
        if (index > paramCount) {
            return null;
        }
        return cs.getString(index);
    }

    private int countParams(String argsText) {
        String trimmed = argsText == null ? "" : argsText.trim();
        if (trimmed.isEmpty()) {
            return 0;
        }
        return (int) Arrays.stream(trimmed.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .count();
    }

    private String buildCallableSql(String procedureName, int paramCount) {
        if (paramCount <= 0) {
            return "{call " + procedureName + "}";
        }
        String placeholders = String.join(",", java.util.Collections.nCopies(paramCount, "?"));
        return "{call " + procedureName + "(" + placeholders + ")}";
    }

    // ===== 工具方法 =====

    /**
     * 判断一段文本是否全为注释行（-- 开头）或空行，无可执行 SQL。
     */
    private boolean isCommentOnly(String block) {
        for (String line : block.split("\n")) {
            String trimmed = line.trim();
            if (!trimmed.isEmpty() && !trimmed.startsWith("--")) {
                return false;
            }
        }
        return true;
    }

    private Map<String, String> success(String msg) {
        Map<String, String> result = new HashMap<>();
        result.put("code", "0");
        result.put("msg", msg);
        return result;
    }

    private Map<String, String> failure(String msg) {
        Map<String, String> result = new HashMap<>();
        result.put("code", "-1");
        result.put("msg", msg);
        return result;
    }

    private String trimTo500(String value) {
        if (value == null) return null;
        return value.length() > 500 ? value.substring(0, 500) : value;
    }
}
