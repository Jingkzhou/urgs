package com.example.urgs_api.announcement.dto;

import lombok.Data;
import java.util.List;

@Data
public class AnnouncementQuery {
    private String keyword;
    private String type; // 'all' or specific type
    private String category; // 'Announcement' or 'Log'
    private String userId; // current user ID
    private List<String> userSystems; // current user's systems

    // Pagination (optional, handled by Page object usually, but can be here too)
}
