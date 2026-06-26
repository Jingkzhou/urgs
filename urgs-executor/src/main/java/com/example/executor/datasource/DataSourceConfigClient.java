package com.example.executor.datasource;

import com.example.executor.common.InternalApiAuthHeaderProvider;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Component
public class DataSourceConfigClient {

    private final RestTemplate restTemplate;
    private final InternalApiAuthHeaderProvider authHeaderProvider;
    private final Map<Long, ResolvedDataSourceConfig> configCache = new ConcurrentHashMap<>();

    @Value("${task.api-base-url:http://127.0.0.1:8080}")
    private String apiBaseUrl;

    public DataSourceConfigClient(RestTemplateBuilder restTemplateBuilder,
            InternalApiAuthHeaderProvider authHeaderProvider) {
        this.restTemplate = restTemplateBuilder.build();
        this.authHeaderProvider = authHeaderProvider;
    }

    public ResolvedDataSourceConfig getResolvedConfig(Long datasourceId) {
        if (datasourceId == null) {
            return null;
        }
        return configCache.computeIfAbsent(datasourceId, this::fetchResolvedConfig);
    }

    private ResolvedDataSourceConfig fetchResolvedConfig(Long datasourceId) {
        String url = apiBaseUrl + "/api/internal/datasource/config/" + datasourceId + "/resolved";
        try {
            HttpHeaders headers = new HttpHeaders();
            authHeaderProvider.apply(headers);
            ResponseEntity<ResolvedDataSourceConfig> response = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    new HttpEntity<>(headers),
                    ResolvedDataSourceConfig.class
            );
            return response.getBody();
        } catch (HttpClientErrorException.Unauthorized e) {
            log.error("Unauthorized when loading datasource config, datasourceId={}, url={}", datasourceId, url);
            throw e;
        }
    }

    @Data
    private static class ApiResponse<T> {
        private boolean success;
        private String msg;
        private T data;
    }
}
