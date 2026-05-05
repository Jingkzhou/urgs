package com.example.urgs_api.marketplace.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("sys_marketplace_point_rule")
public class MarketplacePointRule {
    @TableId(type = IdType.ASSIGN_ID)
    private String id;

    private String taskType;
    private String difficulty;
    private Integer suggestedPoints;
    private String description;
    private Boolean enabled;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
