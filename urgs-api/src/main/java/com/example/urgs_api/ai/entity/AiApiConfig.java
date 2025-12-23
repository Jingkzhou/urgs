package com.example.urgs_api.ai.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * AI API 配置实体
 * 用于存储各种 AI 服务的 API 配置信息
 */
@Data
@TableName("sys_ai_api")
public class AiApiConfig {
    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * 配置名称
     */
    private String name;

    /**
     * AI 服务提供商 (openai, azure, anthropic, gemini, deepseek, qwen, glm 等)
     */
    private String provider;

    /**
     * 模型名称 (gpt-4, claude-3, gemini-pro 等)
     */
    private String model;

    /**
     * API 端点 URL
     */
    private String endpoint;

    /**
     * API 密钥
     */
    private String apiKey;

    /**
     * 备用密钥（可选）
     */
    private String apiKeyBackup;

    /**
     * 最大 Token 数
     */
    private Integer maxTokens;

    /**
     * 温度参数 (0.0 - 2.0)
     */
    private Double temperature;

    /**
     * 是否为默认配置
     */
    private Integer isDefault;

    /**
     * 状态 (1: 启用, 0: 禁用)
     */
    private Integer status;

    /**
     * 备注
     */
    private String remark;

    /**
     * 创建时间
     */
    private LocalDateTime createTime;

    /**
     * 更新时间
     */
    private LocalDateTime updateTime;

    /**
     * 累计消耗 Token
     */
    private Long totalTokens;

    /**
     * 累计请求次数
     */
    private Integer totalRequests;
}
