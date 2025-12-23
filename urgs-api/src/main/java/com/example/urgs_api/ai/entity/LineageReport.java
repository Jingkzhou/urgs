package com.example.urgs_api.ai.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 血缘分析报告实体
 */
@Data
@TableName("lineage_report")
public class LineageReport {

    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * 表名
     */
    private String tableName;

    /**
     * 字段名
     */
    private String columnName;

    /**
     * 报告内容 (Markdown)
     */
    private String reportContent;

    /**
     * 上游节点数
     */
    private Integer upstreamCount;

    /**
     * 下游节点数
     */
    private Integer downstreamCount;

    /**
     * 使用的 AI 模型
     */
    private String aiModel;

    /**
     * 状态: generating/completed/failed
     */
    private String status;

    /**
     * 创建人
     */
    private String createBy;

    /**
     * 创建时间
     */
    private LocalDateTime createTime;
}
