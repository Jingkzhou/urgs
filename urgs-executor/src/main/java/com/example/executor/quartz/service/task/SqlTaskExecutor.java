package com.example.executor.quartz.service.task;

import com.alibaba.druid.pool.DruidDataSource;
import com.example.executor.quartz.domain.entity.QuartzTaskEntity;
import lombok.extern.slf4j.Slf4j;

import java.sql.Connection;
import java.sql.Statement;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
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

    private final DruidDataSource dataSource;

    /** 当前正在执行的 Statement，用于跨线程取消 */
    private volatile Statement currentStatement;

    /** 取消标志，cancel() 设置后 execute() 尽快退出 */
    private volatile boolean cancelled = false;

    public SqlTaskExecutor(DruidDataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    public Map<String, String> execute(QuartzTaskEntity task, String dataDate) throws Exception {
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

        try (Connection conn = dataSource.getConnection()) {
            for (int i = 0; i < statements.size(); i++) {
                if (cancelled || Thread.currentThread().isInterrupted()) {
                    return failure("任务已被停止");
                }

                String stmt = statements.get(i);
                log.debug("[taskId={}][dataDate={}] 执行第 {}/{} 条语句: {}",
                        task.getId(), dataDate, i + 1, statements.size(),
                        stmt.length() > 200 ? stmt.substring(0, 200) + "..." : stmt);

                try (Statement s = conn.createStatement()) {
                    currentStatement = s;
                    s.execute(stmt);
                } catch (Exception e) {
                    currentStatement = null;
                    if (cancelled || Thread.currentThread().isInterrupted()) {
                        return failure("任务已被停止");
                    }
                    return failure(String.format("第 %d/%d 条 SQL 执行失败: %s",
                            i + 1, statements.size(), trimTo500(e.getMessage())));
                }
                currentStatement = null;
            }
        }

        String msg = String.format("SQL 脚本执行完成，共执行 %d 条语句", statements.size());
        log.info("[taskId={}][dataDate={}] {}", task.getId(), dataDate, msg);
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
