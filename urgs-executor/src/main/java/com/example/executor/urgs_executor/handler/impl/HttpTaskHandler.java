package com.example.executor.urgs_executor.handler.impl;

import com.example.executor.urgs_executor.entity.DataSourceConfig;
import com.example.executor.urgs_executor.entity.ExecutorTaskInstance;
import com.example.executor.urgs_executor.handler.TaskHandler;
import com.example.executor.urgs_executor.mapper.DataSourceConfigMapper;
import com.example.executor.urgs_executor.util.PlaceholderUtils;
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
    public String execute(ExecutorTaskInstance instance) throws Exception {
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

        // 将 $dataDate 替换为实际业务日期
        url = PlaceholderUtils.replaceDataDate(url, instance.getDataDate());
        body = PlaceholderUtils.replaceDataDate(body, instance.getDataDate());

        // 如果配置了资源节点，用作基础配置
        if (resourceId != null && !resourceId.isEmpty()) {
            DataSourceConfig config = dataSourceConfigMapper.selectById(resourceId);
            if (config == null) {
                throw new RuntimeException("未找到资源节点: " + resourceId);
            }
            Map<String, Object> params = config.getConnectionParams();

            if (params.containsKey("url")) {
                String baseUrl = (String) params.get("url");
                if (url.startsWith("/")) {
                    url = baseUrl.replaceAll("/$", "") + url;
                } else if (url.isEmpty()) {
                    url = baseUrl;
                }
            }

            if (params.containsKey("method") && method.equals("GET")) {
                method = ((String) params.get("method")).toUpperCase();
            }
        }

        if (url.isEmpty()) {
            throw new IllegalArgumentException("HTTP 任务缺少 URL 配置");
        }

        log.info("开始执行 HTTP 任务 {}: {} {}", instance.getId(), method, url);

        HttpHeaders headers = new HttpHeaders();
        HttpEntity<String> entity = new HttpEntity<>(body, headers);

        try {
            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.valueOf(method), entity,
                    String.class);

            String result = response.getBody();
            log.info("HTTP 响应结果: {}", result);

            String ts = java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            StringBuilder logStr = new StringBuilder();
            logStr.append("[").append(ts).append("] HTTP 请求地址: ").append(url).append("\n");
            logStr.append("[").append(ts).append("] 请求方法: ").append(method).append("\n");
            logStr.append("[").append(ts).append("] 响应状态: ").append(response.getStatusCode()).append("\n");
            logStr.append("[").append(ts).append("] 响应内容:\n");

            if (result != null) {
                for (String rLine : result.split("\n")) {
                    logStr.append("[").append(ts).append("] ").append(rLine).append("\n");
                }
            }
            return logStr.toString();
        } catch (Exception e) {
            log.error("HTTP 任务执行失败", e);
            throw new RuntimeException("HTTP 请求失败: " + e.getMessage());
        }
    }
}
