package com.example.urgs_api.im.vo;

import com.example.urgs_api.im.entity.ImMessage;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
public class ImMessageVO extends ImMessage {
    private String senderName;
    private String senderAvatar;
}
