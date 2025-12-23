package com.example.urgs_api.version.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 应用系统实体
 */
@Data
@Entity
@Table(name = "t_app_system")
public class AppSystem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 应用名称 */
    @Column(nullable = false, length = 100)
    private String name;

    /** 应用编码 */
    @Column(nullable = false, unique = true, length = 50)
    private String code;

    /** 应用描述 */
    @Column(length = 500)
    private String description;

    /** 负责人ID */
    private Long ownerId;

    /** 开发团队 */
    @Column(length = 100)
    private String team;

    /** 状态 */
    @Column(length = 20)
    private String status = "active";

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
