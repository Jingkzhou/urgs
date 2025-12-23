package com.example.urgs_api.metadata.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.metadata.dto.ModelFieldOperationDTO;
import com.example.urgs_api.metadata.model.ModelField;

import java.util.List;

/**
 * 模型字段服务接口
 */
public interface ModelFieldService extends IService<ModelField> {
    /**
     * 根据表ID获取字段列表
     * 
     * @param tableId 表ID
     * @return 字段列表
     */
    List<ModelField> getFieldsByTableId(String tableId);

    /**
     * 添加模型字段
     * 
     * @param dto 字段操作DTO
     */
    void addField(ModelFieldOperationDTO dto);

    /**
     * 更新模型字段
     * 
     * @param dto 字段操作DTO
     */
    void updateField(ModelFieldOperationDTO dto);

    /**
     * 删除模型字段
     * 
     * @param fieldId 字段ID
     * @param dto     字段操作DTO
     */
    void deleteField(String fieldId, ModelFieldOperationDTO dto);
}
