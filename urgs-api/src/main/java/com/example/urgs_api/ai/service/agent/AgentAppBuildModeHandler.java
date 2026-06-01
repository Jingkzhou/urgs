package com.example.urgs_api.ai.service.agent;

import com.example.urgs_api.ai.entity.Agent;
import com.example.urgs_api.ai.entity.AgentAppSkill;
import com.example.urgs_api.ai.service.AiChatHistoryService;
import com.example.urgs_api.ai.service.AgentAppSkillService;
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
import java.util.function.Consumer;

@Component
public class AgentAppBuildModeHandler {

    private static final Logger log = LoggerFactory.getLogger(AgentAppBuildModeHandler.class);
    private static final ObjectMapper objectMapper = new ObjectMapper();
    private static final ExecutorService executor = Executors.newCachedThreadPool();
    private static final int AGENT_APP_TIMEOUT_SECONDS = 600;
    private static final int MAX_CONTEXT_TOKENS = 30000;
    private static final List<String> AGENT_APP_TOOL_ALLOWLIST = List.of("hermesagent", "opencode", "openclaw");

    @Autowired
    private AiChatHistoryService aiChatHistoryService;

    @Autowired
    private AgentAppSkillService agentAppSkillService;

    public boolean supports(Agent agent) {
        return agent != null && "AGENT_APP".equalsIgnoreCase(agent.getBuildMode());
    }

    public void streamWithPersistence(String sessionId, Agent agent, String userPrompt, String skillAppCode,
            String skillCode, SseEmitter emitter) {
        executor.submit(() -> {
            StringBuilder response = new StringBuilder();
            try {
                emitter.send(SseEmitter.event().name("status").data("agent_app_running"));
                emitter.send(SseEmitter.event().name("metrics")
                        .data(objectMapper.writeValueAsString(Map.of("used", estimateTokens(userPrompt),
                                "limit", MAX_CONTEXT_TOKENS))));

                AgentAppSkill skill = resolveSkill(agent, skillAppCode, skillCode);
                String effectivePrompt = buildSkillPrompt(skill, userPrompt);

                executeAgentApp(agent, skill == null ? null : skill.getAppCode(), effectivePrompt, chunk -> {
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

    private AgentAppSkill resolveSkill(Agent agent, String skillAppCode, String skillCode) {
        if (skillCode == null || skillCode.isBlank()) {
            return null;
        }
        AgentAppSkill skill = agentAppSkillService.getEnabledSkill(skillAppCode, skillCode);
        if (skill == null) {
            throw new RuntimeException("Agent App 技能不存在或已禁用: " + skillCode);
        }
        List<String> configuredTools = parseAgentAppTools(agent.getAgentAppTools());
        if (!configuredTools.contains(skill.getAppCode())) {
            throw new RuntimeException("当前助手未允许调用 Agent App: " + skill.getAppCode());
        }
        return skill;
    }

    private String buildSkillPrompt(AgentAppSkill skill, String userPrompt) {
        if (skill == null) {
            return userPrompt;
        }
        return """
                [Agent App Skill]
                Agent App: %s
                名称: %s
                编码: %s
                指令: %s

                [用户请求]
                %s
                """.formatted(
                nullToEmpty(skill.getAppCode()),
                nullToEmpty(skill.getName()),
                nullToEmpty(skill.getCode()),
                nullToEmpty(skill.getInstruction()),
                nullToEmpty(userPrompt));
    }

    private void executeAgentApp(Agent agent, String preferredTool, String userPrompt, Consumer<String> chunkConsumer)
            throws Exception {
        AgentAppCommand commandConfig = selectAgentAppCommand(agent, preferredTool);
        List<String> command = buildAgentAppCommand(commandConfig.tool(), commandConfig.executable(), userPrompt);
        log.info("Executing Agent App tool {} for agent {}", commandConfig.tool(), agent.getName());

        ProcessBuilder builder = new ProcessBuilder(command);
        builder.directory(resolveAgentAppWorkingDir());
        builder.redirectErrorStream(true);
        Process process = builder.start();

        Future<?> readerFuture = executor.submit(() -> {
            try (InputStreamReader reader = new InputStreamReader(process.getInputStream(), StandardCharsets.UTF_8)) {
                char[] buffer = new char[512];
                int len;
                while ((len = reader.read(buffer)) != -1) {
                    String content = stripAnsi(new String(buffer, 0, len)).replace('\r', '\n');
                    if (!content.isBlank()) {
                        chunkConsumer.accept(content);
                    }
                }
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        });

        boolean finished = process.waitFor(AGENT_APP_TIMEOUT_SECONDS, TimeUnit.SECONDS);
        if (!finished) {
            process.destroyForcibly();
            throw new RuntimeException("Agent App CLI 执行超时: " + commandConfig.tool());
        }

        readerFuture.get(5, TimeUnit.SECONDS);
        int exitCode = process.exitValue();
        if (exitCode != 0) {
            throw new RuntimeException("Agent App CLI 执行失败: " + commandConfig.tool() + "，退出码 " + exitCode);
        }
    }

    private AgentAppCommand selectAgentAppCommand(Agent agent, String preferredTool) {
        List<String> configuredTools = parseAgentAppTools(agent.getAgentAppTools());
        if (preferredTool != null && !preferredTool.isBlank()) {
            String normalizedPreferredTool = preferredTool.trim().toLowerCase();
            if (configuredTools.contains(normalizedPreferredTool) && AGENT_APP_TOOL_ALLOWLIST.contains(normalizedPreferredTool)) {
                String executable = resolveExecutable(normalizedPreferredTool);
                if (executable != null) {
                    return new AgentAppCommand(normalizedPreferredTool, executable);
                }
                throw new RuntimeException("Agent App 已配置 CLI 但当前后端环境未安装或不在 PATH 中: "
                        + normalizedPreferredTool);
            }
        }

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
            return List.of(executable, "chat",  "--query", userPrompt);
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

    private String nullToEmpty(String text) {
        return text == null ? "" : text;
    }

    private record AgentAppCommand(String tool, String executable) {
    }
}
