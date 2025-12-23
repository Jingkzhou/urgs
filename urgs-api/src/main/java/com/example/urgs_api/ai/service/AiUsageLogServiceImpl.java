package com.example.urgs_api.ai.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.ai.entity.AiApiConfig;
import com.example.urgs_api.ai.entity.AiUsageLog;
import com.example.urgs_api.ai.repository.AiUsageLogMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * AI 使用记录服务实现
 */
@Service
public class AiUsageLogServiceImpl extends ServiceImpl<AiUsageLogMapper, AiUsageLog>
        implements AiUsageLogService {

    @Autowired
    private AiApiConfigService aiApiConfigService;

    @Override
    @Transactional
    public void recordUsage(Long configId, String model, Integer promptTokens,
            Integer completionTokens, String requestType,
            Boolean success, String errorMessage) {
        // 创建使用记录
        AiUsageLog log = new AiUsageLog();
        log.setConfigId(configId);
        log.setModel(model);
        log.setPromptTokens(promptTokens != null ? promptTokens : 0);
        log.setCompletionTokens(completionTokens != null ? completionTokens : 0);
        log.setTotalTokens((promptTokens != null ? promptTokens : 0) +
                (completionTokens != null ? completionTokens : 0));
        log.setRequestType(requestType);
        log.setSuccess(success);
        log.setErrorMessage(errorMessage);
        log.setCreateTime(LocalDateTime.now());
        save(log);

        // 更新配置的累计统计
        if (configId != null && success != null && success) {
            AiApiConfig config = aiApiConfigService.getById(configId);
            if (config != null) {
                Long totalTokens = config.getTotalTokens() != null ? config.getTotalTokens() : 0L;
                Integer totalRequests = config.getTotalRequests() != null ? config.getTotalRequests() : 0;

                aiApiConfigService.update(new LambdaUpdateWrapper<AiApiConfig>()
                        .eq(AiApiConfig::getId, configId)
                        .set(AiApiConfig::getTotalTokens, totalTokens + log.getTotalTokens())
                        .set(AiApiConfig::getTotalRequests, totalRequests + 1));
            }
        }
    }

    @Override
    public Map<String, Object> getUsageStats(Long configId) {
        Map<String, Object> stats = new HashMap<>();

        // 查询总计
        LambdaQueryWrapper<AiUsageLog> query = new LambdaQueryWrapper<>();
        if (configId != null) {
            query.eq(AiUsageLog::getConfigId, configId);
        }

        List<AiUsageLog> logs = list(query);

        long totalTokens = 0;
        long totalPromptTokens = 0;
        long totalCompletionTokens = 0;
        int successCount = 0;
        int failCount = 0;

        for (AiUsageLog log : logs) {
            totalTokens += log.getTotalTokens() != null ? log.getTotalTokens() : 0;
            totalPromptTokens += log.getPromptTokens() != null ? log.getPromptTokens() : 0;
            totalCompletionTokens += log.getCompletionTokens() != null ? log.getCompletionTokens() : 0;
            if (Boolean.TRUE.equals(log.getSuccess())) {
                successCount++;
            } else {
                failCount++;
            }
        }

        stats.put("totalTokens", totalTokens);
        stats.put("totalPromptTokens", totalPromptTokens);
        stats.put("totalCompletionTokens", totalCompletionTokens);
        stats.put("totalRequests", logs.size());
        stats.put("successCount", successCount);
        stats.put("failCount", failCount);

        return stats;
    }

    @Override
    public List<AiUsageLog> getRecentLogs(Long configId, int limit) {
        LambdaQueryWrapper<AiUsageLog> query = new LambdaQueryWrapper<>();
        if (configId != null) {
            query.eq(AiUsageLog::getConfigId, configId);
        }
        query.orderByDesc(AiUsageLog::getCreateTime);
        query.last("LIMIT " + limit);
        return list(query);
    }
}
