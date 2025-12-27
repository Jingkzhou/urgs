package com.example.urgs_api.version.audit.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.version.audit.entity.AiCodeReview;

public interface AiCodeReviewService extends IService<AiCodeReview> {

    /**
     * Trigger an AI Code Review for a specific commit.
     * This method should ideally be async.
     */
    void triggerReview(Long repoId, String commitSha, String branch, String developerEmail);

    /**
     * Get review by commit SHA.
     */
    AiCodeReview getByCommit(String commitSha);
}
