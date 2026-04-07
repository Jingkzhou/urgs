package com.example.urgs_api.quartz.service;

import com.example.urgs_api.quartz.support.constant.ResponseCodeConst;
import com.example.urgs_api.quartz.support.domain.ResponseDTO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
public class ExecutorClientService {

    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${executor.base-url:http://127.0.0.1:8081}")
    private String executorBaseUrl;

    public ResponseDTO<String> stopTask(Long planId, String dataDate) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, Object> payload = new HashMap<>();
            payload.put("planId", planId);
            payload.put("dataDate", dataDate);

            @SuppressWarnings("unchecked")
            ResponseDTO<Object> response = restTemplate.postForObject(
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
            return ResponseDTO.succ();
        } catch (Exception e) {
            log.error("Call executor stop task failed, planId={}, dataDate={}", planId, dataDate, e);
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "调用执行器停止任务失败: " + e.getMessage());
        }
    }

    public ResponseDTO<String> triggerNow(Long planId, String dataDate) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, Object> payload = new HashMap<>();
            payload.put("planId", planId);
            payload.put("dataDate", dataDate);

            @SuppressWarnings("unchecked")
            ResponseDTO<Object> response = restTemplate.postForObject(
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
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "调用执行器立即触发失败: " + e.getMessage());
        }
    }
}
