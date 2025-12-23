package com.example.urgs_api.ai.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.ai.entity.AiChatMessage;
import com.example.urgs_api.ai.entity.AiChatSession;
import com.example.urgs_api.ai.repository.AiChatMessageMapper;
import com.example.urgs_api.ai.repository.AiChatSessionMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class AiChatHistoryServiceImpl implements AiChatHistoryService {

    @Autowired
    private AiChatSessionMapper sessionMapper;

    @Autowired
    private AiChatMessageMapper messageMapper;

    @Override
    public AiChatSession createSession(String userId, String title, Long agentId) {
        AiChatSession session = new AiChatSession();
        session.setId(UUID.randomUUID().toString());
        session.setUserId(userId);
        session.setTitle(title);
        session.setAgentId(agentId);
        session.setCreateTime(LocalDateTime.now());
        session.setUpdateTime(LocalDateTime.now());
        session.setIsDeleted(0);

        sessionMapper.insert(session);
        return session;
    }

    @Override
    public List<AiChatSession> getUserSessions(String userId) {
        return sessionMapper.selectList(new LambdaQueryWrapper<AiChatSession>()
                .eq(AiChatSession::getUserId, userId)
                .orderByDesc(AiChatSession::getUpdateTime));
    }

    @Override
    public AiChatSession getSession(String sessionId) {
        return sessionMapper.selectById(sessionId);
    }

    @Override
    public void deleteSession(String sessionId, String userId) {
        AiChatSession session = sessionMapper.selectById(sessionId);
        if (session != null && session.getUserId().equals(userId)) {
            sessionMapper.deleteById(sessionId); // @TableLogic handles the update
        }
    }

    @Override
    public void updateSessionTitle(String sessionId, String title) {
        AiChatSession session = new AiChatSession();
        session.setId(sessionId);
        session.setTitle(title);
        session.setUpdateTime(LocalDateTime.now());
        sessionMapper.updateById(session);
    }

    @Override
    public AiChatMessage saveMessage(String sessionId, String role, String content) {
        AiChatMessage message = new AiChatMessage();
        message.setId(UUID.randomUUID().toString());
        message.setSessionId(sessionId);
        message.setRole(role);
        message.setContent(content);
        message.setCreateTime(LocalDateTime.now());

        messageMapper.insert(message);

        // Update session update_time
        AiChatSession session = new AiChatSession();
        session.setId(sessionId);
        session.setUpdateTime(LocalDateTime.now());
        sessionMapper.updateById(session);

        return message;
    }

    @Override
    public List<AiChatMessage> getSessionMessages(String sessionId) {
        return messageMapper.selectList(new LambdaQueryWrapper<AiChatMessage>()
                .eq(AiChatMessage::getSessionId, sessionId)
                .orderByAsc(AiChatMessage::getCreateTime));
    }

    @Autowired
    @org.springframework.context.annotation.Lazy
    private AiChatService aiChatService;

    @Override
    public String generateSessionTitle(String sessionId) {
        // 1. Get messages
        List<AiChatMessage> messages = getSessionMessages(sessionId);
        if (messages.isEmpty()) {
            return "New Chat";
        }

        // 2. Prepare prompt
        StringBuilder conversation = new StringBuilder();
        // Limit to first few messages to avoid token limit and focus on topic
        int limit = Math.min(messages.size(), 4);
        for (int i = 0; i < limit; i++) {
            AiChatMessage msg = messages.get(i);
            conversation.append(msg.getRole()).append(": ").append(msg.getContent()).append("\n");
        }

        String systemPrompt = "You are a helpful assistant. Analyze the following conversation start and generate a short, concise title (max 10 words). strictly return ONLY the title text, no quotes, no explanations.";
        String userPrompt = "Conversation:\n" + conversation.toString();

        // 3. Call AI
        // Use a lightweight model if possible, but here we use the default
        String generatedTitle = aiChatService.chat(systemPrompt, userPrompt);

        // 4. Clean up
        boolean isValid = false;
        if (generatedTitle != null) {
            generatedTitle = generatedTitle.trim();
            // Remove quotes if present
            if (generatedTitle.startsWith("\"") && generatedTitle.endsWith("\"")) {
                generatedTitle = generatedTitle.substring(1, generatedTitle.length() - 1).trim();
            }
            if (!generatedTitle.isEmpty()) {
                isValid = true;
            }
            // Truncate if too long (backup safety)
            if (generatedTitle.length() > 50) {
                generatedTitle = generatedTitle.substring(0, 50);
            }
        }

        if (!isValid) {
            // Fallback: use first message content or default
            if (!messages.isEmpty() && messages.get(0).getContent() != null) {
                String firstMsg = messages.get(0).getContent().trim();
                generatedTitle = firstMsg.length() > 20 ? firstMsg.substring(0, 20) + "..." : firstMsg;
            } else {
                generatedTitle = "New Chat";
            }
        }

        // 5. Update session
        updateSessionTitle(sessionId, generatedTitle);
        return generatedTitle;
    }

    @Override
    public void updateSessionSummary(String sessionId, String summary) {
        AiChatSession session = new AiChatSession();
        session.setId(sessionId);
        session.setSummary(summary);
        // Do not update time for internal summary updates to avoid re-ordering list
        // user sees?
        // Or should we? Let's keep it silent for now or update time?
        // PRD doesn't specify, but usually background tasks shouldn't bump the chat to
        // top if user didn't act.
        // But here user IS acting (sending message triggers it).
        // Actually, streamChatWithPersistence updates time when saving message anyway.
        sessionMapper.updateById(session);
    }
}
