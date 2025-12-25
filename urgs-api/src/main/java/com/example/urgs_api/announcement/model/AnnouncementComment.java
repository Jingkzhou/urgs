package com.example.urgs_api.announcement.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("sys_announcement_comment")
public class AnnouncementComment {
    @TableId(type = IdType.ASSIGN_ID)
    private String id;
    private String announcementId;
    private String userId;
    private String content;
    private String parentId; // For nested replies
    private LocalDateTime createTime;

    @com.baomidou.mybatisplus.annotation.TableField(exist = false)
    private String userName;

    @com.baomidou.mybatisplus.annotation.TableField(exist = false)
    private String userAvatar;
    @com.baomidou.mybatisplus.annotation.TableField(exist = false)
    private java.util.List<String> mentionedUserIds;
}
