package com.example.urgs_api.ai.controller;

import com.example.urgs_api.ai.service.AiUsageLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

/**
 * AI 使用记录控制器
 */
@RestController
@RequestMapping("/api/ai/usage")
public class AiUsageLogController {

    @Autowired
    private AiUsageLogService aiUsageLogService;

    /**
     * 记录使用统计
     */
    @PostMapping("/record")
    public Map<String, Object> record(@RequestBody Map<String, Object> usageData) {
        Map<String, Object> result = new HashMap<>();

        try {
            Long configId = usageData.get("configId") != null ? Long.valueOf(usageData.get("configId").toString())
                    : null;
            String model = (String) usageData.get("model");
            Integer promptTokens = (Integer) usageData.get("promptTokens");
            Integer completionTokens = (Integer) usageData.get("completionTokens");
            String requestType = (String) usageData.get("requestType");
            Boolean success = (Boolean) usageData.get("success");
            String errorMessage = (String) usageData.get("errorMessage");

            aiUsageLogService.recordUsage(configId, model, promptTokens, completionTokens, requestType, success,
                    errorMessage);

            result.put("success", true);
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", e.getMessage());
        }

        return result;
    }
}
