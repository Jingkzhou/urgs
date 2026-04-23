package com.example.urgs_api.metadata.review.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("t_lineage_review_task")
public class LineageReviewTask {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String analysisRecordId;
    private Long repoId;
    private String versionId;
    private String ref;
    private String systemKey;
    private String pathPrefix;
    private String taskName;
    private String status;
    private Integer objectCount;
    private Integer processedCount;
    private Integer issueCount;
    private Integer failedCount;
    private Integer aiCallCount;
    private Integer cacheHitCount;
    private Integer batchCount;
    private Integer tokenBudget;
    private Integer consumedTokens;
    private String lastError;
    private LocalDateTime startedAt;
    private LocalDateTime finishedAt;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
