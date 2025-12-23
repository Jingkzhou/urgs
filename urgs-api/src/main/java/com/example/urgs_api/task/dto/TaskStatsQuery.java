package com.example.urgs_api.task.dto;

import lombok.Data;
import java.util.List;
import java.time.LocalDateTime;

@Data
public class TaskStatsQuery {
    private List<String> systemIds;
    private List<String> subjectIds;
    private List<String> taskStatuses;
    private LocalDateTime startTimeBegin;
    private LocalDateTime startTimeEnd;
    private LocalDateTime updateTimeBegin;
    private LocalDateTime updateTimeEnd;
    private Boolean onlyLatest;
}
