package com.example.urgs_api.marketplace.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.marketplace.mapper.MarketplacePointRuleMapper;
import com.example.urgs_api.marketplace.model.MarketplacePointRule;
import com.example.urgs_api.marketplace.service.MarketplacePointRuleService;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
public class MarketplacePointRuleServiceImpl
        extends ServiceImpl<MarketplacePointRuleMapper, MarketplacePointRule>
        implements MarketplacePointRuleService {

    @Override
    public MarketplacePointRule suggestRule(String taskType, String difficulty) {
        if (!StringUtils.hasText(taskType) || !StringUtils.hasText(difficulty)) {
            return null;
        }
        return this.lambdaQuery()
                .eq(MarketplacePointRule::getTaskType, taskType)
                .eq(MarketplacePointRule::getDifficulty, difficulty)
                .eq(MarketplacePointRule::getEnabled, true)
                .last("LIMIT 1")
                .one();
    }
}
