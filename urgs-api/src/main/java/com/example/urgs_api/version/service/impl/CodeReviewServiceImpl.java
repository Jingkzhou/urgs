package com.example.urgs_api.version.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.urgs_api.user.mapper.UserMapper;
import com.example.urgs_api.user.model.User;
import com.example.urgs_api.version.entity.AICodeReview;
import com.example.urgs_api.version.repository.AICodeReviewRepository;
import com.example.urgs_api.version.service.CodeReviewService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class CodeReviewServiceImpl implements CodeReviewService {

    private final AICodeReviewRepository reviewRepository;
    private final UserMapper userMapper;

    @Override
    @Transactional
    public AICodeReview triggerReview(Long repoId, String commitSha, String branch, String developerEmail) {
        log.info("Triggering AI review for commit: {}, email: {}", commitSha, developerEmail);

        // 1. Check if review already exists
        Optional<AICodeReview> existing = reviewRepository.findByCommitSha(commitSha);
        if (existing.isPresent()) {
            return existing.get();
        }

        // 2. Map developer
        Long developerId = null;
        if (developerEmail != null && !developerEmail.isEmpty()) {
            User user = userMapper.selectOne(new QueryWrapper<User>().eq("email", developerEmail));
            if (user != null) {
                developerId = user.getId();
            } else {
                log.warn("No user found for email: {}", developerEmail);
            }
        }

        // 3. Create initial review record
        AICodeReview review = new AICodeReview();
        review.setRepoId(repoId);
        review.setCommitSha(commitSha);
        review.setBranch(branch);
        review.setDeveloperEmail(developerEmail);
        review.setDeveloperId(developerId);
        review.setStatus("PENDING");
        review.setSummary("Waiting for AI analysis...");
        reviewRepository.save(review);

        // 4. Mock AI Analysis
        // In real impl, this would be async
        mockAiAnalysis(review);

        return review;
    }

    private void mockAiAnalysis(AICodeReview review) {
        review.setScore(85);
        review.setSummary("Code structure looks good, but needs more comments.");
        review.setContent(
                "### AI Review Analysis\n\n**Score**: 85/100\n\n**Pros**:\n- Clean code style\n- Good variable naming\n\n**Cons**:\n- Missing Javadocs in some methods\n- Potential NPE in line 42");
        review.setStatus("COMPLETED");
        reviewRepository.save(review);
    }

    @Override
    public AICodeReview getReviewById(Long id) {
        return reviewRepository.findById(id).orElseThrow(() -> new RuntimeException("Review not found"));
    }

    @Override
    public List<AICodeReview> listReviews(Long repoId, Long developerId) {
        if (repoId != null) {
            return reviewRepository.findByRepoId(repoId);
        }
        if (developerId != null) {
            return reviewRepository.findByDeveloperId(developerId);
        }
        return reviewRepository.findAll();
    }

    @Override
    public Optional<AICodeReview> getReviewByCommit(String commitSha) {
        return reviewRepository.findByCommitSha(commitSha);
    }
}
