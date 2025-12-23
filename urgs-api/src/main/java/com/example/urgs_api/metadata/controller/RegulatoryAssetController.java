package com.example.urgs_api.metadata.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.urgs_api.metadata.model.RegulatoryAsset;
import com.example.urgs_api.metadata.service.RegulatoryAssetService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/metadata/asset")
/**
 * 监管资产控制器
 * 处理监管资产相关的HTTP请求
 */
public class RegulatoryAssetController {

    @Autowired
    private RegulatoryAssetService assetService;

    /**
     * 查询监管资产列表
     *
     * @param keyword    搜索关键词（匹配名称或代码）
     * @param systemCode 系统代码
     * @param parentId   父节点ID
     * @param type       资产类型
     * @return 监管资产列表
     */
    @GetMapping("/list")
    public List<RegulatoryAsset> list(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String systemCode,
            @RequestParam(required = false) Long parentId,
            @RequestParam(required = false) String type) {

        QueryWrapper<RegulatoryAsset> query = new QueryWrapper<>();

        // 精确匹配条件 (AND)
        query.eq(systemCode != null && !systemCode.isEmpty(), "system_code", systemCode);
        query.eq(parentId != null, "parent_id", parentId);
        query.eq(type != null && !type.isEmpty(), "type", type);

        // 关键词搜索 (分组 OR)
        if (keyword != null && !keyword.isEmpty()) {
            query.and(wrapper -> wrapper.like("name", keyword).or().like("code", keyword));
        }

        query.orderByDesc("create_time");
        return assetService.list(query);
    }

    /**
     * 新增监管资产
     *
     * @param asset 监管资产对象
     * @return 是否成功
     */
    @PostMapping("/add")
    public boolean add(@RequestBody RegulatoryAsset asset) {
        asset.setCreateTime(LocalDateTime.now());
        asset.setUpdateTime(LocalDateTime.now());
        if (asset.getStatus() == null) {
            asset.setStatus(1);
        }
        return assetService.save(asset);
    }

    /**
     * 更新监管资产
     *
     * @param asset 监管资产对象
     * @return 是否成功
     */
    @PostMapping("/update")
    public boolean update(@RequestBody RegulatoryAsset asset) {
        asset.setUpdateTime(LocalDateTime.now());
        return assetService.updateById(asset);
    }

    /**
     * 删除监管资产
     *
     * @param id 资产ID
     * @return 是否成功
     */
    @PostMapping("/delete/{id}")
    public boolean delete(@PathVariable Long id) {
        return assetService.removeById(id);
    }
}
