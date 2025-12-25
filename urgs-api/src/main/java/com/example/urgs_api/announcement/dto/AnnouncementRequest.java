package com.example.urgs_api.announcement.dto;

import lombok.Data;
import java.util.List;

@Data
public class AnnouncementRequest {
    private String id;
    private String title;
    private String type;
    private String category;
    private String content;
    private List<AttachmentDTO> attachments;
    private List<String> systems;

    @Data
    public static class AttachmentDTO {
        private String name;
        private String url;
    }
}
