package com.example.urgs_api.im.ws;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.example.urgs_api.im.entity.ImMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Component
public class ImWebSocketHandler extends TextWebSocketHandler {

    // Store sessions: userId -> WebSocketSession
    private static final Map<Long, WebSocketSession> userSessions = new ConcurrentHashMap<>();
    private final ObjectMapper objectMapper = new ObjectMapper();

    public ImWebSocketHandler() {
        objectMapper.registerModule(new com.fasterxml.jackson.datatype.jsr310.JavaTimeModule());
        objectMapper.disable(com.fasterxml.jackson.databind.SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        Long userId = getUserIdFromSession(session);
        if (userId != null) {
            userSessions.put(userId, session);
            log.info("User connected: " + userId);
        } else {
            session.close();
        }
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        // Handle incoming messages if needed (e.g. ping/pong, or upstream messages)
        // For now, we mainly use this for pushing messages DOWN to clients.
        String payload = message.getPayload();
        log.info("Received message: " + payload);
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        Long userId = getUserIdFromSession(session);
        if (userId != null) {
            userSessions.remove(userId);
            log.info("User disconnected: " + userId);
        }
    }

    /**
     * Push message to a specific user
     */
    public void sendMessageToUser(Long userId, ImMessage message) {
        WebSocketSession session = userSessions.get(userId);
        if (session != null && session.isOpen()) {
            try {
                String jsonMsg = objectMapper.writeValueAsString(message);
                session.sendMessage(new TextMessage(jsonMsg));
            } catch (IOException e) {
                log.error("Failed to send message to user " + userId, e);
            }
        }
    }

    private Long getUserIdFromSession(WebSocketSession session) {
        // In real app, extract from token or query param
        // For demo, assume query param ?userId=123
        try {
            String query = session.getUri().getQuery(); // "userId=123"
            if (query != null && query.contains("userId=")) {
                String[] parts = query.split("userId=");
                if (parts.length > 1) {
                    return Long.parseLong(parts[1].split("&")[0]);
                }
            }
        } catch (Exception e) {
            log.error("Error parsing userId from session", e);
        }
        return null;
    }
}
