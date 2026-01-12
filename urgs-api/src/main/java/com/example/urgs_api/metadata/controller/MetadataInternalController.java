package com.example.urgs_api.metadata.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.metadata.model.ModelField;
import com.example.urgs_api.metadata.model.ModelTable;
import com.example.urgs_api.metadata.service.ModelFieldService;
import com.example.urgs_api.metadata.service.ModelTableService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/internal/metadata")
/**
 * 内部元数据查询控制器
 * 专门供血缘解析引擎等内部组件调用
 */
public class MetadataInternalController {

    @Autowired
    private ModelTableService modelTableService;

    @Autowired
    private ModelFieldService modelFieldService;

    /**
     * 根据表全名获取表及字段信息
     *
     * @param fullName 表名，支持 "OWNER.TABLE" 或 "TABLE" 格式
     * @return 包含表信息和字段列表的 Map
     */
    @GetMapping("/table-fields")
    public Map<String, Object> getTableFields(@RequestParam String fullName) {
        String owner = null;
        String tableName;

        if (fullName.contains(".")) {
            // 处理 SCHEMA.TABLE 格式
            int lastDotIndex = fullName.lastIndexOf(".");
            owner = fullName.substring(0, lastDotIndex);
            tableName = fullName.substring(lastDotIndex + 1);
        } else {
            tableName = fullName;
        }

        // 统一转大写查询，匹配数据库习惯
        LambdaQueryWrapper<ModelTable> tableWrapper = new LambdaQueryWrapper<ModelTable>()
                .eq(ModelTable::getName, tableName.toUpperCase());

        if (owner != null && !owner.isEmpty()) {
            tableWrapper.eq(ModelTable::getOwner, owner.toUpperCase());
        }

        ModelTable table = modelTableService.getOne(tableWrapper);

        Map<String, Object> result = new HashMap<>();
        if (table == null) {
            // 如果带 Owner 没找到，尝试只按表名找（可能元数据中 Owner 记录不全）
            if (owner != null) {
                table = modelTableService.getOne(new LambdaQueryWrapper<ModelTable>()
                        .eq(ModelTable::getName, tableName.toUpperCase()));
            }

            if (table == null) {
                result.put("success", false);
                result.put("message", "Table not found: " + fullName);
                return result;
            }
        }

        List<ModelField> fields = modelFieldService.getFieldsByTableId(table.getId());

        result.put("success", true);
        result.put("table", table);
        result.put("fields", fields);
        return result;
    }
}
