package com.example.executor.quartz.service;

import com.example.executor.common.InternalApiAuthHeaderProvider;
import com.example.executor.quartz.domain.entity.QuartzTaskEntity;
import com.example.executor.quartz.domain.entity.QuartzTaskStatusEntity;
import org.junit.jupiter.api.Test;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.HttpEntity;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ProblemTransferClientTest {

    @Test
    void sendsInternalApiCredential() {
        RestTemplate restTemplate = mock(RestTemplate.class);
        RestTemplateBuilder builder = mock(RestTemplateBuilder.class);
        when(builder.build()).thenReturn(restTemplate);
        InternalApiAuthHeaderProvider auth = new InternalApiAuthHeaderProvider(
                "Authorization", "Bearer ", "shared-token");
        ProblemTransferClient client = new ProblemTransferClient(builder, auth);
        ReflectionTestUtils.setField(client, "apiBaseUrl", "http://api");

        QuartzTaskEntity task = mock(QuartzTaskEntity.class);
        QuartzTaskStatusEntity status = mock(QuartzTaskStatusEntity.class);
        client.transferFailedInstance(task, status);

        @SuppressWarnings("unchecked")
        org.mockito.ArgumentCaptor<HttpEntity<Map<String, Object>>> entityCaptor =
                org.mockito.ArgumentCaptor.forClass(HttpEntity.class);
        verify(restTemplate).postForObject(
                eq("http://api/api/internal/quartz/task/status/transfer-problem"),
                entityCaptor.capture(),
                eq(Map.class));
        assertEquals("Bearer shared-token", entityCaptor.getValue().getHeaders().getFirst("Authorization"));
    }
}
