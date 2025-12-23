package com.example.urgs_api.ai.controller;

import com.example.urgs_api.ai.entity.AiChatMessage;
import com.example.urgs_api.ai.entity.AiChatSession;
import com.example.urgs_api.ai.service.AiChatHistoryService;
import com.example.urgs_api.ai.service.AiChatService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.List;
import java.util.Map;

/**
 * AI 聊天控制器
 */
@RestController
@RequestMapping("/api/ai/chat")
public class AiChatController {

    @Autowired
    private AiChatService aiChatService;

    @Autowired
    private AiChatHistoryService aiChatHistoryService;

    /**
     * 发送聊天请求 (流式响应)
     */
    @PostMapping("/stream")
    public org.springframework.http.ResponseEntity<SseEmitter> streamChat(@RequestBody Map<String, String> request) {
        String systemPrompt = request.getOrDefault("systemPrompt", "You are a helpful assistant.");
        String userPrompt = request.get("userPrompt");
        // 如果有 sessionId，则使用持久化逻辑；否则仅流式返回
        String sessionId = request.get("sessionId");

        SseEmitter emitter = new SseEmitter(300000L); // 5分钟超时

        if (sessionId != null && !sessionId.isEmpty()) {
            aiChatService.streamChatWithPersistence(sessionId, systemPrompt, userPrompt, emitter);
        } else {
            aiChatService.streamChat(systemPrompt, userPrompt, emitter);
        }

        return org.springframework.http.ResponseEntity.ok()
                .header("X-Accel-Buffering", "no")
                .header("Cache-Control", "no-cache")
                .body(emitter);
    }

    /**
     * 发送聊天请求 (同步响应)
     */
    @PostMapping("/completions")
    public Map<String, String> chat(@RequestBody Map<String, String> request) {
        String systemPrompt = request.getOrDefault("systemPrompt", "You are a helpful assistant.");
        String userPrompt = request.get("userPrompt");

        String response = aiChatService.chat(systemPrompt, userPrompt);
        return Map.of("content", response);
    }

    // --- Session Management ---

    @PostMapping("/session")
    public AiChatSession createSession(@RequestBody Map<String, String> body) {
        String userId = body.get("userId"); // Should come from Auth context in real app
        String title = body.getOrDefault("title", "New Chat");
        String agentIdStr = body.get("agentId");
        Long agentId = null;
        if (agentIdStr != null) {
            try {
                agentId = Long.parseLong(agentIdStr);
            } catch (NumberFormatException e) {
                // Ignore invalid format
            }
        }
        return aiChatHistoryService.createSession(userId, title, agentId);
    }

    @GetMapping("/session")
    public List<AiChatSession> getUserSessions(@RequestParam String userId) {
        return aiChatHistoryService.getUserSessions(userId);
    }

    @DeleteMapping("/session/{sessionId}")
    public void deleteSession(@PathVariable String sessionId, @RequestParam String userId) {
        aiChatHistoryService.deleteSession(sessionId, userId);
    }

    @GetMapping("/session/{sessionId}/messages")
    public List<AiChatMessage> getSessionMessages(@PathVariable String sessionId) {
        return aiChatHistoryService.getSessionMessages(sessionId);
    }

    @PostMapping("/session/{sessionId}/generate-title")
    public String generateSessionTitle(@PathVariable String sessionId) {
        return aiChatHistoryService.generateSessionTitle(sessionId);
    }

    @PutMapping("/session/{sessionId}")
    public void updateSessionTitle(@PathVariable String sessionId, @RequestBody Map<String, String> body) {
        String title = body.get("title");
        if (title != null) {
            aiChatHistoryService.updateSessionTitle(sessionId, title);
        }
    }
}
