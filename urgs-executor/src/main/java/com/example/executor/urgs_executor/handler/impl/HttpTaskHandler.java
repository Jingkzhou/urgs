package com.example.executor.urgs_executor.handler.impl;

import com.example.executor.urgs_executor.entity.DataSourceConfig;
import com.example.executor.urgs_executor.entity.TaskInstance;
import com.example.executor.urgs_executor.handler.TaskHandler;
import com.example.executor.urgs_executor.mapper.DataSourceConfigMapper;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

@Slf4j
@Component("HTTP")
public class HttpTaskHandler implements TaskHandler {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final RestTemplate restTemplate = new RestTemplate();

    @Autowired
    private DataSourceConfigMapper dataSourceConfigMapper;

    @Override
    public String execute(TaskInstance instance) throws Exception {
        String url = "";
        String method = "GET";
        String body = null;
        String resourceId = null;

        if (instance.getContentSnapshot() != null) {
            JsonNode node = objectMapper.readTree(instance.getContentSnapshot());
            if (node.has("url"))
                url = node.get("url").asText("");
            if (node.has("method"))
                method = node.get("method").asText().toUpperCase();
            if (node.has("body"))
                body = node.get("body").asText();
            if (node.has("resource"))
                resourceId = node.get("resource").asText();
        }

        // Replace $dataDate with actual date
        // Replace $dataDate with actual date
        url = url.replace("$dataDate", instance.getDataDate());
        if (body != null)
            body = body.replace("$dataDate", instance.getDataDate());

        // If resource is provided, use it as base configuration
        if (resourceId != null && !resourceId.isEmpty()) {
            DataSourceConfig config = dataSourceConfigMapper.selectById(resourceId);
            if (config == null) {
                throw new RuntimeException("Resource not found: " + resourceId);
            }
            Map<String, Object> params = config.getConnectionParams();

            // Override or prepend base URL
            if (params.containsKey("url")) {
                String baseUrl = (String) params.get("url");
                // If the task specific URL is relative (starts with /), append it
                // If task URL is empty, use base URL
                // If task URL is absolute, use it (ignoring base? or maybe error?)
                // For simplicity: if task URL is present, treat it as full URL or relative
                // path?
                // Let's assume task URL is relative path if resource is present.
                if (url.startsWith("/")) {
                    url = baseUrl.replaceAll("/$", "") + url;
                } else if (url.isEmpty()) {
                    url = baseUrl;
                }
            }

            if (params.containsKey("method") && method.equals("GET")) { // Only override default
                method = ((String) params.get("method")).toUpperCase();
            }
        }

        if (url.isEmpty()) {
            throw new IllegalArgumentException("HTTP task missing URL");
        }

        log.info("Executing HTTP Task {}: {} {}", instance.getId(), method, url);

        HttpHeaders headers = new HttpHeaders();
        // Add default headers or headers from config if needed
        // For now, we assume simple requests.
        // If we want headers from config, we'd need to parse them from params.

        HttpEntity<String> entity = new HttpEntity<>(body, headers);

        try {
            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.valueOf(method), entity,
                    String.class);

            String result = response.getBody();
            log.info("HTTP Result: {}", result);
            return "HTTP Request to " + url + "\nMethod: " + method + "\nStatus: " + response.getStatusCode()
                    + "\nResult:\n" + result;
        } catch (Exception e) {
            log.error("HTTP Task failed", e);
            throw new RuntimeException("HTTP request failed: " + e.getMessage());
        }
    }
}
