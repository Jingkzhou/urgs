package com.example.executor.datasource;

import com.example.executor.common.InternalApiAuthHeaderProvider;
import org.junit.jupiter.api.Test;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.RestTemplate;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class DataSourceConfigClientTest {

    @Test
    void sendsInternalApiCredential() {
        RestTemplate restTemplate = mock(RestTemplate.class);
        RestTemplateBuilder builder = mock(RestTemplateBuilder.class);
        when(builder.build()).thenReturn(restTemplate);
        InternalApiAuthHeaderProvider auth = new InternalApiAuthHeaderProvider(
                "Authorization", "Bearer ", "shared-token");
        DataSourceConfigClient client = new DataSourceConfigClient(builder, auth);
        ReflectionTestUtils.setField(client, "apiBaseUrl", "http://api");
        when(restTemplate.exchange(
                eq("http://api/api/internal/datasource/config/12/resolved"),
                eq(HttpMethod.GET),
                org.mockito.ArgumentMatchers.<HttpEntity<Void>>any(),
                eq(ResolvedDataSourceConfig.class)))
                .thenReturn(ResponseEntity.ok(new ResolvedDataSourceConfig()));

        client.getResolvedConfig(12L);

        @SuppressWarnings("unchecked")
        org.mockito.ArgumentCaptor<HttpEntity<Void>> entityCaptor = org.mockito.ArgumentCaptor.forClass(HttpEntity.class);
        verify(restTemplate).exchange(
                eq("http://api/api/internal/datasource/config/12/resolved"),
                eq(HttpMethod.GET),
                entityCaptor.capture(),
                eq(ResolvedDataSourceConfig.class));
        assertEquals("Bearer shared-token", entityCaptor.getValue().getHeaders().getFirst("Authorization"));
    }
}
