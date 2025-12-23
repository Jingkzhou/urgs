package com.example.urgs_api.version.dto;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * Git 分支 DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GitBranch {

    /** 分支名 */
    private String name;

    /** 是否默认分支 */
    private Boolean isDefault;

    /** 是否受保护分支 */
    private Boolean isProtected;

    /** 最新提交 SHA */
    private String commitSha;

    /** 最新提交时间 */
    private String lastCommitDate;

    /** 最新提交作者 */
    private String lastCommitAuthor;

    /** 最新提交信息 */
    private String lastCommitMessage;
}
