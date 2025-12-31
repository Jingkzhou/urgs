package com.example.executor.urgs_executor.handler.impl;

import com.example.executor.urgs_executor.entity.DataSourceConfig;
import com.example.executor.urgs_executor.entity.ExecutorTaskInstance;
import com.example.executor.urgs_executor.handler.TaskHandler;
import com.example.executor.urgs_executor.mapper.DataSourceConfigMapper;
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
@Component("PYTHON")
public class PythonTaskHandler implements TaskHandler {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    private DataSourceConfigMapper dataSourceConfigMapper;

    @Override
    public String execute(ExecutorTaskInstance instance) throws Exception {
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
            throw new RuntimeException("Python task " + instance.getId() + " has no script content");
        }

        // Replace $dataDate with actual date
        script = script.replace("$dataDate", instance.getDataDate());

        log.info("Executing Python Task {}: {}", instance.getId(), script);

        if (resourceId != null && !resourceId.isEmpty()) {
            return executeRemote(instance, script, resourceId);
        } else {
            return executeLocal(instance, script);
        }
    }

    private String executeRemote(ExecutorTaskInstance instance, String script, String resourceId) throws Exception {
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
        logBuilder.append("Executing Remote Python Task ").append(instance.getId()).append("\n");
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
            // Execute python3 with the script content passed via -c
            // Note: Complex scripts with single/double quotes might need better escaping or
            // file transfer
            // For now, we assume simple scripts or user handles escaping, or we could wrap
            // in a HEREDOC if shell allows
            // A safer approach for complex scripts is to upload a file, but -c is
            // requested/implied for simplicity first.
            // Let's try to escape single quotes if we wrap in single quotes, or just pass
            // as is if we trust the content?
            // The safest quick way for -c is to wrap in single quotes and escape single
            // quotes inside.
            // But rawScript might be multi-line.
            // Let's try a HEREDOC approach: python3 -c "$(cat << 'EOF' ... EOF)" but that's
            // shell specific.
            // Or just: python3 -c "..."
            // Let's stick to the same pattern as ShellTaskHandler for now, but prepending
            // python3 -c
            // Actually, if it's a raw script, maybe we should just run it?
            // If the user provided a python script, they expect it to run.
            // If we use "python3 -c 'script'", we need to escape.
            // Let's try to just run the script string as a command if it's a shell command
            // that invokes python?
            // No, the user provides Python code.
            // So we MUST wrap it.
            // Let's use a simple escaping strategy: replace ' with '\'' and wrap in '
            String escapedScript = script.replace("'", "'\\''");
            String command = "python3 -c '" + escapedScript + "'";

            channel.setCommand(command);

            InputStream in = channel.getInputStream();
            InputStream err = channel.getErrStream();

            channel.connect();

            try (BufferedReader reader = new BufferedReader(new InputStreamReader(in, StandardCharsets.UTF_8));
                    BufferedReader errReader = new BufferedReader(new InputStreamReader(err, StandardCharsets.UTF_8))) {

                String line;
                while ((line = reader.readLine()) != null) {
                    log.info("[Python-{}-Remote] {}", instance.getId(), line);
                    logBuilder.append(line).append("\n");
                }

                while ((line = errReader.readLine()) != null) {
                    log.error("[Python-{}-Remote-Err] {}", instance.getId(), line);
                    logBuilder.append("ERR: ").append(line).append("\n");
                }
            }

            int exitCode = channel.getExitStatus();
            if (exitCode != 0) {
                logBuilder.append("\nRemote process exited with code ").append(exitCode);
                throw new RuntimeException(
                        "Remote python script exited with code " + exitCode + "\nLogs:\n" + logBuilder.toString());
            }

        } finally {
            if (channel != null)
                channel.disconnect();
            if (session != null)
                session.disconnect();
        }

        return logBuilder.toString();
    }

    private String executeLocal(ExecutorTaskInstance instance, String script) throws Exception {
        ProcessBuilder pb = new ProcessBuilder("python3", "-c", script);
        pb.redirectErrorStream(true);
        Process process = pb.start();

        StringBuilder logBuilder = new StringBuilder();
        logBuilder.append("Executing Local Python Task ").append(instance.getId()).append("\n");
        logBuilder.append("Script: ").append(script).append("\n\n");

        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                log.info("[Python-{}] {}", instance.getId(), line);
                logBuilder.append(line).append("\n");
            }
        }

        try {
            int exitCode = process.waitFor();
            if (exitCode != 0) {
                logBuilder.append("\nProcess exited with code ").append(exitCode);
                throw new RuntimeException(
                        "Python script exited with code " + exitCode + "\nLogs:\n" + logBuilder.toString());
            }
        } catch (InterruptedException e) {
            log.warn("Python task {} interrupted, killing process...", instance.getId());
            process.destroy();
            logBuilder.append("\nProcess interrupted and killed.");
            throw e;
        }

        return logBuilder.toString();
    }
}
