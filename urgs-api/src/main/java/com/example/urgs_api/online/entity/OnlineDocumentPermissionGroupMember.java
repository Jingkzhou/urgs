package com.example.urgs_api.online.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 在线文档常用授权组成员
 */
@Data
@TableName("online_document_permission_group_member")
public class OnlineDocumentPermissionGroupMember {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 授权组ID */
    private Long groupId;

    /** 组成员用户ID */
    private Long userId;

    /** 创建时间 */
    private LocalDateTime createTime;
}
