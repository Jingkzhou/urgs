package com.example.urgs_api.version.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 发布策略实体
 */
@Data
@Entity
@Table(name = "t_release_strategy")
public class ReleaseStrategy {

    public static final String TYPE_FULL = "full"; // 全量发布
    public static final String TYPE_CANARY = "canary"; // 金丝雀发布
    public static final String TYPE_GRAY = "gray"; // 灰度发布
    public static final String TYPE_BLUE_GREEN = "blue_green"; // 蓝绿部署

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 策略名称 */
    @Column(nullable = false, length = 50)
    private String name;

    /** 策略类型 */
    @Column(nullable = false, length = 20)
    private String type;

    /** 流量百分比 */
    @Column(name = "traffic_percent")
    private Integer trafficPercent = 100;

    /** 策略配置 (JSON) */
    @Column(columnDefinition = "JSON")
    private String config;

    /** 策略描述 */
    @Column(length = 200)
    private String description;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
