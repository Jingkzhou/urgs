package com.example.urgs_api.version.dto;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * Git 文件内容 DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GitFileContent {

    /** 文件名 */
    private String name;

    /** 文件路径 */
    private String path;

    /** 文件大小 (bytes) */
    private Long size;

    /** 文件内容 (Base64 解码后) */
    private String content;

    /** 编码类型 */
    private String encoding;

    /** SHA */
    private String sha;

    /** 文件类型 (用于语法高亮) */
    private String language;
}
