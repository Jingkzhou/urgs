package com.example.urgs_api.ops.ws;

import com.example.urgs_api.ops.entity.DockerLogDTO;
import com.example.urgs_api.ops.service.DockerLogStreamService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;
import org.springframework.web.util.UriComponentsBuilder;

import java.io.IOException;
import java.net.URI;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Component
public class DockerLogWebSocketHandler extends TextWebSocketHandler {

    @Autowired
    private DockerLogStreamService logStreamService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    // sessionId -> set of streamKeys
    private final Map<String, Set<String>> sessionStreams = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        String sessionId = session.getId();
        sessionStreams.put(sessionId, ConcurrentHashMap.newKeySet());

        // Check if containerId is passed as query parameter
        URI uri = session.getUri();
        if (uri != null) {
            String query = uri.getQuery();
            if (query != null) {
                Map<String, String> params = UriComponentsBuilder.fromUri(uri).build()
                        .getQueryParams().toSingleValueMap();
                String containerIds = params.get("containerIds");
                if (containerIds != null && !containerIds.isEmpty()) {
                    for (String cid : containerIds.split(",")) {
                        String trimmed = cid.trim();
                        if (!trimmed.isEmpty()) {
                            subscribeContainer(session, trimmed);
                        }
                    }
                }
            }
        }

        log.info("Docker log WebSocket connected: {}", sessionId);
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        String payload = message.getPayload();

        // Handle ping
        if ("ping".equals(payload)) {
            if (session.isOpen()) {
                session.sendMessage(new TextMessage("pong"));
            }
            return;
        }

        try {
            JsonNode json = objectMapper.readTree(payload);
            String action = json.has("action") ? json.get("action").asText() : "";
            String containerId = json.has("containerId") ? json.get("containerId").asText() : "";

            switch (action) {
                case "subscribe":
                    if (!containerId.isEmpty()) {
                        subscribeContainer(session, containerId);
                    }
                    break;
                case "unsubscribe":
                    if (!containerId.isEmpty()) {
                        unsubscribeContainer(session, containerId);
                    }
                    break;
                default:
                    log.warn("Unknown action: {}", action);
            }
        } catch (Exception e) {
            log.error("Error handling WebSocket message: {}", payload, e);
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        String sessionId = session.getId();
        Set<String> streamKeys = sessionStreams.remove(sessionId);
        if (streamKeys != null) {
            streamKeys.forEach(logStreamService::stopStream);
        }
        log.info("Docker log WebSocket disconnected: {}, status: {}", sessionId, status);
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) throws Exception {
        log.error("Docker log WebSocket transport error for session {}", session.getId(), exception);
        afterConnectionClosed(session, CloseStatus.SERVER_ERROR);
    }

    private void subscribeContainer(WebSocketSession session, String containerId) {
        String streamKey = logStreamService.startStream(containerId, logEntry -> {
            sendLog(session, logEntry);
        });

        if (streamKey != null) {
            Set<String> keys = sessionStreams.get(session.getId());
            if (keys != null) {
                keys.add(streamKey);
            }
            log.info("Session {} subscribed to container {}", session.getId(), containerId);
        }
    }

    private void unsubscribeContainer(WebSocketSession session, String containerId) {
        Set<String> keys = sessionStreams.get(session.getId());
        if (keys != null) {
            keys.removeIf(key -> {
                if (key.startsWith(containerId + "-")) {
                    logStreamService.stopStream(key);
                    return true;
                }
                return false;
            });
        }
        log.info("Session {} unsubscribed from container {}", session.getId(), containerId);
    }

    private void sendLog(WebSocketSession session, DockerLogDTO logEntry) {
        if (!session.isOpen()) return;
        try {
            String json = objectMapper.writeValueAsString(logEntry);
            synchronized (session) {
                session.sendMessage(new TextMessage(json));
            }
        } catch (IOException e) {
            log.error("Failed to send log to WebSocket session {}", session.getId(), e);
        }
    }
}
