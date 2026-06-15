package com.example.urgs_api.online.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 创建在线文档请求
 */
@Data
public class CreateOnlineDocumentRequest {

    @NotBlank(message = "文档标题不能为空")
    @Size(max = 200, message = "文档标题不能超过200个字符")
    private String title;

    @NotBlank(message = "文件地址不能为空")
    @Size(max = 500, message = "文件地址不能超过500个字符")
    private String fileUrl;

    @Size(max = 255, message = "文件名不能超过255个字符")
    private String fileName;

    private Long fileSize;
}
