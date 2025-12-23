package com.example.urgs_api.im.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("im_conversation")
public class ImConversation {
    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    private Long peerId;

    private Integer chatType;

    private Long lastMsgId;

    private String lastMsgContent;

    private LocalDateTime lastMsgTime;

    private Integer unreadCount;

    private Boolean isTop;

    private Boolean isHidden;

    private String name;

    private String avatar;
}
