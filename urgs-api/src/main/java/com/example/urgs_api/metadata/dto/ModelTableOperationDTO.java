package com.example.urgs_api.metadata.dto;

import com.example.urgs_api.metadata.model.ModelTable;
import lombok.Data;

@Data
/**
 * 模型表操作传输对象
 * 用于接收前端传递的模型表增删改操作参数
 */
public class ModelTableOperationDTO {
    /**
     * 模型表信息
     */
    private ModelTable table;
    /**
     * 需求ID
     */
    private String reqId;
    /**
     * 描述/备注
     */
    private String description;
    /**
     * 计划日期
     */
    private String plannedDate;
    /**
     * 脚本内容
     */
    private String script;
    /**
     * 操作人
     */
    private String operator;

    // Manual Getters and Setters
    public ModelTable getTable() {
        return table;
    }

    public void setTable(ModelTable table) {
        this.table = table;
    }

    public String getReqId() {
        return reqId;
    }

    public void setReqId(String reqId) {
        this.reqId = reqId;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getPlannedDate() {
        return plannedDate;
    }

    public void setPlannedDate(String plannedDate) {
        this.plannedDate = plannedDate;
    }

    public String getScript() {
        return script;
    }

    public void setScript(String script) {
        this.script = script;
    }

    public String getOperator() {
        return operator;
    }

    public void setOperator(String operator) {
        this.operator = operator;
    }
}
