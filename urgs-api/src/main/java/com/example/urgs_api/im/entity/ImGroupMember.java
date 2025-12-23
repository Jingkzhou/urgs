package com.example.urgs_api.im.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("im_group_member")
public class ImGroupMember {
    @TableId(type = IdType.AUTO)
    private Long id;

    private Long groupId;

    private Long userId;

    private Integer role;

    private String alias;

    private Boolean isMuted;

    private Boolean isTop;

    private LocalDateTime joinTime;
}
