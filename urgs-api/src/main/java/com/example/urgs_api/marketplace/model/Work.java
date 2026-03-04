package com.example.urgs_api.marketplace.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("sys_work")
public class Work {
    @TableId(type = IdType.ASSIGN_ID)
    private String id;

    private String title;
    private String description;
    private String category;
    private String priority;
    private Integer totalPoints;
    private String status;
    private String publisherId;
    private LocalDateTime deadline;
    private String requirementNumber;
    private String attachments;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
