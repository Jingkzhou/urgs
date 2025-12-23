package com.example.urgs_api.ai.service;

import com.example.urgs_api.ai.entity.AiChatMessage;
import com.example.urgs_api.ai.entity.AiChatSession;

import java.util.List;

public interface AiChatHistoryService {

    /**
     * 创建新会话
     */
    AiChatSession createSession(String userId, String title, Long agentId);

    /**
     * 获取用户所有会话
     */
    List<AiChatSession> getUserSessions(String userId);

    /**
     * 获取会话
     */
    AiChatSession getSession(String sessionId);

    /**
     * 删除会话
     */
    void deleteSession(String sessionId, String userId);

    /**
     * 更新会话标题
     */
    void updateSessionTitle(String sessionId, String title);

    /**
     * 记录消息
     */
    AiChatMessage saveMessage(String sessionId, String role, String content);

    /**
     * 获取会话所有消息
     */
    List<AiChatMessage> getSessionMessages(String sessionId);

    /**
     * 生成并更新会话标题
     */
    String generateSessionTitle(String sessionId);

    /**
     * Update session summary
     */
    void updateSessionSummary(String sessionId, String summary);
}
