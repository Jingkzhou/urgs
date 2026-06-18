package com.example.urgs_api.ai.service;

import com.example.urgs_api.ai.entity.AiAgentRun;
import com.example.urgs_api.ai.entity.AiAgentRunEvent;
import com.example.urgs_api.ai.entity.Agent;
import com.example.urgs_api.ai.repository.AiAgentRunEventRepository;
import com.example.urgs_api.ai.repository.AiAgentRunRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

@Service
public class AiAgentRunService {

    private static final Logger log = LoggerFactory.getLogger(AiAgentRunService.class);
    private static final ObjectMapper objectMapper = new ObjectMapper();

    private final AiAgentRunRepository runRepository;
    private final AiAgentRunEventRepository eventRepository;

    public AiAgentRunService(AiAgentRunRepository runRepository, AiAgentRunEventRepository eventRepository) {
        this.runRepository = runRepository;
        this.eventRepository = eventRepository;
    }

    public String createRun(String sessionId, String userId, Agent agent, String userPrompt) {
        try {
            AiAgentRun run = new AiAgentRun();
            run.setId(UUID.randomUUID().toString());
            run.setSessionId(sessionId);
            run.setUserId(userId);
            applyAgent(run, agent);
            run.setStatus("RUNNING");
            run.setUserPrompt(trimToLength(userPrompt, 4000));
            run.setStartTime(LocalDateTime.now());
            runRepository.insert(run);
            return run.getId();
        } catch (Exception e) {
            log.warn("Failed to create agent run for session {}", sessionId, e);
            return null;
        }
    }

    public void updateRouting(String runId, Agent agent, String intent, Double confidence) {
        if (isBlank(runId)) {
            return;
        }
        try {
            AiAgentRun run = new AiAgentRun();
            run.setId(runId);
            applyAgent(run, agent);
            run.setRouterIntent(intent);
            run.setRouterConfidence(confidence);
            runRepository.updateById(run);
        } catch (Exception e) {
            log.warn("Failed to update agent run routing {}", runId, e);
        }
    }

    public void recordEvent(String runId, String sessionId, Agent agent, String eventType, String title,
            String content, Map<String, Object> payload, String status) {
        if (isBlank(runId)) {
            return;
        }
        try {
            AiAgentRunEvent event = new AiAgentRunEvent();
            event.setRunId(runId);
            event.setSessionId(sessionId);
            if (agent != null) {
                event.setAgentId(agent.getId());
                event.setAgentCode(agent.getAgentCode());
            }
            event.setEventType(eventType);
            event.setTitle(title);
            event.setContent(trimToLength(content, 4000));
            event.setPayload(payload == null ? null : objectMapper.writeValueAsString(payload));
            event.setStatus(status);
            event.setCreateTime(LocalDateTime.now());
            eventRepository.insert(event);
        } catch (Exception e) {
            log.warn("Failed to record agent run event {} for run {}", eventType, runId, e);
        }
    }

    public void completeRun(String runId) {
        finishRun(runId, "COMPLETED", null);
    }

    public void failRun(String runId, String errorMessage) {
        finishRun(runId, "FAILED", errorMessage);
    }

    private void finishRun(String runId, String status, String errorMessage) {
        if (isBlank(runId)) {
            return;
        }
        try {
            AiAgentRun run = new AiAgentRun();
            run.setId(runId);
            run.setStatus(status);
            run.setEndTime(LocalDateTime.now());
            run.setErrorMessage(trimToLength(errorMessage, 2000));
            runRepository.updateById(run);
        } catch (Exception e) {
            log.warn("Failed to finish agent run {}", runId, e);
        }
    }

    private void applyAgent(AiAgentRun run, Agent agent) {
        if (agent == null) {
            return;
        }
        run.setAgentId(agent.getId());
        run.setAgentCode(agent.getAgentCode());
        run.setAgentName(agent.getName());
    }

    private String trimToLength(String value, int maxLength) {
        if (value == null || value.length() <= maxLength) {
            return value;
        }
        return value.substring(0, maxLength);
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}
