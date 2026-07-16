package com.example.urgs_api.version.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Git 文件下载内容
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GitFileDownload {

    /** 原始文件名 */
    private String name;

    /** 原始字节内容 */
    private byte[] content;
}
