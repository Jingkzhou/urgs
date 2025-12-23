package com.example.urgs_api.im.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("im_user")
public class ImUser {
    @TableId(type = IdType.INPUT)
    private Long userId;

    private String wxId;

    private String avatarUrl;

    private String region;

    private String signature;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}
