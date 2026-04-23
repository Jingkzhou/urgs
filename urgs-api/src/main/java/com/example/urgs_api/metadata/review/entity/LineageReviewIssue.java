package com.example.urgs_api.metadata.review.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Data
@TableName(value = "t_lineage_review_issue", autoResultMap = true)
public class LineageReviewIssue {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long taskId;
    private String analysisRecordId;
    private Long repoId;
    private String versionId;
    private String systemKey;
    private String pathPrefix;
    private String tableName;
    private String columnName;
    private String objectType;
    private String issueType;
    private String severity;
    private BigDecimal confidence;
    private String verdict;
    private String reason;

    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<String> ruleHits;

    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<String> suggestedSources;

    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<String> evidenceRefs;

    @TableField(typeHandler = JacksonTypeHandler.class)
    private Map<String, Object> graphSnapshot;

    private String fingerprint;
    private String cacheKey;
    private String reviewStatus;
    private Long reviewerId;
    private String reviewerNote;
    private LocalDateTime reviewTime;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
