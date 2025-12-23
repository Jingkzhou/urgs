package com.example.urgs_api.im.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("im_group")
public class ImGroup {
    @TableId(type = IdType.AUTO)
    private Long id;

    private Long ownerId;

    private String name;

    private String notice;

    private String avatarUrl;

    private Integer inviteMode;

    private Integer memberCount;

    private LocalDateTime createdAt;
}
