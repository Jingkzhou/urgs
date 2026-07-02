package com.example.urgs_api.marketplace.dto;

import com.example.urgs_api.marketplace.model.WorkTask;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class TaskMarketDTO extends WorkTask {
    private String workTitle;
    private String workDescription;
    private String workPriority;
    private Integer workTotalPoints;
    private String workStatus;
    private String workPublisherId;
    private LocalDateTime workDeadline;
    private String requirementNumber;
    private String applicationDepartment;
    private String applicantName;
    private String owningSystem;
    private Boolean primarySystem;
    private String primarySystemName;
    private String projectType;
    private String attachments;
    private LocalDateTime workCreateTime;
    private LocalDateTime workUpdateTime;
    private String publisherName;
    private String publisherAvatar;
    private Integer applicationCount;
}
