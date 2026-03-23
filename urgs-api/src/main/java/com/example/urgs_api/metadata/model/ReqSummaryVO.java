package com.example.urgs_api.metadata.model;

import lombok.Data;

/**
 * 需求变更汇总 VO
 * 按需求编号分组的变更统计
 */
@Data
public class ReqSummaryVO {

    /** 需求编号 */
    private String reqId;

    /** 需求名称 */
    private String reqName;

    /** 执行人（操作人） */
    private String operator;

    /** 上线日期（计划日期） */
    private String plannedDate;

    /** 变更数量 */
    private Integer changeCount;
}
