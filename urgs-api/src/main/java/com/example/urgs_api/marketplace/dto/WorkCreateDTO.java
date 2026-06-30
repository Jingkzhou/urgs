package com.example.urgs_api.marketplace.dto;

import com.example.urgs_api.marketplace.model.WorkTask;
import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;

@Data
public class WorkCreateDTO {
    private String title;
    private String description;
    private String background;
    private String businessValue;
    private String category;
    private String priority;
    private LocalDateTime deadline;
    private String requirementNumber;
    private String applicationDepartment;
    private String applicantName;
    private String owningSystem;
    private Boolean primarySystem;
    private String primarySystemName;
    private String projectType;
    private WorkTaskCreateDTO mainTask;
    private List<AttachmentDTO> attachments;
    private List<WorkTaskCreateDTO> tasks;

    @Data
    public static class AttachmentDTO {
        private String name;
        private String url;
    }
}
