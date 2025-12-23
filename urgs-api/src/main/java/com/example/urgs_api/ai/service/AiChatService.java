package com.example.urgs_api.ai.service;

import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.function.Consumer;

/**
 * AI 聊天服务接口，支持流式输出
 */
public interface AiChatService {

    /**
     * 同步调用 AI，返回完整响应
     * 
     * @param systemPrompt 系统提示词
     * @param userPrompt   用户提示词
     * @return 完整的 AI 响应内容
     */
    String chat(String systemPrompt, String userPrompt);

    /**
     * 流式调用 AI，通过 SseEmitter 推送内容
     * 
     * @param systemPrompt 系统提示词
     * @param userPrompt   用户提示词
     * @param emitter      SSE 发射器
     */
    void streamChat(String systemPrompt, String userPrompt, SseEmitter emitter);

    /**
     * 流式调用 AI，通过回调函数接收内容片段
     * 
     * @param systemPrompt  系统提示词
     * @param userPrompt    用户提示词
     * @param chunkConsumer 接收内容片段的回调
     * @param onComplete    完成回调
     * @param onError       错误回调
     */
    void streamChat(String systemPrompt, String userPrompt,
            Consumer<String> chunkConsumer,
            Runnable onComplete,
            Consumer<Exception> onError);

    void streamChatWithPersistence(String sessionId, String systemPrompt, String userPrompt, SseEmitter emitter);

}
