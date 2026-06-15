package com.example.urgs_api.online.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 设置在线文档空间类型请求
 */
@Data
public class SetOnlineDocumentSpaceTypeRequest {

    @NotBlank(message = "空间类型不能为空")
    private String spaceType;
}
