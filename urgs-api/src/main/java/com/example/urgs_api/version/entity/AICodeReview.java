package com.example.urgs_api.version.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.util.Date;

@Data
@Entity
@Table(name = "ver_ai_code_review")
public class AICodeReview {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Associated Repository ID
     */
    @Column(name = "repo_id")
    private Long repoId;

    /**
     * Commit SHA being reviewed
     */
    @Column(name = "commit_sha")
    private String commitSha;

    /**
     * Branch name
     */
    private String branch;

    /**
     * Developer's email (from Git commit)
     */
    @Column(name = "developer_email")
    private String developerEmail;

    /**
     * Developer's User ID (mapped from email)
     */
    @Column(name = "developer_id")
    private Long developerId;

    /**
     * General score given by AI (0-100)
     */
    private Integer score;

    /**
     * Summary of the review
     */
    @Column(length = 2000)
    private String summary;

    /**
     * Full AI analysis/feedback in JSON or Markdown format
     */
    @Column(columnDefinition = "TEXT")
    private String content;

    /**
     * Status of the review: PENDING, COMPLETED, FAILED
     */
    private String status;

    @Column(name = "created_at")
    private Date createdAt;

    @Column(name = "updated_at")
    private Date updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = new Date();
        updatedAt = new Date();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = new Date();
    }
}
