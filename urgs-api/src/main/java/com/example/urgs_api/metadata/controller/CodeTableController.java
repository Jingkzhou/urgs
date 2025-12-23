package com.example.urgs_api.metadata.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.urgs_api.metadata.model.CodeTable;
import com.example.urgs_api.metadata.service.CodeTableService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/metadata/code-tables")
/**
 * 码表控制器
 * 管理码表定义（Code Table）
 */
public class CodeTableController {

    @Autowired
    private CodeTableService codeTableService;

    /**
     * 获取所有码表列表
     *
     * @return 码表列表
     */
    @GetMapping
    public List<CodeTable> list() {
        QueryWrapper<CodeTable> wrapper = new QueryWrapper<>();
        wrapper.orderByAsc("table_code");
        return codeTableService.list(wrapper);
    }

    /**
     * 新增码表
     *
     * @param codeTable 码表对象
     * @return 是否成功
     */
    @PostMapping
    public boolean save(@RequestBody CodeTable codeTable) {
        // 检查码表编号是否重复
        QueryWrapper<CodeTable> query = new QueryWrapper<>();
        query.eq("table_code", codeTable.getTableCode());
        if (codeTable.getId() != null) {
            query.ne("id", codeTable.getId());
        }
        // 用户需求："同系统...编号不能重复"。
        // 这里的逻辑通常是全局唯一，或者按系统唯一。
        // 目前实现保持全局 table_code 唯一。

        if (codeTableService.count(query) > 0) {
            throw new RuntimeException("码表编号已存在");
        }

        if (codeTable.getId() == null) {
            codeTable.setCreateTime(LocalDateTime.now());
        }
        codeTable.setUpdateTime(LocalDateTime.now());
        return codeTableService.saveOrUpdate(codeTable);
    }

    /**
     * 更新码表
     *
     * @param codeTable 码表对象
     * @return 是否成功
     */
    @PutMapping
    public boolean update(@RequestBody CodeTable codeTable) {
        // 检查码表编号是否重复
        QueryWrapper<CodeTable> query = new QueryWrapper<>();
        query.eq("table_code", codeTable.getTableCode());
        if (codeTable.getId() != null) {
            query.ne("id", codeTable.getId());
        }
        if (codeTableService.count(query) > 0) {
            throw new RuntimeException("码表编号已存在");
        }

        codeTable.setUpdateTime(LocalDateTime.now());
        return codeTableService.saveOrUpdate(codeTable);
    }

    /**
     * 删除码表
     *
     * @param id 码表ID
     * @return 是否成功
     */
    @DeleteMapping("/{id}")
    public boolean delete(@PathVariable String id) {
        return codeTableService.removeById(id);
    }
}
