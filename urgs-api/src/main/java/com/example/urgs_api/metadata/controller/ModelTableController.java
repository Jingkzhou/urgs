package com.example.urgs_api.metadata.controller;

import com.example.urgs_api.metadata.dto.ModelSyncRequest;
import com.example.urgs_api.metadata.dto.ModelSyncResult;
import com.example.urgs_api.metadata.model.ModelTable;
import com.example.urgs_api.metadata.service.ModelTableService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

import com.example.urgs_api.metadata.dto.ModelTableOperationDTO;

@RestController
@RequestMapping("/api/metadata/model-table")
/**
 * 模型表控制器
 * 管理模型表（Model Table）的CRUD及导入导出
 */
public class ModelTableController {

    @Autowired
    private ModelTableService modelTableService;

    /**
     * 分页查询模型表列表
     *
     * @param directoryId 目录ID
     * @param page        页码
     * @param size        每页大小
     * @return 分页结果
     */
    @GetMapping
    public com.example.urgs_api.common.PageResult<ModelTable> list(
            @RequestParam(required = false) String directoryId,
            @RequestParam(required = false) Long dataSourceId,
            @RequestParam(required = false) String owner,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer size) {
        if (dataSourceId != null) {
            return com.example.urgs_api.common.PageResult
                    .of(modelTableService.listBySource(dataSourceId, owner, keyword, page, size));
        }
        return com.example.urgs_api.common.PageResult.of(modelTableService.listByDirectory(directoryId, page, size));
    }

    /**
     * 获取数据源下的用户/Schema列表
     *
     * @param dataSourceId 数据源ID
     * @return 用户/Schema列表
     */
    @GetMapping("/owners")
    public List<String> listOwners(@RequestParam Long dataSourceId) {
        return modelTableService.listOwners(dataSourceId);
    }

    /**
     * 同步数据源元数据到模型表/字段
     *
     * @param request 同步请求
     * @return 同步结果
     */
    @PostMapping("/sync")
    public ModelSyncResult sync(@RequestBody ModelSyncRequest request) {
        return modelTableService.syncFromDataSource(request.getDataSourceId(), request.getOwner());
    }

    /**
     * 创建模型表（包含记录）
     *
     * @param dto 模型表操作DTO
     * @return 是否成功
     */
    @PostMapping
    public boolean create(@RequestBody ModelTableOperationDTO dto) {
        return modelTableService.createWithRecord(dto);
    }

    /**
     * 更新模型表（包含记录）
     *
     * @param dto 模型表操作DTO
     * @return 是否成功
     */
    @PutMapping
    public boolean update(@RequestBody ModelTableOperationDTO dto) {
        return modelTableService.updateWithRecord(dto);
    }

    /**
     * 删除模型表
     *
     * @param id          模型表ID
     * @param reqId       需求ID
     * @param description 描述
     * @return 是否成功
     */
    @DeleteMapping("/{id}")
    public boolean delete(
            @PathVariable String id,
            @RequestParam(required = false) String reqId,
            @RequestParam(required = false) String description) {
        return modelTableService.deleteWithRecord(id, reqId, description);
    }

    /**
     * 批量删除模型表
     *
     * @param ids         模型表ID列表
     * @param reqId       需求ID
     * @param description 描述
     * @return 是否成功
     */
    @DeleteMapping("/batch")
    public boolean deleteBatch(
            @RequestBody List<String> ids,
            @RequestParam(required = false) String reqId,
            @RequestParam(required = false) String description) {
        return modelTableService.deleteBatchWithRecord(ids, reqId, description);
    }

    /**
     * 导入模型表
     *
     * @param file        Excel文件
     * @param reqId       需求ID
     * @param description 描述
     * @param operator    操作人
     * @param directoryId 目录ID
     * @return 是否成功
     */
    @PostMapping("/import")
    public boolean importModels(
            @RequestParam("file") org.springframework.web.multipart.MultipartFile file,
            @RequestParam String reqId,
            @RequestParam String description,
            @RequestParam(required = false) String operator,
            @RequestParam String directoryId) {
        return modelTableService.importModels(file, reqId, description, operator, directoryId);
    }

    /**
     * 导出模型表
     *
     * @param tableIds 表ID列表
     * @param response HTTP响应
     */
    @PostMapping("/export")
    public void exportModels(
            @RequestBody List<String> tableIds,
            jakarta.servlet.http.HttpServletResponse response) {
        modelTableService.exportModels(tableIds, response);
    }
}
