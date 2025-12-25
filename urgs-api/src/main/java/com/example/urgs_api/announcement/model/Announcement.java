package com.example.urgs_api.announcement.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("sys_announcement")
public class Announcement {
    @TableId(type = IdType.ASSIGN_ID)
    private String id;

    @TableField(exist = false)
    private boolean hasRead;

    @TableField(exist = false)
    private int readCount;

    private String title;
    private String type;
    private String category;
    private String content;

    // Stored as JSON string
    private String attachments;

    // Stored as JSON string
    private String systems;

    private Integer status; // 1: Published, 0: Draft

    private LocalDateTime createTime;
    private LocalDateTime updateTime;
    private String createBy;
}
