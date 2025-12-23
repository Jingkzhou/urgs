package com.example.urgs_api.metadata.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.metadata.model.MaintenanceRecord;
import com.example.urgs_api.metadata.service.MaintenanceRecordService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/metadata/maintenance-record")
/**
 * 维护记录控制器
 * 提供维护记录的查询功能
 */
public class MaintenanceRecordController {

    @Autowired
    private MaintenanceRecordService maintenanceRecordService;

    /**
     * 分页查询维护记录
     *
     * @param tableName   表名
     * @param tableCnName 表中文名
     * @param fieldName   字段名
     * @param fieldCnName 字段中文名
     * @param plannedDate 计划日期
     * @param reqId       需求ID
     * @param page        页码
     * @param size        每页大小
     * @return 维护记录分页结果
     */
    @GetMapping
    public com.baomidou.mybatisplus.core.metadata.IPage<MaintenanceRecord> list(
            @RequestParam(required = false) String tableName,
            @RequestParam(required = false) String tableCnName,
            @RequestParam(required = false) String fieldName,
            @RequestParam(required = false) String fieldCnName,
            @RequestParam(required = false) String plannedDate,
            @RequestParam(required = false) String reqId,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer size) {
        LambdaQueryWrapper<MaintenanceRecord> query = new LambdaQueryWrapper<>();
        if (StringUtils.hasText(tableName)) {
            query.like(MaintenanceRecord::getTableName, tableName);
        }
        if (StringUtils.hasText(tableCnName)) {
            query.like(MaintenanceRecord::getTableCnName, tableCnName);
        }
        if (StringUtils.hasText(fieldName)) {
            query.like(MaintenanceRecord::getFieldName, fieldName);
        }
        if (StringUtils.hasText(fieldCnName)) {
            query.like(MaintenanceRecord::getFieldCnName, fieldCnName);
        }
        if (StringUtils.hasText(plannedDate)) {
            query.eq(MaintenanceRecord::getPlannedDate, plannedDate);
        }
        if (StringUtils.hasText(reqId)) {
            query.like(MaintenanceRecord::getReqId, reqId);
        }
        query.orderByDesc(MaintenanceRecord::getTime);
        return maintenanceRecordService
                .page(new com.baomidou.mybatisplus.extension.plugins.pagination.Page<>(page, size), query);
    }
}
