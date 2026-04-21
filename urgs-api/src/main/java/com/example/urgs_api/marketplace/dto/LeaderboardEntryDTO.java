package com.example.urgs_api.marketplace.dto;

import lombok.Data;

@Data
public class LeaderboardEntryDTO {
    private String userId;
    private String userName;
    private String avatarUrl;
    private String orgName;
    private int completedTasks;
    private int inProgressTasks;
    private int totalPoints;
    private double completionRate;
}
