package com.example.urgs_api.quartz.service;

import com.example.urgs_api.quartz.domain.dto.ExecutorPoolStatsVO;
import com.example.urgs_api.quartz.support.constant.ResponseCodeConst;
import com.example.urgs_api.quartz.support.domain.ResponseDTO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.Duration;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

@Slf4j
@Service
public class ExecutorClientService {

    private final RestTemplate commandRestTemplate;
    private final RestTemplate statsRestTemplate;
    private final String executorBaseUrl;

    @Autowired
    public ExecutorClientService(
            RestTemplateBuilder restTemplateBuilder,
            @Value("${executor.base-url:http://127.0.0.1:8082}") String executorBaseUrl,
            @Value("${executor.stats-connect-timeout-ms:2000}") long statsConnectTimeoutMs,
            @Value("${executor.stats-read-timeout-ms:3000}") long statsReadTimeoutMs) {
        this.commandRestTemplate = restTemplateBuilder.build();
        this.statsRestTemplate = restTemplateBuilder
                .setConnectTimeout(Duration.ofMillis(statsConnectTimeoutMs))
                .setReadTimeout(Duration.ofMillis(statsReadTimeoutMs))
                .build();
        this.executorBaseUrl = executorBaseUrl;
    }

    ExecutorClientService(RestTemplate restTemplate, String executorBaseUrl) {
        this.commandRestTemplate = restTemplate;
        this.statsRestTemplate = restTemplate;
        this.executorBaseUrl = executorBaseUrl;
    }

    public ResponseDTO<ExecutorPoolStatsVO> getPoolStats() {
        try {
            ResponseEntity<ResponseDTO<ExecutorPoolStatsVO>> responseEntity = statsRestTemplate.exchange(
                    executorBaseUrl + "/api/executor/task/pool/stats",
                    HttpMethod.GET,
                    null,
                    new ParameterizedTypeReference<ResponseDTO<ExecutorPoolStatsVO>>() { }
            );
            ResponseDTO<ExecutorPoolStatsVO> response = responseEntity.getBody();
            if (response == null) {
                return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "执行器未返回结果");
            }
            if (!response.isSuccess()) {
                return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM,
                        response.getMsg() == null ? "获取执行器线程池统计失败" : response.getMsg());
            }
            if (response.getData() == null) {
                return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "执行器返回的线程池统计为空");
            }
            return ResponseDTO.succData(response.getData());
        } catch (Exception e) {
            log.error("Call executor pool stats failed", e);
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "调用执行器线程池统计失败");
        }
    }

    public ResponseDTO<ExecutorStopResultData> stopTask(Long planId, String dataDate) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, Object> payload = new HashMap<>();
            payload.put("planId", planId);
            payload.put("dataDate", dataDate);

            @SuppressWarnings("unchecked")
            ResponseDTO<Object> response = commandRestTemplate.postForObject(
                    executorBaseUrl + "/api/executor/task/stop",
                    new HttpEntity<>(payload, headers),
                    ResponseDTO.class
            );

            if (response == null) {
                return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "执行器未返回结果");
            }
            if (!response.isSuccess()) {
                return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, response.getMsg() == null ? "执行器停止任务失败" : response.getMsg());
            }
            Map<String, Object> data = (Map<String, Object>) response.getData();
            if (data == null) {
                return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "执行器返回结果缺失");
            }
            boolean foundRunningTask = Boolean.TRUE.equals(data.get("foundRunningTask"));
            boolean cancelled = Boolean.TRUE.equals(data.get("cancelled"));
            String taskKey = Objects.toString(data.get("taskKey"), planId + "_" + dataDate);
            return ResponseDTO.succData(new ExecutorStopResultData(foundRunningTask, cancelled, taskKey));
        } catch (Exception e) {
            log.error("Call executor stop task failed, planId={}, dataDate={}", planId, dataDate, e);
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "调用执行器停止任务失败");
        }
    }

    public ResponseDTO<String> triggerNow(Long planId, String dataDate) {
        return triggerNow(planId, dataDate, "manual");
    }

    public ResponseDTO<String> triggerNow(Long planId, String dataDate, String triggerType) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, Object> payload = new HashMap<>();
            payload.put("planId", planId);
            payload.put("dataDate", dataDate);
            payload.put("triggerType", triggerType);

            @SuppressWarnings("unchecked")
            ResponseDTO<Object> response = commandRestTemplate.postForObject(
                    executorBaseUrl + "/api/executor/task/triggerNow",
                    new HttpEntity<>(payload, headers),
                    ResponseDTO.class
            );

            if (response == null) {
                return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "执行器未返回结果");
            }
            if (!response.isSuccess()) {
                return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, response.getMsg() == null ? "执行器触发任务失败" : response.getMsg());
            }
            return ResponseDTO.succ();
        } catch (Exception e) {
            log.error("Call executor triggerNow failed, planId={}, dataDate={}", planId, dataDate, e);
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "调用执行器立即触发失败");
        }
    }

    public static class ExecutorStopResultData {
        private final boolean foundRunningTask;
        private final boolean cancelled;
        private final String taskKey;

        public ExecutorStopResultData(boolean foundRunningTask, boolean cancelled, String taskKey) {
            this.foundRunningTask = foundRunningTask;
            this.cancelled = cancelled;
            this.taskKey = taskKey;
        }

        public boolean isFoundRunningTask() {
            return foundRunningTask;
        }

        public boolean isCancelled() {
            return cancelled;
        }

        public String getTaskKey() {
            return taskKey;
        }
    }

}
