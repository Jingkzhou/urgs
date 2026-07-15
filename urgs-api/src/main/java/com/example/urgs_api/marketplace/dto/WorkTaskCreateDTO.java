package com.example.urgs_api.marketplace.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class WorkTaskCreateDTO {
    private String id;
    private String title;
    private String description;
    private String taskType;
    private String difficulty;
    private java.util.List<Long> involvedSystemIds;
    private String requiredSkills;
    private String acceptanceCriteria;
    private Integer points;
    private Integer estimatedHours;
    private String assignMode; // OPEN/COMPETE/ASSIGN
    private String assigneeId; // If ASSIGN mode
    private Integer maxApplicants; // If COMPETE mode
    private LocalDateTime deadline;
    private String taskRole; // MAIN/SUB
    private String parentTaskId;
    private String currentStage; // TEST_SUBMISSION_COMPLETED/QUALITY_ACCEPTANCE_COMPLETED/ASSET_REVIEW/LAUNCH
}
