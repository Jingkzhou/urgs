package com.example.urgs_api.ai.controller;

import com.example.urgs_api.ai.entity.AiApiConfig;
import com.example.urgs_api.ai.service.AiApiConfigService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * AI API 配置控制器
 */
@RestController
@RequestMapping("/api/ai/config")
public class AiApiConfigController {

    @Autowired
    private AiApiConfigService aiApiConfigService;

    /**
     * 获取所有 AI API 配置
     */
    @GetMapping
    public List<AiApiConfig> list() {
        return aiApiConfigService.getAllConfigs();
    }

    /**
     * 获取单个配置
     */
    @GetMapping("/{id}")
    public AiApiConfig getById(@PathVariable Long id) {
        return aiApiConfigService.getById(id);
    }

    /**
     * 获取默认配置
     */
    @GetMapping("/default")
    public AiApiConfig getDefault() {
        return aiApiConfigService.getDefaultConfig();
    }

    /**
     * 新增配置
     */
    @PostMapping
    public Map<String, Object> create(@RequestBody AiApiConfig config) {
        Map<String, Object> result = new HashMap<>();
        boolean success = aiApiConfigService.save(config);
        result.put("success", success);
        result.put("id", config.getId());
        return result;
    }

    /**
     * 更新配置
     */
    @PutMapping("/{id}")
    public Map<String, Object> update(@PathVariable Long id, @RequestBody AiApiConfig config) {
        Map<String, Object> result = new HashMap<>();
        config.setId(id);
        boolean success = aiApiConfigService.updateById(config);
        result.put("success", success);
        return result;
    }

    /**
     * 删除配置
     */
    @DeleteMapping("/{id}")
    public Map<String, Object> delete(@PathVariable Long id) {
        Map<String, Object> result = new HashMap<>();
        boolean success = aiApiConfigService.removeById(id);
        result.put("success", success);
        return result;
    }

    /**
     * 设置默认配置
     */
    @PostMapping("/{id}/default")
    public Map<String, Object> setDefault(@PathVariable Long id) {
        Map<String, Object> result = new HashMap<>();
        boolean success = aiApiConfigService.setDefaultConfig(id);
        result.put("success", success);
        return result;
    }

    /**
     * 测试连接
     */
    @PostMapping("/test")
    public Map<String, Object> testConnection(@RequestBody AiApiConfig config) {
        return aiApiConfigService.testConnection(config);
    }

    /**
     * 获取支持的 AI 提供商列表
     */
    @GetMapping("/providers")
    public List<Map<String, Object>> getProviders() {
        return List.of(
                Map.of("code", "openai", "name", "OpenAI", "models", List.of("gpt-4", "gpt-4-turbo", "gpt-3.5-turbo")),
                Map.of("code", "azure", "name", "Azure OpenAI", "models", List.of("gpt-4", "gpt-35-turbo")),
                Map.of("code", "anthropic", "name", "Anthropic", "models",
                        List.of("claude-3-opus", "claude-3-sonnet", "claude-3-haiku")),
                Map.of("code", "gemini", "name", "Google Gemini", "models", List.of("gemini-pro", "gemini-ultra")),
                Map.of("code", "deepseek", "name", "DeepSeek", "models", List.of("deepseek-chat", "deepseek-coder")),
                Map.of("code", "qwen", "name", "通义千问", "models", List.of("qwen-max", "qwen-plus", "qwen-turbo")),
                Map.of("code", "glm", "name", "智谱 GLM", "models", List.of("glm-4", "glm-3-turbo")),
                Map.of("code", "ernie", "name", "文心一言", "models", List.of("ernie-4.0", "ernie-3.5")),
                Map.of("code", "moonshot", "name", "Moonshot", "models", List.of("moonshot-v1-8k", "moonshot-v1-32k")),
                Map.of("code", "ark", "name", "火山方舟", "models",
                        List.of("doubao-pro-32k", "doubao-lite-32k", "doubao-pro-4k")),
                Map.of("code", "custom", "name", "自定义", "models", List.of()));
    }
}
