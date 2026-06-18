package com.example.urgs_api.ai.client;

import com.example.urgs_api.ai.service.agent.DeepAgentsBuildModeHandler;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
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
    private DeepAgentsBuildModeHandler deepAgentsBuildModeHandler;

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
     * 执行 AI 调用（内部方法）
     */
    void executeRequest(ChatRequestBuilder builder) {
        try {
            String response = deepAgentsBuildModeHandler.invokeDefault(builder.systemPrompt, List.of(
                    Map.of("role", "user", "content", builder.userPrompt)));
            if (response != null && !response.isEmpty() && builder.onChunk != null) {
                builder.onChunk.accept(response);
            }
            if (builder.onComplete != null) {
                builder.onComplete.run();
            }
        } catch (Exception e) {
            log.error("AI request error", e);
            if (builder.onError != null) {
                builder.onError.accept(e);
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
