package com.example.urgs_api.version.dto;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * Git 标签 DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GitTag {

    /** 标签名 */
    private String name;

    /** 标签消息 (annotated tag) */
    private String message;

    /** 指向的提交 SHA */
    private String commitSha;

    /** 提交消息 */
    private String commitMessage;

    /** 打标签的人 */
    private String taggerName;

    /** 打标签的时间 */
    private String taggerDate;
}
