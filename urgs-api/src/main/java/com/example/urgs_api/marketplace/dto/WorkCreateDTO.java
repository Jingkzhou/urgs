package com.example.urgs_api.marketplace.dto;

import com.example.urgs_api.marketplace.model.WorkTask;
import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;

@Data
public class WorkCreateDTO {
    private String title;
    private String description;
    private String category;
    private String priority;
    private LocalDateTime deadline;
    private List<WorkTaskCreateDTO> tasks;
}
