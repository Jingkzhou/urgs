package com.example.urgs_api.metadata.review.service;

import com.example.urgs_api.metadata.review.dto.LineageReviewDecisionRequest;
import com.example.urgs_api.metadata.review.dto.LineageReviewMemoryRequest;
import com.example.urgs_api.metadata.review.entity.LineageReviewIssue;
import com.example.urgs_api.metadata.review.entity.LineageReviewMemory;

import java.util.List;

public interface LineageReviewMemoryService {

    List<LineageReviewMemory> listMemories(String status);

    LineageReviewMemory getMemory(Long memoryId);

    LineageReviewMemory updateMemory(Long memoryId, Long userId, LineageReviewMemoryRequest request);

    LineageReviewMemory captureFalsePositive(LineageReviewIssue issue, Long userId,
            LineageReviewDecisionRequest request);
}
