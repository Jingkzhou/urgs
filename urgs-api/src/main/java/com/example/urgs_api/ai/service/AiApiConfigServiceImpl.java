package com.example.urgs_api.ai.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.ai.entity.AiApiConfig;
import com.example.urgs_api.ai.repository.AiApiConfigMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * AI API 配置服务实现
 */
@Service
public class AiApiConfigServiceImpl extends ServiceImpl<AiApiConfigMapper, AiApiConfig> implements AiApiConfigService {

    @Override
    public List<AiApiConfig> getAllConfigs() {
        return list(new LambdaQueryWrapper<AiApiConfig>()
                .orderByDesc(AiApiConfig::getIsDefault)
                .orderByDesc(AiApiConfig::getCreateTime));
    }

    @Override
    public AiApiConfig getDefaultConfig() {
        return getOne(new LambdaQueryWrapper<AiApiConfig>()
                .eq(AiApiConfig::getIsDefault, 1)
                .eq(AiApiConfig::getStatus, 1)
                .last("LIMIT 1"));
    }

    @Override
    @Transactional
    public boolean setDefaultConfig(Long id) {
        // 先将所有配置的 isDefault 设为 0
        update(new LambdaUpdateWrapper<AiApiConfig>()
                .set(AiApiConfig::getIsDefault, 0));

        // 再将指定配置设为默认
        return update(new LambdaUpdateWrapper<AiApiConfig>()
                .eq(AiApiConfig::getId, id)
                .set(AiApiConfig::getIsDefault, 1));
    }

    @Override
    public java.util.Map<String, Object> testConnection(AiApiConfig config) {
        java.util.Map<String, Object> result = new java.util.HashMap<>();

        // 验证配置完整性
        if (config.getEndpoint() == null || config.getEndpoint().isEmpty()) {
            result.put("success", false);
            result.put("message", "API 端点不能为空");
            return result;
        }
        if (config.getApiKey() == null || config.getApiKey().isEmpty()) {
            result.put("success", false);
            result.put("message", "API 密钥不能为空");
            return result;
        }

        try {
            // 构建端点 URL
            String endpoint = config.getEndpoint();
            if (!endpoint.endsWith("/")) {
                endpoint += "/";
            }
            endpoint += "chat/completions";

            // 构建请求体
            String model = config.getModel();
            if (model == null || model.isEmpty()) {
                // 如果未提供模型，对于 Ollama/vLLM 等私有部署，通常需要一个具体的模型名称
                // 默认使用 gpt-3.5-turbo 仅适用于 OpenAI
                model = "gpt-3.5-turbo";
            }

            String requestBody = String.format("""
                    {
                        "model": "%s",
                        "messages": [{"role": "user", "content": "Hi"}],
                        "max_tokens": 5
                    }
                    """, model);

            // 创建 HTTP 连接
            java.net.URL url = java.net.URI.create(endpoint).toURL();
            java.net.HttpURLConnection conn = (java.net.HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setRequestProperty("Authorization", "Bearer " + config.getApiKey());
            conn.setDoOutput(true);
            conn.setConnectTimeout(10000);
            conn.setReadTimeout(30000);

            // 发送请求
            try (java.io.OutputStream os = conn.getOutputStream()) {
                os.write(requestBody.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            }

            int responseCode = conn.getResponseCode();

            if (responseCode == 200) {
                result.put("success", true);
                result.put("message", "连接成功");
                return result;
            } else {
                // 读取错误信息
                String errorBody = "";
                try (java.io.InputStream errorStream = conn.getErrorStream()) {
                    if (errorStream != null) {
                        errorBody = new String(errorStream.readAllBytes(), java.nio.charset.StandardCharsets.UTF_8);
                    }
                }

                String message = "连接失败 (HTTP " + responseCode + ")";
                if (responseCode == 404) {
                    message = "模型名称未找到。请确认模型名称是否正确。如果您使用的是私有服务器，请在“模型”字段输入正确的 ID (如 qwen3)。";
                } else if (responseCode == 401) {
                    message = "认证失败，请检查 API 密钥。";
                } else if (!errorBody.isEmpty()) {
                    // 尝试提取 JSON 中的错误信息
                    if (errorBody.contains("\"message\"")) {
                        message += ": " + errorBody;
                    }
                }

                System.err.println("AI API test failed: " + responseCode + " - " + errorBody);
                result.put("success", false);
                result.put("message", message);
                result.put("details", errorBody);
                return result;
            }
        } catch (Exception e) {
            System.err.println("AI API test connection error: " + e.getMessage());
            result.put("success", false);
            result.put("message", "网络连接错误: " + e.getMessage());
            return result;
        }
    }

    @Override
    public boolean save(AiApiConfig entity) {
        entity.setCreateTime(LocalDateTime.now());
        entity.setUpdateTime(LocalDateTime.now());
        if (entity.getStatus() == null) {
            entity.setStatus(1);
        }
        if (entity.getIsDefault() == null) {
            entity.setIsDefault(0);
        }
        return super.save(entity);
    }

    @Override
    public boolean updateById(AiApiConfig entity) {
        entity.setUpdateTime(LocalDateTime.now());
        return super.updateById(entity);
    }
}
