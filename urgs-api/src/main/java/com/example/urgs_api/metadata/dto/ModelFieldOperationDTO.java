package com.example.urgs_api.metadata.dto;

import com.example.urgs_api.metadata.model.ModelField;

/**
 * 模型字段操作传输对象
 * 用于接收前端传递的字段增删改操作参数
 */
public class ModelFieldOperationDTO {
    /**
     * 字段信息
     */
    private ModelField field;
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

    public ModelField getField() {
        return field;
    }

    public void setField(ModelField field) {
        this.field = field;
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
