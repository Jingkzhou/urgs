package com.example.urgs_api.metadata.review.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.metadata.review.dto.LineageReviewDecisionRequest;
import com.example.urgs_api.metadata.review.dto.LineageReviewMemoryRequest;
import com.example.urgs_api.metadata.review.entity.LineageReviewCache;
import com.example.urgs_api.metadata.review.entity.LineageReviewIssue;
import com.example.urgs_api.metadata.review.entity.LineageReviewMemory;
import com.example.urgs_api.metadata.review.mapper.LineageReviewCacheMapper;
import com.example.urgs_api.metadata.review.mapper.LineageReviewMemoryMapper;
import com.example.urgs_api.metadata.review.service.LineageReviewAiService;
import com.example.urgs_api.metadata.review.service.LineageReviewMemoryService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class LineageReviewMemoryServiceImpl implements LineageReviewMemoryService {

    private static final String STATUS_ACTIVE = "ACTIVE";

    private final LineageReviewMemoryMapper memoryMapper;
    private final LineageReviewCacheMapper cacheMapper;
    private final LineageReviewAiService aiService;

    public LineageReviewMemoryServiceImpl(LineageReviewMemoryMapper memoryMapper,
            LineageReviewCacheMapper cacheMapper,
            LineageReviewAiService aiService) {
        this.memoryMapper = memoryMapper;
        this.cacheMapper = cacheMapper;
        this.aiService = aiService;
    }

    @Override
    public List<LineageReviewMemory> listMemories(String status) {
        LambdaQueryWrapper<LineageReviewMemory> query = new LambdaQueryWrapper<>();
        query.eq(StringUtils.hasText(status), LineageReviewMemory::getStatus, status);
        query.orderByDesc(LineageReviewMemory::getUpdateTime)
                .orderByDesc(LineageReviewMemory::getCreateTime);
        return memoryMapper.selectList(query);
    }

    @Override
    public LineageReviewMemory getMemory(Long memoryId) {
        return memoryMapper.selectById(memoryId);
    }

    @Override
    @Transactional
    public LineageReviewMemory updateMemory(Long memoryId, Long userId, LineageReviewMemoryRequest request) {
        LineageReviewMemory memory = memoryMapper.selectById(memoryId);
        if (memory == null) {
            throw new IllegalArgumentException("走查记忆不存在");
        }
        if (StringUtils.hasText(request.getTitle())) {
            memory.setTitle(request.getTitle().trim());
        }
        if (StringUtils.hasText(request.getContent())) {
            memory.setContent(request.getContent().trim());
        }
        if (StringUtils.hasText(request.getStatus())) {
            memory.setStatus(request.getStatus().trim());
        }
        memory.setUpdatedBy(userId);
        memory.setUpdateTime(LocalDateTime.now());
        memoryMapper.updateById(memory);
        clearAiReviewCache();
        return memory;
    }

    @Override
    @Transactional
    public LineageReviewMemory captureFalsePositive(LineageReviewIssue issue, Long userId,
            LineageReviewDecisionRequest request) {
        if (issue == null || !"FALSE_POSITIVE".equalsIgnoreCase(issue.getReviewStatus())) {
            return null;
        }
        String falsePositiveReason = resolveFalsePositiveReason(request);
        if (!StringUtils.hasText(falsePositiveReason)) {
            throw new IllegalArgumentException("标记误报时必须填写误报原因");
        }

        LineageReviewMemory memory = findBySourceIssue(issue.getId());
        LocalDateTime now = LocalDateTime.now();
        if (memory == null) {
            memory = new LineageReviewMemory();
            memory.setSourceIssueId(issue.getId());
            memory.setCreateTime(now);
            memory.setCreatedBy(userId);
        }
        memory.setTitle(buildTitle(issue));
        memory.setStatus(STATUS_ACTIVE);
        memory.setContent(aiService.summarizeFalsePositiveMemory(issue, falsePositiveReason));
        memory.setTargetPattern(buildTargetPattern(issue));
        memory.setIssueType(issue.getIssueType());
        memory.setRuleHits(issue.getRuleHits());
        memory.setSourceTaskId(issue.getTaskId());
        memory.setAnalysisRecordId(issue.getAnalysisRecordId());
        memory.setRepoId(issue.getRepoId());
        memory.setVersionId(issue.getVersionId());
        memory.setSystemKey(issue.getSystemKey());
        memory.setPathPrefix(issue.getPathPrefix());
        memory.setUpdatedBy(userId);
        memory.setUpdateTime(now);
        if (memory.getId() == null) {
            memoryMapper.insert(memory);
        } else {
            memoryMapper.updateById(memory);
        }
        clearAiReviewCache();
        return memory;
    }

    private void clearAiReviewCache() {
        cacheMapper.delete(new LambdaQueryWrapper<LineageReviewCache>()
                .isNotNull(LineageReviewCache::getId));
    }

    private LineageReviewMemory findBySourceIssue(Long sourceIssueId) {
        if (sourceIssueId == null) {
            return null;
        }
        LambdaQueryWrapper<LineageReviewMemory> query = new LambdaQueryWrapper<>();
        query.eq(LineageReviewMemory::getSourceIssueId, sourceIssueId).last("LIMIT 1");
        return memoryMapper.selectOne(query);
    }

    private String resolveFalsePositiveReason(LineageReviewDecisionRequest request) {
        if (request == null) {
            return null;
        }
        if (StringUtils.hasText(request.getFalsePositiveReason())) {
            return request.getFalsePositiveReason().trim();
        }
        return StringUtils.hasText(request.getReviewerNote()) ? request.getReviewerNote().trim() : null;
    }

    private String buildTitle(LineageReviewIssue issue) {
        return "误报复盘：" + issue.getIssueType() + " / " + buildTargetPattern(issue);
    }

    private String buildTargetPattern(LineageReviewIssue issue) {
        String tableName = StringUtils.hasText(issue.getTableName()) ? issue.getTableName() : "UNKNOWN_TABLE";
        if (!StringUtils.hasText(issue.getColumnName())) {
            return tableName;
        }
        return tableName + "." + issue.getColumnName();
    }
}
