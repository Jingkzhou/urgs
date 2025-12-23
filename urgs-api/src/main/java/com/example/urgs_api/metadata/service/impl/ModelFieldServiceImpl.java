package com.example.urgs_api.metadata.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.metadata.dto.ModelFieldOperationDTO;
import com.example.urgs_api.metadata.mapper.ModelFieldMapper;
import com.example.urgs_api.metadata.model.MaintenanceRecord;
import com.example.urgs_api.metadata.model.ModelField;
import com.example.urgs_api.metadata.model.ModelTable;
import com.example.urgs_api.metadata.service.MaintenanceRecordService;
import com.example.urgs_api.metadata.service.ModelFieldService;
import com.example.urgs_api.metadata.service.ModelTableService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
/**
 * 模型字段服务实现类
 */
public class ModelFieldServiceImpl extends ServiceImpl<ModelFieldMapper, ModelField> implements ModelFieldService {

    @Autowired
    private MaintenanceRecordService maintenanceRecordService;

    @Autowired
    @org.springframework.context.annotation.Lazy
    private ModelTableService modelTableService;

    @Override
    /**
     * 根据表ID获取字段列表
     */
    public List<ModelField> getFieldsByTableId(String tableId) {
        return list(new LambdaQueryWrapper<ModelField>()
                .eq(ModelField::getTableId, tableId)
                .orderByAsc(ModelField::getSortOrder));
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    /**
     * 添加字段
     */
    public void addField(ModelFieldOperationDTO dto) {
        ModelField field = dto.getField();
        save(field);
        recordMaintenance(field, "新增字段", dto);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    /**
     * 更新字段
     */
    public void updateField(ModelFieldOperationDTO dto) {
        ModelField field = dto.getField();
        updateById(field);
        recordMaintenance(field, "修改字段", dto);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    /**
     * 删除字段
     */
    public void deleteField(String fieldId, ModelFieldOperationDTO dto) {
        ModelField field = getById(fieldId);
        if (field != null) {
            removeById(fieldId);
            // For deletion, we might not have the full field object in DTO, so we use the
            // fetched one
            // But we need the maintenance info from DTO
            recordMaintenance(field, "删除字段", dto);
        }
    }

    private void recordMaintenance(ModelField field, String type, ModelFieldOperationDTO dto) {
        MaintenanceRecord record = new MaintenanceRecord();
        ModelTable table = modelTableService.getById(field.getTableId());

        if (table != null) {
            record.setTableName(table.getName());
            record.setTableCnName(table.getCnName());
        }

        record.setModType(type);
        record.setFieldName(field.getName());
        record.setFieldCnName(field.getCnName());
        record.setTime(LocalDateTime.now());
        record.setOperator(dto.getOperator());
        record.setReqId(dto.getReqId());
        record.setDescription(dto.getDescription());

        if (dto.getPlannedDate() != null && !dto.getPlannedDate().isEmpty()) {
            try {
                record.setPlannedDate(java.time.LocalDate.parse(dto.getPlannedDate()));
            } catch (Exception e) {
                // Ignore parse error
            }
        }
        record.setScript(dto.getScript());

        maintenanceRecordService.save(record);
    }
}
