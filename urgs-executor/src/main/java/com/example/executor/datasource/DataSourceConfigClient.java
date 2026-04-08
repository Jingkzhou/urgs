package com.example.executor.datasource;

import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;

@Slf4j
@Component
public class DataSourceConfigClient {

    private final RestTemplate restTemplate;

    @Value("${task.api-base-url:http://127.0.0.1:8080}")
    private String apiBaseUrl;

    @Value("${task.api-auth-header:Authorization}")
    private String apiAuthHeader;

    @Value("${task.api-auth-prefix:Bearer }")
    private String apiAuthPrefix;

    @Value("${task.api-auth-token:}")
    private String apiAuthToken;

    public DataSourceConfigClient(RestTemplateBuilder restTemplateBuilder) {
        this.restTemplate = restTemplateBuilder.build();
    }

    public ResolvedDataSourceConfig getResolvedConfig(Long datasourceId) {
        if (datasourceId == null) {
            return null;
        }
        String url = apiBaseUrl + "/api/internal/datasource/config/" + datasourceId + "/resolved";
        try {
            HttpHeaders headers = new HttpHeaders();
            if (StringUtils.hasText(apiAuthToken) && StringUtils.hasText(apiAuthHeader)) {
                headers.set(apiAuthHeader, apiAuthPrefix + apiAuthToken);
            }
            ResponseEntity<ResolvedDataSourceConfig> response = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    new HttpEntity<>(headers),
                    ResolvedDataSourceConfig.class
            );
            return response.getBody();
        } catch (HttpClientErrorException.Unauthorized e) {
            log.error("Unauthorized when loading datasource config, datasourceId={}, url={}, authHeaderConfigured={}",
                    datasourceId, url, StringUtils.hasText(apiAuthToken));
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
