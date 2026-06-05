package com.example.urgs_api.metadata.dto;

import lombok.Data;

@Data
public class PhysicalFieldBindingDTO {
    private String modelFieldId;
    private String modelTableId;
    private Long dataSourceId;
    private String owner;
    private String tableName;
    private String tableCnName;
    private String fieldName;
    private String fieldCnName;
    private String fieldType;
}
