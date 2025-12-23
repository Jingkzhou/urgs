package com.example.urgs_api.metadata.controller;

import com.example.urgs_api.metadata.dto.ModelFieldOperationDTO;
import com.example.urgs_api.metadata.model.ModelField;
import com.example.urgs_api.metadata.service.ModelFieldService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/metadata/model-field")
/**
 * 模型字段控制器
 * 管理模型表的字段信息
 */
public class ModelFieldController {

    @Autowired
    private ModelFieldService modelFieldService;

    /**
     * 获取指定表的字段列表
     *
     * @param tableId 表ID
     * @return 字段列表
     */
    @GetMapping
    public List<ModelField> list(@RequestParam String tableId) {
        return modelFieldService.getFieldsByTableId(tableId);
    }

    /**
     * 添加字段
     *
     * @param dto 字段操作DTO
     */
    @PostMapping
    public void add(@RequestBody ModelFieldOperationDTO dto) {
        modelFieldService.addField(dto);
    }

    /**
     * 更新字段
     *
     * @param dto 字段操作DTO
     */
    @PutMapping
    public void update(@RequestBody ModelFieldOperationDTO dto) {
        modelFieldService.updateField(dto);
    }

    /**
     * 删除字段
     *
     * @param id  字段ID
     * @param dto 字段操作DTO（可能包含删除原因等）
     */
    @DeleteMapping("/{id}")
    public void delete(@PathVariable String id, @RequestBody ModelFieldOperationDTO dto) {
        modelFieldService.deleteField(id, dto);
    }
}
