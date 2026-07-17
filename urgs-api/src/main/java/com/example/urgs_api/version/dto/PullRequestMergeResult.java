package com.example.urgs_api.version.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class PullRequestMergeResult {
    /** 是否请求删除源分支 */
    private boolean sourceBranchDeleteRequested;

    /** 源分支是否已删除或已由平台接收删除请求 */
    private boolean sourceBranchDeleted;

    /** 源分支未删除时的原因 */
    private String sourceBranchDeleteMessage;
}
