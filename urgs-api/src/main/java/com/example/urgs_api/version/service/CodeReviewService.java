package com.example.urgs_api.version.service;

import com.example.urgs_api.version.entity.AICodeReview;
import java.util.List;
import java.util.Optional;

public interface CodeReviewService {
    AICodeReview triggerReview(Long repoId, String commitSha, String branch, String developerEmail);

    AICodeReview getReviewById(Long id);

    List<AICodeReview> listReviews(Long repoId, Long developerId);

    Optional<AICodeReview> getReviewByCommit(String commitSha);
}
