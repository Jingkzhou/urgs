package com.example.urgs_api.im.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("im_friendship")
public class ImFriendship {
    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    private Long friendId;

    private String remark;

    private Integer status;

    private Integer source;

    private String tags;

    private LocalDateTime createdAt;
}
