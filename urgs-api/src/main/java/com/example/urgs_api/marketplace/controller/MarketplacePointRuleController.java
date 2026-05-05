package com.example.urgs_api.marketplace.controller;

import com.example.urgs_api.marketplace.model.MarketplacePointRule;
import com.example.urgs_api.marketplace.service.MarketplacePointRuleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/marketplace/point-rules")
public class MarketplacePointRuleController {

    @Autowired
    private MarketplacePointRuleService pointRuleService;

    @GetMapping
    public List<MarketplacePointRule> listRules(
            @RequestParam(required = false) String taskType,
            @RequestParam(required = false) String difficulty,
            @RequestParam(required = false) Boolean enabled) {
        return pointRuleService.lambdaQuery()
                .eq(StringUtils.hasText(taskType), MarketplacePointRule::getTaskType, taskType)
                .eq(StringUtils.hasText(difficulty), MarketplacePointRule::getDifficulty, difficulty)
                .eq(enabled != null, MarketplacePointRule::getEnabled, enabled)
                .orderByAsc(MarketplacePointRule::getTaskType)
                .orderByAsc(MarketplacePointRule::getDifficulty)
                .list();
    }

    @GetMapping("/suggest")
    public MarketplacePointRule suggestRule(
            @RequestParam String taskType,
            @RequestParam String difficulty) {
        return pointRuleService.suggestRule(taskType, difficulty);
    }

    @PostMapping
    public MarketplacePointRule createRule(@RequestBody MarketplacePointRule rule) {
        if (rule.getEnabled() == null) {
            rule.setEnabled(true);
        }
        pointRuleService.save(rule);
        return rule;
    }

    @PutMapping("/{id}")
    public MarketplacePointRule updateRule(
            @PathVariable String id,
            @RequestBody MarketplacePointRule rule) {
        rule.setId(id);
        pointRuleService.updateById(rule);
        return pointRuleService.getById(id);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteRule(@PathVariable String id) {
        pointRuleService.removeById(id);
        return ResponseEntity.ok().build();
    }
}
