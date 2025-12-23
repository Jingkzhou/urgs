package com.example.urgs_api.ai.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.ai.entity.AiUsageLog;

import java.util.List;
import java.util.Map;

/**
 * AI 使用记录服务接口
 */
public interface AiUsageLogService extends IService<AiUsageLog> {

    /**
     * 记录 Token 使用
     * 
     * @param configId         配置 ID
     * @param model            模型名称
     * @param promptTokens     输入 Token
     * @param completionTokens 输出 Token
     * @param requestType      请求类型
     * @param success          是否成功
     * @param errorMessage     错误信息
     */
    void recordUsage(Long configId, String model, Integer promptTokens,
            Integer completionTokens, String requestType,
            Boolean success, String errorMessage);

    /**
     * 获取配置的使用统计
     * 
     * @param configId 配置 ID
     * @return 统计信息
     */
    Map<String, Object> getUsageStats(Long configId);

    /**
     * 获取最近的使用记录
     * 
     * @param configId 配置 ID
     * @param limit    数量限制
     * @return 使用记录列表
     */
    List<AiUsageLog> getRecentLogs(Long configId, int limit);
}
