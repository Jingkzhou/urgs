package com.example.urgs_api.online.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 在线文档实体类
 */
@Data
@TableName("online_document")
public class OnlineDocument {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 用户ID */
    private Long userId;

    /** 文档标题 */
    private String title;

    /** 文件访问地址 */
    private String fileUrl;

    /** 原始文件名 */
    private String fileName;

    /** 文件大小（字节） */
    private Long fileSize;

    /** 创建时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;

    /** 所有者名称 */
    @TableField(exist = false)
    private String ownerName;

    /** 是否由他人授权给当前用户 */
    @TableField(exist = false)
    private Boolean shared;

    /** 当前用户是否可管理授权 */
    @TableField(exist = false)
    private Boolean canManagePermissions;
}
