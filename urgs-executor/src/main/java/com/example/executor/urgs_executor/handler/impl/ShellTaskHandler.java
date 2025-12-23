package com.example.executor.urgs_executor.handler.impl;

import com.example.executor.urgs_executor.entity.DataSourceConfig;
import com.example.executor.urgs_executor.entity.TaskInstance;
import com.example.executor.urgs_executor.handler.TaskHandler;
import com.example.executor.urgs_executor.mapper.DataSourceConfigMapper;
import com.example.executor.urgs_executor.mapper.TaskInstanceMapper;
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
import java.util.Map;

@Slf4j
@Component("SHELL")
public class ShellTaskHandler implements TaskHandler {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    private DataSourceConfigMapper dataSourceConfigMapper;

    @Autowired
    private TaskInstanceMapper taskInstanceMapper;

    private void updateLog(TaskInstance instance, String content) {
        UpdateWrapper<TaskInstance> update = new UpdateWrapper<>();
        update.eq("id", instance.getId());
        update.set("log_content", content);
        taskInstanceMapper.update(null, update);
        instance.setLogContent(content);
    }

    @Override
    public String execute(TaskInstance instance) throws Exception {
        String script = "";
        String resourceId = null;

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

        if (script.isEmpty()) {
            log.warn("Shell task {} has no script content", instance.getId());
            return "No script content";
        }

        // Replace $dataDate with actual date
        script = script.replace("$dataDate", instance.getDataDate());

        log.info("Executing Shell Task {}: {}", instance.getId(), script);

        if (resourceId != null && !resourceId.isEmpty()) {
            return executeRemote(instance, script, resourceId);
        } else {
            return executeLocal(instance, script);
        }
    }

    private String executeRemote(TaskInstance instance, String script, String resourceId) throws Exception {
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
        logBuilder.append("Executing Remote Shell Task ").append(instance.getId()).append("\n");
        logBuilder.append("Target: ").append(username).append("@").append(host).append(":").append(port).append("\n");
        logBuilder.append("Script: ").append(script).append("\n\n");

        JSch jsch = new JSch();
        Session session = null;
        ChannelExec channel = null;

        try {
            session = jsch.getSession(username, host, port);
            if (password != null) {
                session.setPassword(password);
            }
            session.setConfig("StrictHostKeyChecking", "no");
            session.connect(30000);

            channel = (ChannelExec) session.openChannel("exec");
            channel.setCommand(script);

            InputStream in = channel.getInputStream();
            InputStream err = channel.getErrStream();

            channel.connect();

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

            int exitCode = channel.getExitStatus();
            if (exitCode != 0) {
                logBuilder.append("\nRemote process exited with code ").append(exitCode);
                throw new RuntimeException(
                        "Remote shell script exited with code " + exitCode + "\nLogs:\n" + logBuilder.toString());
            }

        } finally {
            if (channel != null)
                channel.disconnect();
            if (session != null)
                session.disconnect();
        }

        return logBuilder.toString();
    }

    private String executeLocal(TaskInstance instance, String script) throws Exception {
        // Security Note: In production, this should be sandboxed!
        ProcessBuilder pb = new ProcessBuilder("sh", "-c", script);
        pb.redirectErrorStream(true);
        Process process = pb.start();

        StringBuilder logBuilder = new StringBuilder();
        logBuilder.append("Executing Local Shell Task ").append(instance.getId()).append("\n");
        logBuilder.append("Script: ").append(script).append("\n\n");

        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            long lastUpdate = System.currentTimeMillis();
            while ((line = reader.readLine()) != null) {
                log.info("[Shell-{}] {}", instance.getId(), line);
                logBuilder.append(line).append("\n");
                if (System.currentTimeMillis() - lastUpdate > 1000) {
                    updateLog(instance, logBuilder.toString());
                    lastUpdate = System.currentTimeMillis();
                }
            }
            updateLog(instance, logBuilder.toString());
        }

        try {
            int exitCode = process.waitFor();
            if (exitCode != 0) {
                logBuilder.append("\nProcess exited with code ").append(exitCode);
                throw new RuntimeException(
                        "Shell script exited with code " + exitCode + "\nLogs:\n" + logBuilder.toString());
            }
        } catch (InterruptedException e) {
            log.warn("Shell task {} interrupted, killing process...", instance.getId());
            process.destroy();
            logBuilder.append("\nProcess interrupted and killed.");
            throw e;
        }

        return logBuilder.toString();
    }
}
