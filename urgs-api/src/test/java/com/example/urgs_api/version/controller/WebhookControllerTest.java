package com.example.urgs_api.version.controller;

import com.example.urgs_api.version.audit.service.AiCodeReviewService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.nio.charset.StandardCharsets;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

@ExtendWith(MockitoExtension.class)
class WebhookControllerTest {

    @Mock
    private AiCodeReviewService aiCodeReviewService;

    private WebhookController controller;

    @BeforeEach
    void setUp() {
        controller = new WebhookController(new ObjectMapper(), aiCodeReviewService);
    }

    @Test
    void acceptsValidGitHubSignatureAndTriggersReview() {
        byte[] payload = "{\"ref\":\"refs/heads/main\",\"after\":\"commit-sha\",\"user_email\":\"dev@example.com\"}"
                .getBytes(StandardCharsets.UTF_8);

        ResponseEntity<Map<String, String>> response = controller.handleGitHubWebhook(
                1L, "push", payload);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(aiCodeReviewService).triggerReview(1L, "commit-sha", "main", "dev@example.com");
    }

    @Test
    void rejectsMalformedPayload() {
        byte[] payload = "not-json".getBytes(StandardCharsets.UTF_8);

        ResponseEntity<Map<String, String>> response = controller.handleGitHubWebhook(
                1L, "push", payload);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        verifyNoInteractions(aiCodeReviewService);
    }
}
