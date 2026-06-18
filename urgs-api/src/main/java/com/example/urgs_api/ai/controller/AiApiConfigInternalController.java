package com.example.urgs_api.ai.controller;

import com.example.urgs_api.ai.entity.AiApiConfig;
import com.example.urgs_api.ai.service.AiApiConfigService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/internal/ai/config")
public class AiApiConfigInternalController {

    private final AiApiConfigService aiApiConfigService;

    public AiApiConfigInternalController(AiApiConfigService aiApiConfigService) {
        this.aiApiConfigService = aiApiConfigService;
    }

    @GetMapping("/default")
    public DefaultAiApiConfig getDefault() {
        AiApiConfig config = aiApiConfigService.getDefaultConfig();
        if (config == null) {
            return null;
        }
        return new DefaultAiApiConfig(
                config.getProvider(),
                config.getModel(),
                config.getEndpoint(),
                config.getApiKey(),
                config.getMaxTokens(),
                config.getTemperature());
    }

    public record DefaultAiApiConfig(
            String provider,
            String model,
            String endpoint,
            String apiKey,
            Integer maxTokens,
            Double temperature) {
    }
}
