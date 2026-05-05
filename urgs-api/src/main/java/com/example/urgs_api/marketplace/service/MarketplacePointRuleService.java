package com.example.urgs_api.marketplace.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.marketplace.model.MarketplacePointRule;

public interface MarketplacePointRuleService extends IService<MarketplacePointRule> {
    MarketplacePointRule suggestRule(String taskType, String difficulty);
}
