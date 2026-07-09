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
        session.setTitle((title == null || title.isBlank()) ? "New Chat" : title);
        session.setAgentId(agentId);
        session.setAgentBindingMode(agentId == null ? null : "MANUAL");
        session.setCreateTime(LocalDateTime.now());
        session.setUpdateTime(LocalDateTime.now());
        session.setIsDeleted(0);

        sessionMapper.insert(session);
        return session;
    }

    @Override
    public List<AiChatSession> getUserSessions(String userId) {
        List<AiChatSession> sessions = sessionMapper.selectList(new LambdaQueryWrapper<AiChatSession>()
                .eq(AiChatSession::getUserId, userId)
                .orderByDesc(AiChatSession::getUpdateTime));
        for (AiChatSession session : sessions) {
            repairInvalidSessionTitle(session);
        }
        return sessions;
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
    public void updateSession(AiChatSession session) {
        if (session.getUpdateTime() == null) {
            session.setUpdateTime(LocalDateTime.now());
        }
        sessionMapper.updateById(session);
    }

    @Override
    public AiChatMessage saveMessage(String sessionId, String role, String content) {
        if (sessionId == null || sessionId.isBlank()
                || role == null || role.isBlank()
                || content == null || content.isBlank()) {
            return null;
        }

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
        int appended = 0;
        for (int i = 0; i < messages.size() && appended < 4; i++) {
            AiChatMessage msg = messages.get(i);
            String content = normalizeTitleSourceContent(msg.getContent());
            if (content == null) {
                continue;
            }
            conversation.append(msg.getRole()).append(": ").append(content).append("\n");
            appended++;
        }
        if (conversation.length() == 0) {
            String fallbackTitle = fallbackTitleFromMessages(messages);
            updateSessionTitle(sessionId, fallbackTitle);
            return fallbackTitle;
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
            if (!generatedTitle.isEmpty() && !isInvalidGeneratedTitle(generatedTitle)) {
                isValid = true;
            }
            // Truncate if too long (backup safety)
            if (generatedTitle.length() > 50) {
                generatedTitle = generatedTitle.substring(0, 50);
            }
        }

        if (!isValid) {
            generatedTitle = fallbackTitleFromMessages(messages);
        }

        // 5. Update session
        updateSessionTitle(sessionId, generatedTitle);
        return generatedTitle;
    }

    private boolean isInvalidGeneratedTitle(String title) {
        String normalized = title.trim().toLowerCase();
        return normalized.matches("^(null)+.*")
                || normalized.matches("^(undefined)+.*")
                || normalized.startsWith("#")
                || normalized.contains("\n")
                || normalized.length() > 50;
    }

    private void repairInvalidSessionTitle(AiChatSession session) {
        String title = session.getTitle();
        if (title != null && !title.isBlank() && !isInvalidGeneratedTitle(title)) {
            return;
        }
        String fallbackTitle = fallbackTitleFromMessages(getSessionMessages(session.getId()));
        session.setTitle(fallbackTitle);
        updateSessionTitle(session.getId(), fallbackTitle);
    }

    private String fallbackTitleFromMessages(List<AiChatMessage> messages) {
        for (AiChatMessage message : messages) {
            if (!"user".equals(message.getRole())) {
                continue;
            }
            String content = normalizeTitleSourceContent(message.getContent());
            if (content != null) {
                return truncateTitle(content);
            }
        }
        return "New Chat";
    }

    private String normalizeTitleSourceContent(String content) {
        if (content == null) {
            return null;
        }
        String normalized = content.trim();
        if (normalized.isEmpty() || isInvalidGeneratedTitle(normalized)) {
            return null;
        }
        return normalized;
    }

    private String truncateTitle(String title) {
        return title.length() > 20 ? title.substring(0, 20) + "..." : title;
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
