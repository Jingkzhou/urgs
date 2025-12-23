package com.example.urgs_api.announcement.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("sys_announcement_read")
public class AnnouncementRead {
    @TableId(type = IdType.ASSIGN_ID)
    private String id;
    private String announcementId;
    private String userId;
    private LocalDateTime readTime;
}
