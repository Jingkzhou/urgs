package com.example.urgs_api.metadata.controller;

import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/internal/metadata")
/**
 * 内部元数据查询控制器
 * 专门供血缘解析引擎等内部组件调用
 */
public class MetadataInternalController {

    /**
     * 根据表全名获取表及字段信息
     *
     * @param fullName 表名，支持 "OWNER.TABLE" 或 "TABLE" 格式
     * @return 包含表信息和字段列表的 Map
     */
    @GetMapping("/table-fields")
    public Map<String, Object> getTableFields(@RequestParam String fullName) {
        Map<String, Object> result = new HashMap<>();
        // 临时禁用内部元数据查询，避免血缘引擎高频回调拖垮主系统。
        result.put("success", false);
        result.put("message", "Metadata lookup temporarily disabled: " + fullName);
        return result;
    }
}
