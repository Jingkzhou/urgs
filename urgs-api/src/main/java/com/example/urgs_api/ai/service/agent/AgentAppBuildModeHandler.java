package com.example.urgs_api.ai.service.agent;

import com.example.urgs_api.ai.entity.Agent;
import com.example.urgs_api.ai.service.AiChatHistoryService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Consumer;

@Component
public class AgentAppBuildModeHandler {

    private static final Logger log = LoggerFactory.getLogger(AgentAppBuildModeHandler.class);
    private static final ObjectMapper objectMapper = new ObjectMapper();
    private static final ExecutorService executor = Executors.newCachedThreadPool();
    private static final int AGENT_APP_TIMEOUT_SECONDS = 600;
    private static final int AGENT_APP_HEARTBEAT_SECONDS = 20;
    private static final int MAX_CONTEXT_TOKENS = 30000;
    private static final List<String> AGENT_APP_TOOL_ALLOWLIST = List.of("hermesagent", "opencode", "openclaw");

    @Autowired
    private AiChatHistoryService aiChatHistoryService;

    public boolean supports(Agent agent) {
        return agent != null && "AGENT_APP".equalsIgnoreCase(agent.getBuildMode());
    }

    public void streamWithPersistence(String sessionId, Agent agent, String userPrompt, SseEmitter emitter) {
        executor.submit(() -> {
            StringBuilder response = new StringBuilder();
            try {
                emitter.send(SseEmitter.event().name("status").data("agent_app_running"));
                emitter.send(SseEmitter.event().name("metrics")
                        .data(objectMapper.writeValueAsString(Map.of("used", estimateTokens(userPrompt),
                                "limit", MAX_CONTEXT_TOKENS))));

                executeAgentApp(agent, userPrompt, chunk -> {
                    response.append(chunk);
                    try {
                        emitter.send(SseEmitter.event().data(objectMapper.writeValueAsString(Map.of("content", chunk))));
                    } catch (java.io.IOException | IllegalStateException e) {
                        throw new RuntimeException("SSE connection broken", e);
                    }
                });

                aiChatHistoryService.saveMessage(sessionId, "assistant", response.toString());
                emitter.send(SseEmitter.event().data("[DONE]"));
                emitter.complete();
            } catch (Exception e) {
                log.error("Agent App execution failed for session {}", sessionId, e);
                try {
                    if (response.length() > 0) {
                        aiChatHistoryService.saveMessage(sessionId, "assistant", response.toString());
                    }
                    emitter.send(SseEmitter.event()
                            .data(objectMapper.writeValueAsString(Map.of("error", e.getMessage()))));
                    emitter.complete();
                } catch (Exception ex) {
                    log.warn("Failed to send Agent App error event", ex);
                }
            }
        });
    }

    private void executeAgentApp(Agent agent, String userPrompt, Consumer<String> chunkConsumer) throws Exception {
        AgentAppCommand commandConfig = selectAgentAppCommand(agent);
        List<String> command = buildAgentAppCommand(commandConfig.tool(), commandConfig.executable(), userPrompt);
        log.info("Executing Agent App tool {} for agent {}", commandConfig.tool(), agent.getName());

        ProcessBuilder builder = new ProcessBuilder(command);
        builder.directory(resolveAgentAppWorkingDir());
        builder.redirectErrorStream(true);
        Process process = builder.start();
        AtomicLong lastOutputAt = new AtomicLong(System.currentTimeMillis());

        Future<?> readerFuture = executor.submit(() -> {
            try (InputStreamReader reader = new InputStreamReader(process.getInputStream(), StandardCharsets.UTF_8)) {
                char[] buffer = new char[512];
                StringBuilder pending = new StringBuilder();
                int len;
                while ((len = reader.read(buffer)) != -1) {
                    String content = stripAnsi(new String(buffer, 0, len)).replace('\r', '\n');
                    if (!content.isBlank()) {
                        String progress = filterAgentAppOutput(commandConfig.tool(), content, pending);
                        if (!progress.isBlank()) {
                            lastOutputAt.set(System.currentTimeMillis());
                            chunkConsumer.accept(progress);
                        }
                    }
                }
                String progress = flushAgentAppOutput(commandConfig.tool(), pending);
                if (!progress.isBlank()) {
                    lastOutputAt.set(System.currentTimeMillis());
                    chunkConsumer.accept(progress);
                }
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        });

        Future<?> heartbeatFuture = executor.submit(() -> {
            while (process.isAlive()) {
                try {
                    Thread.sleep(AGENT_APP_HEARTBEAT_SECONDS * 1000L);
                    long quietMillis = System.currentTimeMillis() - lastOutputAt.get();
                    if (process.isAlive() && quietMillis >= AGENT_APP_HEARTBEAT_SECONDS * 1000L) {
                        lastOutputAt.set(System.currentTimeMillis());
                        chunkConsumer.accept("\n`Hermes 仍在执行，等待下一步输出...`\n");
                    }
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    return;
                }
            }
        });

        boolean finished = process.waitFor(AGENT_APP_TIMEOUT_SECONDS, TimeUnit.SECONDS);
        if (!finished) {
            process.destroyForcibly();
            throw new RuntimeException("Agent App CLI 执行超时: " + commandConfig.tool());
        }

        readerFuture.get(5, TimeUnit.SECONDS);
        heartbeatFuture.cancel(true);
        int exitCode = process.exitValue();
        if (exitCode != 0) {
            throw new RuntimeException("Agent App CLI 执行失败: " + commandConfig.tool() + "，退出码 " + exitCode);
        }
    }

    private AgentAppCommand selectAgentAppCommand(Agent agent) {
        List<String> configuredTools = parseAgentAppTools(agent.getAgentAppTools());
        List<String> allowedConfiguredTools = new java.util.ArrayList<>();
        for (String tool : configuredTools) {
            String normalized = tool == null ? "" : tool.trim().toLowerCase();
            if (AGENT_APP_TOOL_ALLOWLIST.contains(normalized)) {
                allowedConfiguredTools.add(normalized);
                String executable = resolveExecutable(normalized);
                if (executable != null) {
                    return new AgentAppCommand(normalized, executable);
                }
            }
        }

        if (allowedConfiguredTools.isEmpty()) {
            throw new RuntimeException("Agent App 未配置可调用的 CLI 工具");
        }
        throw new RuntimeException("Agent App 已配置 CLI 但当前后端环境未安装或不在 PATH 中: "
                + String.join(", ", allowedConfiguredTools));
    }

    private List<String> parseAgentAppTools(String rawTools) {
        if (rawTools == null || rawTools.isBlank()) {
            return List.of();
        }
        try {
            JsonNode node = objectMapper.readTree(rawTools);
            if (node.isArray()) {
                List<String> tools = new java.util.ArrayList<>();
                node.forEach(item -> tools.add(item.asText()));
                return tools;
            }
        } catch (Exception e) {
            log.warn("Failed to parse Agent App tools as JSON, fallback to comma list: {}", rawTools);
        }
        return java.util.Arrays.stream(rawTools.split(","))
                .map(String::trim)
                .filter(value -> !value.isEmpty())
                .collect(java.util.stream.Collectors.toList());
    }

    private List<String> buildAgentAppCommand(String tool, String executable, String userPrompt) {
        if ("hermesagent".equals(tool)) {
            return List.of(executable, "chat", "--verbose", "--query", userPrompt);
        }
        if ("opencode".equals(tool)) {
            return List.of(executable, "run", "--format", "default", "--dir", resolveAgentAppWorkingDir().getAbsolutePath(),
                    userPrompt);
        }
        if ("openclaw".equals(tool)) {
            return List.of(executable, "agent", "--local", "--message", userPrompt);
        }
        return List.of(executable, userPrompt);
    }

    private java.io.File resolveAgentAppWorkingDir() {
        java.io.File current = new java.io.File(System.getProperty("user.dir")).getAbsoluteFile();
        if ("urgs-api".equals(current.getName()) && current.getParentFile() != null) {
            return current.getParentFile();
        }
        return current;
    }

    private String resolveExecutable(String tool) {
        String executableName = "hermesagent".equals(tool) ? "hermes" : tool;
        java.util.List<String> dirs = new java.util.ArrayList<>();
        String path = System.getenv("PATH");
        if (path != null && !path.isBlank()) {
            dirs.addAll(java.util.Arrays.asList(path.split(java.io.File.pathSeparator)));
        }
        dirs.add("/opt/homebrew/bin");
        dirs.add("/usr/local/bin");
        dirs.add(System.getProperty("user.home") + "/.local/bin");

        for (String dir : dirs) {
            java.io.File candidate = new java.io.File(dir, executableName);
            if (candidate.isFile() && candidate.canExecute()) {
                return candidate.getAbsolutePath();
            }
        }
        return null;
    }

    private int estimateTokens(String text) {
        if (text == null || text.isEmpty()) {
            return 0;
        }
        return text.length() / 4;
    }

    private String stripAnsi(String text) {
        return text == null ? "" : text.replaceAll("\\u001B\\[[;\\d]*[ -/]*[@-~]", "");
    }

    private String filterAgentAppOutput(String tool, String chunk, StringBuilder pending) {
        if (!"hermesagent".equals(tool)) {
            return chunk;
        }
        pending.append(chunk);
        String text = pending.toString();
        int lastNewline = text.lastIndexOf('\n');
        if (lastNewline < 0) {
            return "";
        }

        String complete = text.substring(0, lastNewline + 1);
        pending.setLength(0);
        pending.append(text.substring(lastNewline + 1));
        return compactHermesProgress(complete);
    }

    private String flushAgentAppOutput(String tool, StringBuilder pending) {
        if (pending.isEmpty()) {
            return "";
        }
        String text = pending.toString();
        pending.setLength(0);
        return "hermesagent".equals(tool) ? compactHermesProgress(text) : text;
    }

    private String compactHermesProgress(String text) {
        StringBuilder result = new StringBuilder();
        for (String line : text.split("\\R")) {
            String normalized = normalizeHermesLine(line);
            if (!normalized.isBlank()) {
                result.append(normalized).append('\n');
            }
        }
        return result.toString();
    }

    private String normalizeHermesLine(String line) {
        if (line == null) {
            return "";
        }
        String trimmed = line.trim();
        if (trimmed.isEmpty()) {
            return "";
        }
        if (trimmed.contains("Hermes")) {
            return "\n**Hermes**";
        }
        if (trimmed.startsWith("│")) {
            String message = trimmed.replaceFirst("^│\\s*", "").trim();
            if (!message.isBlank() && !message.matches("[─╭╰╮╯│ ]+")) {
                return "> " + shortenHermesPath(message);
            }
            return "";
        }

        String withoutPrefix = trimmed.replaceFirst("^[│┊┃╎╏|]+\\s*", "").trim();
        if (isHermesProgressLine(withoutPrefix)) {
            return "`" + shortenHermesPath(withoutPrefix) + "`";
        }
        return "";
    }

    private boolean isHermesProgressLine(String line) {
        return line.startsWith("preparing ")
                || line.startsWith("read ")
                || line.startsWith("find ")
                || line.startsWith("skill ")
                || line.startsWith("plan ")
                || line.startsWith("todo ")
                || line.startsWith("search ")
                || line.matches("^[📖🔎📚📋📝✅]\\s+.*");
    }

    private String shortenHermesPath(String text) {
        return text.replaceAll("(/[^\\s]+/)([^/\\s]+\\.\\w+)", ".../$2");
    }

    private record AgentAppCommand(String tool, String executable) {
    }
}
