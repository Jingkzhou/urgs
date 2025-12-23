package com.example.urgs_api.version.dto;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;

import java.util.List;
import lombok.AllArgsConstructor;

/**
 * Git 提交信息 DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GitCommit {

    /** 提交 SHA (短) */
    private String sha;

    /** 完整 SHA */
    private String fullSha;

    /** 提交信息 */
    private String message;

    /** 作者名 */
    private String authorName;

    /** 作者邮箱 */
    private String authorEmail;

    /** 作者头像 */
    private String authorAvatar;

    /** 提交时间 */
    private String committedAt;

    /** 总提交数 (用于统计) */
    private Long totalCommits;

    /** 提交差异列表 */ // Added Javadoc for the new field
    private List<GitCommitDiff> diffs;
}
