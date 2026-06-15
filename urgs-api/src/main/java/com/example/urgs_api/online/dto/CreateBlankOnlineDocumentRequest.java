package com.example.urgs_api.online.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 创建空白在线文档请求
 */
@Data
public class CreateBlankOnlineDocumentRequest {

    @Size(max = 200, message = "文档标题不能超过200个字符")
    private String title;

    @NotBlank(message = "文档类型不能为空")
    private String documentType;
}
