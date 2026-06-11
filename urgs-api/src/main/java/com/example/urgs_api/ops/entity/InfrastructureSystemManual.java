package com.example.urgs_api.ops.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 系统运维手册附件记录。
 */
@Data
@Entity
@Table(name = "t_infrastructure_system_manual")
public class InfrastructureSystemManual {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 关联应用系统ID */
    @Column(name = "app_system_id", nullable = false)
    private Long appSystemId;

    /** 手册标题 */
    @Column(nullable = false, length = 200)
    private String title;

    /** 原始文件名 */
    @Column(name = "file_name", nullable = false, length = 255)
    private String fileName;

    /** 文件访问地址 */
    @Column(name = "file_url", nullable = false, length = 500)
    private String fileUrl;

    /** 文件大小（字节） */
    @Column(name = "file_size")
    private Long fileSize;

    /** 备注说明 */
    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
