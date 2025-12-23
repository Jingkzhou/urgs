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
    public boolean testConnection(AiApiConfig config) {
        // 验证配置完整性
        if (config.getEndpoint() == null || config.getEndpoint().isEmpty()) {
            return false;
        }
        if (config.getApiKey() == null || config.getApiKey().isEmpty()) {
            return false;
        }

        try {
            // 构建端点 URL
            String endpoint = config.getEndpoint();
            if (!endpoint.endsWith("/")) {
                endpoint += "/";
            }
            endpoint += "chat/completions";

            // 构建请求体 - 发送一个最简单的测试请求
            String requestBody = String.format("""
                    {
                        "model": "%s",
                        "messages": [{"role": "user", "content": "Hi"}],
                        "max_tokens": 5
                    }
                    """, config.getModel() != null ? config.getModel() : "gpt-3.5-turbo");

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

            // 200 表示成功，其他状态码表示失败
            if (responseCode == 200) {
                return true;
            } else {
                // 读取错误信息用于日志
                try (java.io.InputStream errorStream = conn.getErrorStream()) {
                    if (errorStream != null) {
                        String errorBody = new String(errorStream.readAllBytes(),
                                java.nio.charset.StandardCharsets.UTF_8);
                        System.err.println("AI API test failed: " + responseCode + " - " + errorBody);
                    }
                }
                return false;
            }
        } catch (Exception e) {
            System.err.println("AI API test connection error: " + e.getMessage());
            return false;
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
