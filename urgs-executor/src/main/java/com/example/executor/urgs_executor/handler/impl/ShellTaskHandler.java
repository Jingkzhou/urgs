package com.example.executor.urgs_executor.handler.impl;

import com.example.executor.urgs_executor.entity.DataSourceConfig;
import com.example.executor.urgs_executor.entity.ExecutorTaskInstance;
import com.example.executor.urgs_executor.handler.TaskHandler;
import com.example.executor.urgs_executor.mapper.DataSourceConfigMapper;
import com.example.executor.urgs_executor.mapper.ExecutorTaskInstanceMapper;
import com.example.executor.urgs_executor.util.PlaceholderUtils;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.jcraft.jsch.ChannelExec;
import com.jcraft.jsch.JSch;
import com.jcraft.jsch.Session;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;

/**
 * Shell 任务处理器
 * 负责执行 Shell 脚本，支持本地执行和通过 SSH 远程执行。
 */
@Slf4j
@Component("SHELL")
public class ShellTaskHandler implements TaskHandler {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    private DataSourceConfigMapper dataSourceConfigMapper;

    @Autowired
    private ExecutorTaskInstanceMapper taskInstanceMapper;

    /**
     * 同步更新任务实例的日志内容
     * 
     * @param instance 任务实例
     * @param content  日志内容
     */

    private void updateLog(ExecutorTaskInstance instance, String content) {
        UpdateWrapper<ExecutorTaskInstance> update = new UpdateWrapper<>();
        update.eq("id", instance.getId());
        update.set("log_content", content);
        taskInstanceMapper.update(null, update);
        instance.setLogContent(content);
    }

    /**
     * 执行 Shell 任务的主入口
     * 
     * @param instance 任务实例信息
     * @return 执行产生的日志内容
     */
    @Override
    public String execute(ExecutorTaskInstance instance) throws Exception {
        String script = "";
        String resourceId = null;

        // 1. 从内容快照中解析脚本内容和资源节点信息
        if (instance.getContentSnapshot() != null) {
            JsonNode node = objectMapper.readTree(instance.getContentSnapshot());
            if (node.has("rawScript")) {
                script = node.get("rawScript").asText();
            } else if (node.has("script")) {
                script = node.get("script").asText();
            }

            if (node.has("resource")) {
                resourceId = node.get("resource").asText();
            }
        }

        // 2. 校验脚本是否为空
        if (script.isEmpty()) {
            log.error("Shell task {} script is empty. Content Snapshot: {}", instance.getId(),
                    instance.getContentSnapshot());
            throw new RuntimeException("Shell task " + instance.getId() + " has no script content");
        }

        // 3. 变量替换：将 $dataDate 替换为实例对应的业务日期
        script = PlaceholderUtils.replaceDataDate(script, instance.getDataDate());

        log.info("Executing Shell Task {}: {}", instance.getId(), script);

        // 4. 根据是否配置了 resourceId 决定是远程执行还是本地执行
        if (resourceId != null && !resourceId.isEmpty()) {
            return executeRemote(instance, script, resourceId);
        } else {
            return executeLocal(instance, script);
        }
    }

    /**
     * 通过 SSH 远程执行 Shell 脚本
     */
    private String executeRemote(ExecutorTaskInstance instance, String script, String resourceId) throws Exception {
        // 获取远程服务器的配置信息
        DataSourceConfig config = dataSourceConfigMapper.selectById(resourceId);
        if (config == null) {
            throw new RuntimeException("Resource not found: " + resourceId);
        }

        Map<String, Object> params = config.getConnectionParams();
        String host = (String) params.get("host");
        Integer port = (Integer) params.get("port");
        String username = (String) params.get("username");
        String password = (String) params.get("password");

        if (host == null || username == null) {
            throw new RuntimeException("Invalid SSH connection parameters for resource: " + resourceId);
        }
        if (port == null)
            port = 22;

        StringBuilder logBuilder = new StringBuilder();
        String timeStart = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        logBuilder.append("[").append(timeStart).append("] ").append("Executing Remote Shell Task ")
                .append(instance.getId()).append("\n");
        logBuilder.append("Target: ").append(username).append("@").append(host).append(":").append(port).append("\n");
        logBuilder.append("Script: ").append(script).append("\n\n");

        JSch jsch = new JSch();
        Session session = null;
        ChannelExec channel = null;

        try {
            // 建立 SSH 会话
            session = jsch.getSession(username, host, port);
            if (password != null) {
                session.setPassword(password);
            }
            session.setConfig("StrictHostKeyChecking", "no");
            session.connect(30000);

            // 开启执行通道
            channel = (ChannelExec) session.openChannel("exec");
            channel.setCommand(script);

            InputStream in = channel.getInputStream();
            InputStream err = channel.getErrStream();

            channel.connect();

            // 实时读取输出日志并存入数据库
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(in, StandardCharsets.UTF_8));
                    BufferedReader errReader = new BufferedReader(new InputStreamReader(err, StandardCharsets.UTF_8))) {

                String line;
                long lastUpdate = System.currentTimeMillis();
                while ((line = reader.readLine()) != null) {
                    log.info("[Shell-{}-Remote] {}", instance.getId(), line);
                    logBuilder.append(line).append("\n");
                    if (System.currentTimeMillis() - lastUpdate > 1000) {
                        updateLog(instance, logBuilder.toString());
                        lastUpdate = System.currentTimeMillis();
                    }
                }

                while ((line = errReader.readLine()) != null) {
                    log.error("[Shell-{}-Remote-Err] {}", instance.getId(), line);
                    logBuilder.append("ERR: ").append(line).append("\n");
                    if (System.currentTimeMillis() - lastUpdate > 1000) {
                        updateLog(instance, logBuilder.toString());
                        lastUpdate = System.currentTimeMillis();
                    }
                }
                updateLog(instance, logBuilder.toString());
            }

            // 检查退出码
            int exitCode = channel.getExitStatus();
            if (exitCode != 0) {
                String timeErr = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
                logBuilder.append("\n[").append(timeErr).append("] ").append("Remote process exited with code ")
                        .append(exitCode);
                throw new RuntimeException(
                        "Remote shell script exited with code " + exitCode + "\nLogs:\n" + logBuilder.toString());
            }

            String timeEnd = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            logBuilder.append("\n[").append(timeEnd).append("] ").append("Remote Shell Task success.");

        } finally {
            // 资源释放
            if (channel != null)
                channel.disconnect();
            if (session != null)
                session.disconnect();
        }

        return logBuilder.toString();
    }

    /**
     * 在执行器所在的本地环境执行 Shell 脚本
     */
    private String executeLocal(ExecutorTaskInstance instance, String script) throws Exception {
        // 安全提示：生产环境应考虑沙箱化执行，防止恶意脚本
        ProcessBuilder pb = new ProcessBuilder("sh", "-c", script);
        pb.redirectErrorStream(true); // 将标准错误合并到标准输出
        Process process = pb.start();

        StringBuilder logBuilder = new StringBuilder();
        String timeStart = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        logBuilder.append("[").append(timeStart).append("] ").append("Executing Local Shell Task ")
                .append(instance.getId()).append("\n");
        logBuilder.append("Script: ").append(script).append("\n\n");

        // 异步读取脚本执行产生的输出并更新到数据库
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            long lastUpdate = System.currentTimeMillis();
            while ((line = reader.readLine()) != null) {
                log.info("[Shell-{}] {}", instance.getId(), line);
                logBuilder.append(line).append("\n");
                // 每隔一秒钟更新一次数据库中的日志，避免高频操作导致的压力
                if (System.currentTimeMillis() - lastUpdate > 1000) {
                    updateLog(instance, logBuilder.toString());
                    lastUpdate = System.currentTimeMillis();
                }
            }
            updateLog(instance, logBuilder.toString());
        }

        try {
            // 等待进程执行完毕，获取退出码
            int exitCode = process.waitFor();
            if (exitCode != 0) {
                String timeErr = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
                logBuilder.append("\n[").append(timeErr).append("] ").append("Process exited with code ")
                        .append(exitCode);
                throw new RuntimeException(
                        "Shell script exited with code " + exitCode + "\nLogs:\n" + logBuilder.toString());
            }
        } catch (InterruptedException e) {
            log.warn("Shell task {} interrupted, killing process...", instance.getId());
            process.destroy(); // 任务被中断时（如应用关闭），确保子进程被杀死
            String timeErr = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            logBuilder.append("\n[").append(timeErr).append("] ").append("Process interrupted and killed.");
            throw e;
        }

        String timeEnd = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        logBuilder.append("\n[").append(timeEnd).append("] ").append("Local Shell Task success.");

        return logBuilder.toString();
    }
}
