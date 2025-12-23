package com.example.urgs_api.metadata.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 监管指标资产
 */
@Data
@TableName("metadata_regulatory_asset")
public class RegulatoryAsset {

    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * 父级资产ID (如指标所属的报表ID)
     */
    @TableField("parent_id")
    private Long parentId;

    /**
     * 资产名称
     */
    private String name;

    /**
     * 资产代码/标识
     */
    private String code;

    /**
     * 所属系统代码 (关联 sys_sso_config.system_code)
     */
    @TableField("system_code")
    private String systemCode;

    /**
     * 资产类型 (如: 报表, 指标)
     */
    private String type;

    /**
     * 描述
     */
    private String description;

    /**
     * 责任人
     */
    private String owner;

    /**
     * 状态 (1: 启用, 0: 停用)
     */
    private Integer status;

    @TableField("create_time")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createTime;

    @TableField("update_time")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime updateTime;
}
