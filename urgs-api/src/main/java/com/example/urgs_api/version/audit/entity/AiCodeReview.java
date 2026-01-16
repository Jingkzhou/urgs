package com.example.urgs_api.version.audit.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("ver_ai_code_review")
public class AiCodeReview {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long repoId;
    private String commitSha;
    private String branch;
    private String developerEmail;
    private Long developerId;
    private Integer score;
    private String summary;
    private String content; // TEXT
    private String status; // PENDING, COMPLETED, FAILED
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
