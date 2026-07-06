package com.example.urgs_api.marketplace.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
@TableName(value = "sys_work_task", autoResultMap = true)
public class WorkTask {
    @TableId(type = IdType.ASSIGN_ID)
    private String id;

    private String workId;
    private String taskRole;
    private String parentTaskId;
    private String currentStage;
    private Boolean stageRiskReported;
    private String stageRiskNote;
    private LocalDateTime stageUpdatedAt;
    private String title;
    private String description;
    private String taskType;
    private String difficulty;
    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<Long> involvedSystemIds;
    private String requiredSkills;
    private String acceptanceCriteria;
    private Integer points;
    private Integer estimatedHours;
    private String assignMode;
    private String status;
    private String assigneeId;
    private Integer maxApplicants;
    private LocalDateTime deadline;
    private String completionDescription;
    private String deliverables;
    private Integer actualHours;
    private String impactScope;
    private Boolean delayReported;
    private String delayReason;
    private Integer qualityScore;
    private String reviewComment;
    private String assetMaintenanceSnapshot;
    private String reviewerId;
    private LocalDateTime submittedAt;
    private LocalDateTime reviewedAt;
    private Integer reworkCount;
    private Integer bonusPoints;
    private Integer penaltyPoints;
    private Integer finalPoints;
    private String kpiPeriod;
    private Integer sortOrder;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
