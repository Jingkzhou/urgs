package com.example.urgs_api.metadata.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.metadata.model.ModelTable;

import com.example.urgs_api.metadata.dto.ModelTableOperationDTO;
import java.util.List;

/**
 * 模型表服务接口
 */
public interface ModelTableService extends IService<ModelTable> {
    /**
     * 根据目录分页查询模型表
     * 
     * @param directoryId 目录ID
     * @param page        页码
     * @param size        每页大小
     * @return 分页结果
     */
    com.baomidou.mybatisplus.core.metadata.IPage<ModelTable> listByDirectory(String directoryId, int page, int size);

    /**
     * 根据数据源分页查询模型表
     *
     * @param dataSourceId 数据源ID
     * @param owner        用户/Schema
     * @param keyword      关键字
     * @param page         页码
     * @param size         每页大小
     * @return 分页结果
     */
    com.baomidou.mybatisplus.core.metadata.IPage<ModelTable> listBySource(Long dataSourceId, String owner,
            String keyword, int page, int size);

    /**
     * 查询数据源下的用户/Schema列表
     *
     * @param dataSourceId 数据源ID
     * @return 用户列表
     */
    List<String> listOwners(Long dataSourceId);

    /**
     * 同步数据源元数据到模型表/字段
     *
     * @param dataSourceId 数据源ID
     * @param owner        用户/Schema（可选）
     * @return 同步结果
     */
    com.example.urgs_api.metadata.dto.ModelSyncResult syncFromDataSource(Long dataSourceId, String owner);

    /**
     * 创建模型表并记录维护日志
     * 
     * @param dto 操作DTO
     * @return 是否成功
     */
    boolean createWithRecord(ModelTableOperationDTO dto);

    /**
     * 更新模型表并记录维护日志
     * 
     * @param dto 操作DTO
     * @return 是否成功
     */
    boolean updateWithRecord(ModelTableOperationDTO dto);

    /**
     * 删除模型表并记录维护日志
     * 
     * @param id          表ID
     * @param reqId       需求ID
     * @param description 描述
     * @return 是否成功
     */
    boolean deleteWithRecord(String id, String reqId, String description);

    /**
     * 批量删除模型表并记录维护日志
     * 
     * @param ids         表ID列表
     * @param reqId       需求ID
     * @param description 描述
     * @return 是否成功
     */
    boolean deleteBatchWithRecord(List<String> ids, String reqId, String description);

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
    boolean importModels(org.springframework.web.multipart.MultipartFile file, String reqId, String description,
            String operator, String directoryId);

    /**
     * 导出模型表
     * 
     * @param tableIds 表ID列表
     * @param response HTTP响应
     */
    void exportModels(List<String> tableIds, jakarta.servlet.http.HttpServletResponse response);
}
