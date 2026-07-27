package com.example.executor.quartz.service.task;

import com.example.executor.datasource.ResolvedDataSourceConfig;
import com.example.executor.quartz.domain.entity.QuartzTaskEntity;
import com.jcraft.jsch.ChannelExec;
import com.jcraft.jsch.JSch;
import com.jcraft.jsch.JSchException;
import com.jcraft.jsch.Session;
import lombok.extern.slf4j.Slf4j;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import java.util.function.Consumer;

/**
 * Shell 脚本执行器。
 * <p>
 * 将 exePath 字段视为完整的 Shell 脚本内容，通过 SSH 管道传入远程 bash 执行。
 * 脚本中可直接使用 $datadate 变量（执行器自动在脚本首行注入）。
 * <p>
 * 执行方式：
 *   在远程主机执行 {@code bash -s}，将脚本内容写入 stdin；
 *   远程 bash 读取 stdin 执行脚本，exit code 0 视为成功，非 0 视为失败。
 * <p>
 * 停止机制：调用 cancel() 后：
 *   1. 设置 cancelled 标志；
 *   2. 断开 ChannelExec 和 SSH Session，远程 bash 进程收到 SIGHUP 后退出；
 *   3. 若远程进程使用 nohup/trap 忽略 SIGHUP，建议在脚本中主动检测 datadate 锁文件实现幂等。
 */
@Slf4j
public class ShellScriptExecutor implements TaskExecutor {

    private static final String LEGACY_KEY_EXCHANGE_ALGORITHMS =
            "diffie-hellman-group-exchange-sha1,diffie-hellman-group14-sha1,diffie-hellman-group1-sha1";
    private static final String LEGACY_SERVER_HOST_KEY_ALGORITHMS =
            "ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,ssh-rsa,ssh-dss";

    private final ResolvedDataSourceConfig dataSourceConfig;

    public ShellScriptExecutor(ResolvedDataSourceConfig dataSourceConfig) {
        this.dataSourceConfig = dataSourceConfig;
    }

    /** 当前 SSH 会话，用于跨线程取消 */
    private volatile Session sshSession;

    /** 当前执行通道，用于跨线程取消 */
    private volatile ChannelExec execChannel;

    /** 取消标志 */
    private volatile boolean cancelled = false;

    @Override
    public Map<String, String> execute(QuartzTaskEntity task, String dataDate, Consumer<String> logConsumer) throws Exception {
        String scriptContent = task.getExePath();
        if (scriptContent == null || scriptContent.trim().isEmpty()) {
            return failure("Shell 脚本内容为空");
        }

        // 在脚本首部自动注入 datadate 变量，脚本中可直接使用 $datadate
        String fullScript = buildScript(dataDate, scriptContent);

        Session session = null;
        ChannelExec channel = null;
        InputStream stdout = null;

        try {
            // ① 建立 SSH 连接
            session = connectSsh(task);
            sshSession = session;

            if (cancelled || Thread.currentThread().isInterrupted()) {
                return failure("任务已被停止");
            }

            // ② 打开 exec 通道，通过 stdin 管道传入脚本
            channel = (ChannelExec) session.openChannel("exec");
            channel.setCommand("bash -s 2>&1");
            channel.setInputStream(
                    new ByteArrayInputStream(fullScript.getBytes(StandardCharsets.UTF_8))
            );
            execChannel = channel;
            channel.connect();

            log.debug("[taskId={}][dataDate={}] Shell 脚本已提交，等待执行完成...",
                    task.getId(), dataDate);
            if (logConsumer != null) {
                logConsumer.accept("[SHELL] 脚本已提交，开始执行");
            }

            // ③ 读取 stdout（取最后一行作为摘要）
            stdout = channel.getInputStream();
            String lastLine = readOutput(stdout, logConsumer);

            // ④ 等待通道关闭（即脚本执行完毕）
            waitForClose(channel);

            if (cancelled || Thread.currentThread().isInterrupted()) {
                return failure("任务已被停止");
            }

            int exitCode = channel.getExitStatus();
            if (exitCode == 0) {
                log.debug("[taskId={}][dataDate={}] Shell 脚本执行成功", task.getId(), dataDate);
                if (logConsumer != null) {
                    logConsumer.accept("[SHELL] 执行成功");
                }
                return success("Shell 脚本执行成功");
            }

            String errorMsg = lastLine != null && !lastLine.isEmpty()
                    ? lastLine
                    : "exit code=" + exitCode;
            log.warn("[taskId={}][dataDate={}] Shell 脚本执行失败，exit code={}, 最后输出: {}",
                    task.getId(), dataDate, exitCode, errorMsg);
            if (logConsumer != null) {
                logConsumer.accept("[SHELL] 执行失败，exitCode=" + exitCode + "，最后输出: " + trimTo500(errorMsg));
            }
            return failure(String.format("Shell 脚本执行失败，exit code=%d，输出: %s",
                    exitCode, trimTo500(errorMsg)));

        } catch (Exception e) {
            if (cancelled || Thread.currentThread().isInterrupted()) {
                return failure("任务已被停止");
            }
            log.error("[taskId={}][dataDate={}] Shell 脚本执行异常", task.getId(), dataDate, e);
            if (logConsumer != null) {
                logConsumer.accept("[SHELL] 执行异常: " + trimTo500(e.getMessage()));
            }
            return failure("Shell 脚本执行异常: " + trimTo500(e.getMessage()));
        } finally {
            closeQuietly(stdout);
            disconnectQuietly(channel);
            disconnectQuietly(session);
        }
    }

    @Override
    public void cancel() {
        cancelled = true;
        // 先断 channel，再断 session，确保远程进程收到 HUP 信号
        ChannelExec ch = execChannel;
        Session sess = sshSession;
        if (ch != null) {
            try {
                ch.disconnect();
            } catch (Exception e) {
                log.warn("Disconnect exec channel failed on cancel: {}", e.getMessage());
            }
        }
        if (sess != null) {
            try {
                sess.disconnect();
            } catch (Exception e) {
                log.warn("Disconnect SSH session failed on cancel: {}", e.getMessage());
            }
        }
        log.info("ShellScriptExecutor cancelled");
    }

    // ===== 私有方法 =====

    /**
     * 构造完整脚本：首行注入 datadate 变量，其余为原始脚本。
     */
    private String buildScript(String dataDate, String scriptContent) {
        return "#!/bin/bash\n"
                + "datadate=" + dataDate + "\n"
                + "export datadate\n"
                + "\n"
                + scriptContent
                + "\n";
    }

    private Session connectSsh(QuartzTaskEntity task) throws Exception {
        try {
            return connectSsh(task, false);
        } catch (JSchException e) {
            if (!isAlgorithmNegotiationFailure(e)) {
                throw e;
            }
            log.warn("SSH default algorithm negotiation failed for taskId={}, retrying with legacy SSH algorithms",
                    task.getId());
            return connectSsh(task, true);
        }
    }

    private Session connectSsh(QuartzTaskEntity task, boolean useLegacyAlgorithms) throws Exception {
        if (dataSourceConfig == null || dataSourceConfig.getHost() == null || dataSourceConfig.getUsername() == null) {
            throw new IllegalArgumentException("Shell 任务缺少可用的数据源连接配置");
        }
        JSch jsch = new JSch();
        int port = dataSourceConfig.getPort() == null ? 22 : dataSourceConfig.getPort();
        Session session = jsch.getSession(dataSourceConfig.getUsername(), dataSourceConfig.getHost(), port);
        session.setPassword(dataSourceConfig.getPassword());
        session.setTimeout(6_000_000);
        Properties config = new Properties();
        config.put("StrictHostKeyChecking", "no");
        if (useLegacyAlgorithms) {
            config.put("kex", LEGACY_KEY_EXCHANGE_ALGORITHMS);
            config.put("server_host_key", LEGACY_SERVER_HOST_KEY_ALGORITHMS);
        }
        session.setConfig(config);
        try {
            session.connect();
            return session;
        } catch (Exception e) {
            session.disconnect();
            throw e;
        }
    }

    private boolean isAlgorithmNegotiationFailure(JSchException exception) {
        Throwable current = exception;
        while (current != null) {
            String message = current.getMessage();
            if (message != null && message.toLowerCase().contains("algorithm negotiation fail")) {
                return true;
            }
            current = current.getCause();
        }
        return false;
    }

    /**
     * 逐行读取 stdout，遇到取消或中断则停止，返回最后一行。
     */
    private String readOutput(InputStream in, Consumer<String> logConsumer) {
        String lastLine = null;
        try {
            BufferedReader reader = new BufferedReader(
                    new InputStreamReader(in, StandardCharsets.UTF_8));
            String line;
            while ((line = reader.readLine()) != null) {
                if (cancelled || Thread.currentThread().isInterrupted()) break;
                if (!line.trim().isEmpty()) {
                    lastLine = line;
                    if (logConsumer != null) {
                        logConsumer.accept(line);
                    }
                }
            }
        } catch (Exception e) {
            // channel 被 cancel() 断开时 readLine() 会抛异常，属正常情况
            if (!cancelled) {
                log.warn("Read stdout interrupted: {}", e.getMessage());
            }
        }
        return lastLine;
    }

    /**
     * 轮询等待 channel 关闭，每 200ms 检查一次取消标志。
     */
    private void waitForClose(ChannelExec channel) {
        try {
            while (!channel.isClosed()) {
                if (cancelled || Thread.currentThread().isInterrupted()) break;
                Thread.sleep(200);
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private void disconnectQuietly(ChannelExec ch) {
        if (ch != null) {
            try { ch.disconnect(); } catch (Exception ignore) {}
        }
    }

    private void disconnectQuietly(Session sess) {
        if (sess != null) {
            try { sess.disconnect(); } catch (Exception ignore) {}
        }
    }

    private void closeQuietly(AutoCloseable c) {
        if (c != null) {
            try { c.close(); } catch (Exception ignore) {}
        }
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
