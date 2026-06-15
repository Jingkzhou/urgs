package com.example.urgs_api.online.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 在线文档常用授权组
 */
@Data
@TableName("online_document_permission_group")
public class OnlineDocumentPermissionGroup {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 组所有者用户ID */
    private Long ownerUserId;

    /** 组名称 */
    private String name;

    /** 组描述 */
    private String description;

    /** 创建时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;
}
