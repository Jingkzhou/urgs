package com.example.urgs_api.version.dto;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * Git 文件条目 DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GitFileEntry {

    /** 文件/目录名 */
    private String name;

    /** 完整路径 */
    private String path;

    /** 类型: file, dir */
    private String type;

    /** 文件大小 (仅文件有效) */
    private Long size;

    /** 文件 SHA */
    private String sha;

    /** 最后提交信息 (可选) */
    private String lastCommitMessage;

    /** 最后提交时间 (可选) */
    private String lastCommitDate;
}
