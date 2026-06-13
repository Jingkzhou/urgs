package com.example.executor.quartz.service;

import com.example.executor.common.InternalApiAuthHeaderProvider;
import com.example.executor.quartz.domain.entity.QuartzTaskEntity;
import com.example.executor.quartz.domain.entity.QuartzTaskStatusEntity;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
public class ProblemTransferClient {

    private final RestTemplate restTemplate;
    private final InternalApiAuthHeaderProvider authHeaderProvider;

    @Value("${task.api-base-url:http://127.0.0.1:8080}")
    private String apiBaseUrl;

    public ProblemTransferClient(RestTemplateBuilder restTemplateBuilder,
            InternalApiAuthHeaderProvider authHeaderProvider) {
        this.restTemplate = restTemplateBuilder.build();
        this.authHeaderProvider = authHeaderProvider;
    }

    public void transferFailedInstance(QuartzTaskEntity task, QuartzTaskStatusEntity status) {
        if (task == null || status == null) {
            return;
        }

        Map<String, Object> payload = new HashMap<>();
        payload.put("planId", status.getPlanId());
        payload.put("dataDate", status.getDataDate());

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        authHeaderProvider.apply(headers);

        try {
            restTemplate.postForObject(
                    apiBaseUrl + "/api/internal/quartz/task/status/transfer-problem",
                    new HttpEntity<>(payload, headers),
                    Map.class
            );
        } catch (Exception e) {
            log.warn("{} 自动转存生产问题失败: {}", taskTag(task, status), e.getMessage());
        }
    }

    private String taskTag(QuartzTaskEntity task, QuartzTaskStatusEntity status) {
        return "[taskId=" + task.getId() + "][taskName=" + task.getTaskName() + "][dataDate=" + status.getDataDate() + "]";
    }
}
