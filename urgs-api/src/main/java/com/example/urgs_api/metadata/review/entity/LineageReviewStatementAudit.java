package com.example.urgs_api.metadata.review.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Data
@TableName(value = "lineage_review_statement_audit", autoResultMap = true)
public class LineageReviewStatementAudit {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long taskId;
    private String statementUid;
    private String statementHash;
    private String contextGroupId;

    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<String> sourceFilesJson;

    private Integer riskScore;

    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<String> riskReasonsJson;

    private Boolean isHighRisk;
    private String auditStatus;
    private String screeningBatchKey;
    private Boolean isScreeningCandidate;
    private Integer aiCallCount;
    private Integer issueCount;
    private String skipReason;
    private String evidenceHash;

    @TableField(typeHandler = JacksonTypeHandler.class)
    private Map<String, Object> resultJson;

    private LocalDateTime startedTime;
    private LocalDateTime finishedTime;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
