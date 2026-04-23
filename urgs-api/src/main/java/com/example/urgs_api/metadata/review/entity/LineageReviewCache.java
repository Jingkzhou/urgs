package com.example.urgs_api.metadata.review.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;

@Data
@TableName(value = "t_lineage_review_cache", autoResultMap = true)
public class LineageReviewCache {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String cacheKey;
    private String fingerprint;
    private String aiModel;
    private BigDecimal confidence;
    private String verdict;

    @TableField(typeHandler = JacksonTypeHandler.class)
    private Map<String, Object> resultJson;

    private Integer hitCount;
    private LocalDateTime lastHitAt;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
