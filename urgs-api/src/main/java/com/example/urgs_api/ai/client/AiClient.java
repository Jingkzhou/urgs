package com.example.urgs_api.ai.client;

import com.example.urgs_api.ai.entity.AiApiConfig;
import com.example.urgs_api.ai.service.AiApiConfigService;
import com.example.urgs_api.ai.service.AiUsageLogService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Consumer;

/**
 * 通用 AI 客户端
 * 统一的 AI 调用入口，所有 AI 调用都通过此类
 * 
 * 使用示例：
 * 
 * <pre>
 * // 简单调用
 * String result = aiClient.chat("总结这段文本...");
 * 
 * // 带系统提示
 * String result = aiClient.chat("你是专家", "分析这个数据...");
 * 
 * // 构建器模式
 * aiClient.request()
 *         .systemPrompt("你是数据分析师")
 *         .userPrompt("分析血缘影响")
 *         .requestType("report")
 *         .stream(chunk -> System.out.print(chunk));
 * </pre>
 */
@Component
public class AiClient {

    private static final Logger log = LoggerFactory.getLogger(AiClient.class);
    private static final ObjectMapper objectMapper = new ObjectMapper();
    private static final ExecutorService executor = Executors.newCachedThreadPool();

    @Autowired
    private AiApiConfigService aiApiConfigService;

    @Autowired
    private AiUsageLogService aiUsageLogService;

    /**
     * 简单聊天（使用默认系统提示）
     */
    public String chat(String userPrompt) {
        return chat("你是一个有帮助的AI助手。", userPrompt);
    }

    /**
     * 带系统提示的聊天
     */
    public String chat(String systemPrompt, String userPrompt) {
        StringBuilder result = new StringBuilder();
        request()
                .systemPrompt(systemPrompt)
                .userPrompt(userPrompt)
                .requestType("chat")
                .onChunk(result::append)
                .execute();
        return result.toString();
    }

    /**
     * 流式聊天（SSE）
     */
    public SseEmitter streamChat(String systemPrompt, String userPrompt, String requestType) {
        SseEmitter emitter = new SseEmitter(300000L);

        executor.submit(() -> {
            request()
                    .systemPrompt(systemPrompt)
                    .userPrompt(userPrompt)
                    .requestType(requestType)
                    .onChunk(chunk -> {
                        try {
                            emitter.send(SseEmitter.event()
                                    .data(objectMapper.writeValueAsString(Map.of("content", chunk))));
                        } catch (Exception e) {
                            log.error("Failed to send SSE event", e);
                        }
                    })
                    .onComplete(() -> {
                        try {
                            emitter.send(SseEmitter.event().data("[DONE]"));
                            emitter.complete();
                        } catch (Exception e) {
                            log.error("Failed to complete SSE", e);
                        }
                    })
                    .onError(e -> {
                        try {
                            emitter.send(SseEmitter.event()
                                    .data(objectMapper.writeValueAsString(Map.of("error", e.getMessage()))));
                            emitter.completeWithError(e);
                        } catch (Exception ex) {
                            log.error("Failed to send error event", ex);
                        }
                    })
                    .execute();
        });

        return emitter;
    }

    /**
     * 创建请求构建器
     */
    public ChatRequestBuilder request() {
        return new ChatRequestBuilder(this);
    }

    /**
     * 获取默认配置
     */
    AiApiConfig getDefaultConfig() {
        return aiApiConfigService.getDefaultConfig();
    }

    /**
     * 记录 Token 使用
     */
    void recordUsage(Long configId, String model, Integer promptTokens,
            Integer completionTokens, String requestType,
            Boolean success, String errorMessage) {
        aiUsageLogService.recordUsage(configId, model, promptTokens,
                completionTokens, requestType, success, errorMessage);
    }

    /**
     * 执行 AI 调用（内部方法）
     */
    void executeRequest(ChatRequestBuilder builder) {
        AiApiConfig config = null;
        AtomicInteger promptTokens = new AtomicInteger(0);
        AtomicInteger completionTokens = new AtomicInteger(0);
        boolean success = false;
        String errorMessage = null;

        try {
            config = getDefaultConfig();
            if (config == null) {
                throw new RuntimeException("未配置默认 AI API，请在系统管理中配置");
            }

            String endpoint = config.getEndpoint();
            if (!endpoint.endsWith("/")) {
                endpoint += "/";
            }
            endpoint += "chat/completions";

            // 构建请求体
            Map<String, Object> requestBody = Map.of(
                    "model", config.getModel(),
                    "messages", List.of(
                            Map.of("role", "system", "content", builder.systemPrompt),
                            Map.of("role", "user", "content", builder.userPrompt)),
                    "stream", true,
                    "stream_options", Map.of("include_usage", true),
                    "max_tokens",
                    builder.maxTokens != null ? builder.maxTokens
                            : (config.getMaxTokens() != null ? config.getMaxTokens() : 4096),
                    "temperature", builder.temperature != null ? builder.temperature
                            : (config.getTemperature() != null ? config.getTemperature() : 0.7));

            String jsonBody = objectMapper.writeValueAsString(requestBody);
            log.debug("AI Request: {}", jsonBody);

            // 创建连接
            HttpURLConnection conn = (HttpURLConnection) URI.create(endpoint).toURL().openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE);
            conn.setRequestProperty(HttpHeaders.AUTHORIZATION, "Bearer " + config.getApiKey());
            conn.setRequestProperty(HttpHeaders.ACCEPT, "text/event-stream");
            conn.setDoOutput(true);
            conn.setConnectTimeout(30000);
            conn.setReadTimeout(120000);

            // 发送请求
            try (OutputStream os = conn.getOutputStream()) {
                os.write(jsonBody.getBytes(StandardCharsets.UTF_8));
            }

            int responseCode = conn.getResponseCode();
            if (responseCode != 200) {
                String errorBody = new String(conn.getErrorStream().readAllBytes(), StandardCharsets.UTF_8);
                throw new RuntimeException("AI API 调用失败: " + responseCode + " - " + errorBody);
            }

            // 读取流式响应
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    if (line.startsWith("data: ")) {
                        String data = line.substring(6).trim();
                        if ("[DONE]".equals(data)) {
                            break;
                        }
                        try {
                            JsonNode node = objectMapper.readTree(data);

                            // 解析 usage 信息
                            JsonNode usageNode = node.get("usage");
                            if (usageNode != null) {
                                if (usageNode.has("prompt_tokens")) {
                                    promptTokens.set(usageNode.get("prompt_tokens").asInt());
                                }
                                if (usageNode.has("completion_tokens")) {
                                    completionTokens.set(usageNode.get("completion_tokens").asInt());
                                }
                            }

                            // 解析内容
                            JsonNode choices = node.get("choices");
                            if (choices != null && choices.isArray() && !choices.isEmpty()) {
                                JsonNode delta = choices.get(0).get("delta");
                                if (delta != null && delta.has("content")) {
                                    String content = delta.get("content").asText();
                                    if (content != null && !content.isEmpty() && builder.onChunk != null) {
                                        builder.onChunk.accept(content);
                                    }
                                }
                            }
                        } catch (Exception e) {
                            log.warn("Failed to parse SSE data: {}", data, e);
                        }
                    }
                }
            }

            success = true;
            if (builder.onComplete != null) {
                builder.onComplete.run();
            }

        } catch (Exception e) {
            log.error("AI request error", e);
            errorMessage = e.getMessage();
            if (builder.onError != null) {
                builder.onError.accept(e);
            }
        } finally {
            // 记录 Token 使用
            if (config != null) {
                try {
                    int estimatedPromptTokens = promptTokens.get() > 0 ? promptTokens.get()
                            : (builder.systemPrompt.length() + builder.userPrompt.length()) / 4;

                    recordUsage(config.getId(), config.getModel(),
                            estimatedPromptTokens, completionTokens.get(),
                            builder.requestType, success, errorMessage);
                } catch (Exception e) {
                    log.error("Failed to record AI usage", e);
                }
            }
        }
    }

    /**
     * 请求构建器
     */
    public static class ChatRequestBuilder {
        private final AiClient client;
        String systemPrompt = "你是一个有帮助的AI助手。";
        String userPrompt;
        String requestType = "chat";
        Integer maxTokens;
        Double temperature;
        Consumer<String> onChunk;
        Runnable onComplete;
        Consumer<Exception> onError;

        ChatRequestBuilder(AiClient client) {
            this.client = client;
        }

        public ChatRequestBuilder systemPrompt(String systemPrompt) {
            this.systemPrompt = systemPrompt;
            return this;
        }

        public ChatRequestBuilder userPrompt(String userPrompt) {
            this.userPrompt = userPrompt;
            return this;
        }

        public ChatRequestBuilder requestType(String requestType) {
            this.requestType = requestType;
            return this;
        }

        public ChatRequestBuilder maxTokens(int maxTokens) {
            this.maxTokens = maxTokens;
            return this;
        }

        public ChatRequestBuilder temperature(double temperature) {
            this.temperature = temperature;
            return this;
        }

        public ChatRequestBuilder onChunk(Consumer<String> onChunk) {
            this.onChunk = onChunk;
            return this;
        }

        public ChatRequestBuilder onComplete(Runnable onComplete) {
            this.onComplete = onComplete;
            return this;
        }

        public ChatRequestBuilder onError(Consumer<Exception> onError) {
            this.onError = onError;
            return this;
        }

        /**
         * 执行请求
         */
        public void execute() {
            if (userPrompt == null || userPrompt.isEmpty()) {
                throw new IllegalArgumentException("userPrompt is required");
            }
            client.executeRequest(this);
        }

        /**
         * 流式执行（便捷方法）
         */
        public void stream(Consumer<String> chunkConsumer) {
            this.onChunk = chunkConsumer;
            execute();
        }
    }
}
