package com.example.urgs_api.version.repository;

import com.example.urgs_api.version.entity.AICodeReview;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AICodeReviewRepository extends JpaRepository<AICodeReview, Long> {
    List<AICodeReview> findByRepoId(Long repoId);

    List<AICodeReview> findByDeveloperId(Long developerId);

    Optional<AICodeReview> findByCommitSha(String commitSha);
}
