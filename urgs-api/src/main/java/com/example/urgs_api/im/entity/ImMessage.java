package com.example.urgs_api.im.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("im_message")
public class ImMessage {
    @TableId(type = IdType.AUTO)
    private Long id;

    private String conversationId;

    private Long senderId;

    private Long receiverId;

    private Long groupId;

    private Integer msgType;

    private String content;

    private Long referMsgId;

    private LocalDateTime sendTime;
}
