package com.example.urgs_api.online.dto;

import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 更新在线文档请求
 */
@Data
public class UpdateOnlineDocumentRequest {

    @Size(max = 200, message = "文档标题不能超过200个字符")
    private String title;

    @Size(max = 255, message = "文件名不能超过255个字符")
    private String fileName;
}
