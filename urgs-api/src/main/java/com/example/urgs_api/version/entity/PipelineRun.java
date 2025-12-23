package com.example.urgs_api.version.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 流水线执行记录实体
 */
@Data
@Entity
@Table(name = "t_pipeline_run")
public class PipelineRun {

    public static final String STATUS_PENDING = "pending";
    public static final String STATUS_RUNNING = "running";
    public static final String STATUS_SUCCESS = "success";
    public static final String STATUS_FAILED = "failed";
    public static final String STATUS_CANCELLED = "cancelled";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 关联流水线 */
    @Column(name = "pipeline_id", nullable = false)
    private Long pipelineId;

    /** 执行编号 */
    @Column(name = "run_number", nullable = false)
    private Integer runNumber;

    /** 触发方式：manual, webhook, schedule */
    @Column(name = "trigger_type", length = 20)
    private String triggerType;

    /** 分支 */
    @Column(length = 100)
    private String branch;

    /** 提交 ID */
    @Column(name = "commit_id", length = 50)
    private String commitId;

    /** 执行状态 */
    @Column(length = 20)
    private String status = STATUS_PENDING;

    /** 开始时间 */
    @Column(name = "started_at")
    private LocalDateTime startedAt;

    /** 结束时间 */
    @Column(name = "finished_at")
    private LocalDateTime finishedAt;

    /** 执行日志 */
    @Column(columnDefinition = "TEXT")
    private String logs;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
