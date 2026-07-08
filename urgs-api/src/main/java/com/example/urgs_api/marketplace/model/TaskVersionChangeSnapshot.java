package com.example.urgs_api.marketplace.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("sys_task_version_change_snapshot")
public class TaskVersionChangeSnapshot {
    @TableId(type = IdType.AUTO)
    private Long id;

    @TableField("task_id")
    private String taskId;

    @TableField("work_id")
    private String workId;

    @TableField("requirement_number")
    private String requirementNumber;

    @TableField("assignee_id")
    private String assigneeId;

    @TableField("reviewer_id")
    private String reviewerId;

    @TableField("repo_id")
    private Long repoId;

    @TableField("repo_name")
    private String repoName;

    @TableField("pr_number")
    private Long prNumber;

    @TableField("pr_title")
    private String prTitle;

    @TableField("pr_url")
    private String prUrl;

    @TableField("source_branch")
    private String sourceBranch;

    @TableField("target_branch")
    private String targetBranch;

    private String state;

    private Boolean merged;

    @TableField("merged_at")
    private String mergedAt;

    @TableField("match_source")
    private String matchSource;

    @TableField("commit_count")
    private Integer commitCount;

    @TableField("file_count")
    private Integer fileCount;

    private Integer additions;

    private Integer deletions;

    @TableField("snapshot_json")
    private String snapshotJson;

    @TableField("created_at")
    private LocalDateTime createdAt;

    @TableField("updated_at")
    private LocalDateTime updatedAt;
}
