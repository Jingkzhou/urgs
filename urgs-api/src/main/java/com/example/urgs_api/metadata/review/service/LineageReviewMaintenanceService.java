package com.example.urgs_api.metadata.review.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.metadata.review.entity.LineageReviewCache;
import com.example.urgs_api.metadata.review.entity.LineageReviewIssue;
import com.example.urgs_api.metadata.review.entity.LineageReviewTask;
import com.example.urgs_api.metadata.review.mapper.LineageReviewCacheMapper;
import com.example.urgs_api.metadata.review.mapper.LineageReviewIssueMapper;
import com.example.urgs_api.metadata.review.mapper.LineageReviewTaskMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.Map;

@Service
public class LineageReviewMaintenanceService {

    private final LineageReviewTaskMapper taskMapper;
    private final LineageReviewIssueMapper issueMapper;
    private final LineageReviewCacheMapper cacheMapper;

    public LineageReviewMaintenanceService(
            LineageReviewTaskMapper taskMapper,
            LineageReviewIssueMapper issueMapper,
            LineageReviewCacheMapper cacheMapper) {
        this.taskMapper = taskMapper;
        this.issueMapper = issueMapper;
        this.cacheMapper = cacheMapper;
    }

    @Transactional
    public Map<String, Object> clearHistory() {
        Long issueCount = issueMapper.selectCount(new LambdaQueryWrapper<LineageReviewIssue>()
                .isNotNull(LineageReviewIssue::getId));
        Long taskCount = taskMapper.selectCount(new LambdaQueryWrapper<LineageReviewTask>()
                .isNotNull(LineageReviewTask::getId));
        Long cacheCount = cacheMapper.selectCount(new LambdaQueryWrapper<LineageReviewCache>()
                .isNotNull(LineageReviewCache::getId));

        issueMapper.delete(new LambdaQueryWrapper<LineageReviewIssue>()
                .isNotNull(LineageReviewIssue::getId));
        taskMapper.delete(new LambdaQueryWrapper<LineageReviewTask>()
                .isNotNull(LineageReviewTask::getId));
        cacheMapper.delete(new LambdaQueryWrapper<LineageReviewCache>()
                .isNotNull(LineageReviewCache::getId));

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("success", true);
        result.put("taskCount", taskCount);
        result.put("issueCount", issueCount);
        result.put("cacheCount", cacheCount);
        result.put("message", "已清空历史校验结果");
        return result;
    }
}
