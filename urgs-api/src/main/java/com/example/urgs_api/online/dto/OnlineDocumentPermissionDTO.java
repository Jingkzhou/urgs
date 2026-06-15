package com.example.urgs_api.online.dto;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 在线文档授权用户
 */
@Data
public class OnlineDocumentPermissionDTO {
    private Long userId;
    private String userName;
    private String empId;
    private LocalDateTime createTime;
}
