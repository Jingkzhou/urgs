package com.example.urgs_api.online.dto;

import lombok.Data;

import java.util.List;

/**
 * 更新在线文档授权请求
 */
@Data
public class UpdateOnlineDocumentPermissionsRequest {

    private List<Long> userIds;
}
