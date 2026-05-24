package com.example.urgs_api.metadata.review.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
@TableName(value = "t_lineage_review_memory", autoResultMap = true)
public class LineageReviewMemory {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String title;
    private String status;
    private String content;
    private String targetPattern;
    private String issueType;

    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<String> ruleHits;

    private Long sourceIssueId;
    private Long sourceTaskId;
    private String analysisRecordId;
    private Long repoId;
    private String versionId;
    private String systemKey;
    private String pathPrefix;
    private Long createdBy;
    private Long updatedBy;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
