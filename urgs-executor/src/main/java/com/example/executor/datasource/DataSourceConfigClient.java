package com.example.executor.datasource;

import lombok.Data;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

@Component
public class DataSourceConfigClient {

    private final RestTemplate restTemplate;

    @Value("${task.api-base-url:http://127.0.0.1:8080}")
    private String apiBaseUrl;

    public DataSourceConfigClient(RestTemplateBuilder restTemplateBuilder) {
        this.restTemplate = restTemplateBuilder.build();
    }

    public ResolvedDataSourceConfig getResolvedConfig(Long datasourceId) {
        if (datasourceId == null) {
            return null;
        }
        String url = apiBaseUrl + "/api/datasource/config/" + datasourceId + "/resolved";
        return restTemplate.getForObject(url, ResolvedDataSourceConfig.class);
    }

    @Data
    private static class ApiResponse<T> {
        private boolean success;
        private String msg;
        private T data;
    }
}
