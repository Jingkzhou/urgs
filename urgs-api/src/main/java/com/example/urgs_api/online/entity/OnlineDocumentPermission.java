package com.example.urgs_api.online.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 在线文档授权
 */
@Data
@TableName("online_document_permission")
public class OnlineDocumentPermission {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 文档ID */
    private Long documentId;

    /** 被授权用户ID */
    private Long userId;

    /** 授权人ID */
    private Long createBy;

    /** 授权时间 */
    private LocalDateTime createTime;
}
