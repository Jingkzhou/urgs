package com.example.urgs_api.metadata.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
@TableName(value = "t_lineage_analysis_record", autoResultMap = true)
/**
 * 血缘分析记录实体
 */
public class LineageAnalysisRecord {

    @TableId(type = IdType.ASSIGN_ID)
    private String id;

    /**
     * Git 仓库 ID
     */
    private Long repoId;

    /**
     * Git 引用 (分支/标签/SHA)
     */
    private String ref;

    /**
     * 提交 SHA
     */
    private String commitSha;

    /**
     * 分析路径列表 (存储为 JSON)
     */
    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<String> paths;

    /**
     * Python 引擎生成的版本 ID
     */
    private String versionId;

    /**
     * 启动参数：默认用户
     */
    private String defaultUser;

    /**
     * 启动参数：SQL 方言
     */
    private String language;

    /**
     * 状态: PENDING, RUNNING, SUCCESS, FAILED
     */
    private String status;

    /**
     * 错误信息
     */
    private String error;

    private LocalDateTime startTime;

    private LocalDateTime endTime;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;
}
