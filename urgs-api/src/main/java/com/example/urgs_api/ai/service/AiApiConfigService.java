package com.example.urgs_api.ai.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.ai.entity.AiApiConfig;

import java.util.List;

/**
 * AI API 配置服务接口
 */
public interface AiApiConfigService extends IService<AiApiConfig> {

    /**
     * 获取所有配置列表
     */
    List<AiApiConfig> getAllConfigs();

    /**
     * 获取默认配置
     */
    AiApiConfig getDefaultConfig();

    /**
     * 设置默认配置
     */
    boolean setDefaultConfig(Long id);

    /**
     * 测试 API 连接
     */
    java.util.Map<String, Object> testConnection(AiApiConfig config);
}
