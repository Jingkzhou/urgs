package com.example.urgs_api.metadata.review.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.example.urgs_api.metadata.review.dto.LineageReviewDecisionRequest;
import com.example.urgs_api.metadata.review.dto.LineageReviewMemoryRequest;
import com.example.urgs_api.metadata.review.entity.LineageReviewCache;
import com.example.urgs_api.metadata.review.entity.LineageReviewIssue;
import com.example.urgs_api.metadata.review.entity.LineageReviewMemory;
import com.example.urgs_api.metadata.review.mapper.LineageReviewCacheMapper;
import com.example.urgs_api.metadata.review.mapper.LineageReviewIssueMapper;
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
    private static final String STATUS_ARCHIVED = "ARCHIVED";
    private static final String SUMMARY_TARGET_PATTERN = "GLOBAL_FALSE_POSITIVE_SUMMARY";
    private static final String SUMMARY_ISSUE_TYPE = "FALSE_POSITIVE_SUMMARY";
    private static final int FALSE_POSITIVE_SAMPLE_LIMIT = 200;

    private final LineageReviewMemoryMapper memoryMapper;
    private final LineageReviewIssueMapper issueMapper;
    private final LineageReviewCacheMapper cacheMapper;
    private final LineageReviewAiService aiService;

    public LineageReviewMemoryServiceImpl(LineageReviewMemoryMapper memoryMapper,
            LineageReviewIssueMapper issueMapper,
            LineageReviewCacheMapper cacheMapper,
            LineageReviewAiService aiService) {
        this.memoryMapper = memoryMapper;
        this.issueMapper = issueMapper;
        this.cacheMapper = cacheMapper;
        this.aiService = aiService;
    }

    @Override
    public List<LineageReviewMemory> listMemories(String status) {
        LambdaQueryWrapper<LineageReviewMemory> query = new LambdaQueryWrapper<>();
        String targetStatus = StringUtils.hasText(status) ? status : STATUS_ACTIVE;
        query.eq(LineageReviewMemory::getStatus, targetStatus);
        if (STATUS_ACTIVE.equalsIgnoreCase(targetStatus)) {
            query.isNull(LineageReviewMemory::getSourceIssueId);
        }
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

        archiveIssueLevelMemories();
        LineageReviewMemory memory = findSummaryMemory();
        LocalDateTime now = LocalDateTime.now();
        if (memory == null) {
            memory = new LineageReviewMemory();
            memory.setTitle("误报复盘汇总");
            memory.setTargetPattern(SUMMARY_TARGET_PATTERN);
            memory.setIssueType(SUMMARY_ISSUE_TYPE);
            memory.setCreateTime(now);
            memory.setCreatedBy(userId);
        }
        memory.setStatus(STATUS_ACTIVE);
        memory.setContent(aiService.summarizeFalsePositiveMemories(loadFalsePositiveIssues()));
        memory.setRuleHits(null);
        memory.setSourceIssueId(null);
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

    private void archiveIssueLevelMemories() {
        LineageReviewMemory memory = new LineageReviewMemory();
        memory.setStatus(STATUS_ARCHIVED);
        memoryMapper.update(memory, new LambdaUpdateWrapper<LineageReviewMemory>()
                .eq(LineageReviewMemory::getStatus, STATUS_ACTIVE)
                .isNotNull(LineageReviewMemory::getSourceIssueId));
    }

    private LineageReviewMemory findSummaryMemory() {
        LambdaQueryWrapper<LineageReviewMemory> query = new LambdaQueryWrapper<>();
        query.eq(LineageReviewMemory::getTargetPattern, SUMMARY_TARGET_PATTERN)
                .eq(LineageReviewMemory::getIssueType, SUMMARY_ISSUE_TYPE)
                .last("LIMIT 1");
        return memoryMapper.selectOne(query);
    }

    private List<LineageReviewIssue> loadFalsePositiveIssues() {
        LambdaQueryWrapper<LineageReviewIssue> query = new LambdaQueryWrapper<>();
        query.eq(LineageReviewIssue::getReviewStatus, "FALSE_POSITIVE")
                .orderByDesc(LineageReviewIssue::getReviewTime)
                .orderByDesc(LineageReviewIssue::getUpdateTime)
                .last("LIMIT " + FALSE_POSITIVE_SAMPLE_LIMIT);
        return issueMapper.selectList(query);
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

}
