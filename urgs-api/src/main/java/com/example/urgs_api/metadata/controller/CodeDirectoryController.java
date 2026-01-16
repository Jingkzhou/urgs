package com.example.urgs_api.metadata.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.example.urgs_api.common.PageResult;
import com.example.urgs_api.metadata.model.CodeDirectory;
import com.example.urgs_api.metadata.service.CodeDirectoryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;

@RestController
@RequestMapping("/api/metadata/code-directory")
/**
 * 代码目录控制器
 * 管理代码目录（Code Directory）的CRUD及导入导出
 */
public class CodeDirectoryController {

    @Autowired
    private CodeDirectoryService codeDirectoryService;

    @Autowired
    private com.example.urgs_api.metadata.component.MaintenanceLogManager maintenanceLogManager;

    @Autowired
    private com.example.urgs_api.system.service.SysSystemService sysSystemService;

    @Autowired
    private com.example.urgs_api.user.service.UserService userService;

    @Autowired
    private jakarta.servlet.http.HttpServletRequest request;

    private String getCurrentOperator() {
        Object userIdObj = request.getAttribute("userId");
        if (userIdObj != null) {
            Long userId = (Long) userIdObj;
            com.example.urgs_api.user.model.User user = userService.getById(userId);
            if (user != null) {
                return user.getName();
            }
        }
        return "admin";
    }

    /**
     * 分页查询代码目录列表
     *
     * @param keyword   关键词（匹配表名、表代码、代码、名称）
     * @param tableCode 表代码筛选
     * @param page      页码
     * @param size      每页大小
     * @return 分页结果
     */
    @GetMapping
    public PageResult<CodeDirectory> list(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String tableCode,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {

        QueryWrapper<CodeDirectory> wrapper = new QueryWrapper<>();

        if (tableCode != null && !tableCode.isEmpty()) {
            wrapper.eq("table_code", tableCode);
        } else {
            // 前端未指定 TableCode（即 "All Codes"），检查用户权限进行过滤
            Object userIdObj = request.getAttribute("userId");
            if (userIdObj != null) {
                Long userId = (Long) userIdObj;
                com.example.urgs_api.user.model.User user = userService.getById(userId);
                // 判断是否受限：非空且 system 字段不为 NULL/Empty/"ALL"
                boolean isRestricted = true;
                if (user == null || user.getSystem() == null || user.getSystem().isBlank()
                        || "ALL".equalsIgnoreCase(user.getSystem())) {
                    isRestricted = false;
                }

                if (isRestricted) {
                    java.util.List<com.example.urgs_api.system.model.SysSystem> systems = sysSystemService.list(userId);
                    java.util.List<String> clientIds = systems.stream()
                            .map(com.example.urgs_api.system.model.SysSystem::getClientId)
                            .collect(java.util.stream.Collectors.toList());

                    if (clientIds.isEmpty()) {
                        wrapper.apply("1=0"); // 无权限，查空
                    } else {
                        wrapper.in("system_code", clientIds);
                    }
                }
            }
        }

        if (keyword != null && !keyword.isEmpty()) {
            wrapper.and(w -> w.like("table_name", keyword)
                    .or().like("table_code", keyword) // 即使指定了 tableCode 也保留宽泛搜索
                    .or().like("code", keyword)
                    .or().like("name", keyword));
        }
        wrapper.orderByAsc("table_code", "sort_order");

        Page<CodeDirectory> pageParam = new Page<>(page, size);
        Page<CodeDirectory> result = codeDirectoryService.page(pageParam, wrapper);

        return PageResult.of(result);
    }

    /**
     * 获取所有不重复的表信息（用于下拉筛选）
     *
     * @return 代码目录表列表
     */
    @GetMapping("/tables")
    public java.util.List<CodeDirectory> getTables() {
        QueryWrapper<CodeDirectory> wrapper = new QueryWrapper<>();
        wrapper.select("DISTINCT table_code, table_name, system_code")
                .orderByAsc("table_code");

        // 检查用户权限进行过滤
        Object userIdObj = request.getAttribute("userId");
        if (userIdObj != null) {
            Long userId = (Long) userIdObj;
            com.example.urgs_api.user.model.User user = userService.getById(userId);
            // 判断是否受限：非空且 system 字段不为 NULL/Empty/"ALL"
            boolean isRestricted = true;
            if (user == null || user.getSystem() == null || user.getSystem().isBlank()
                    || "ALL".equalsIgnoreCase(user.getSystem())) {
                isRestricted = false;
            }

            if (isRestricted) {
                java.util.List<com.example.urgs_api.system.model.SysSystem> systems = sysSystemService.list(userId);
                java.util.List<String> clientIds = systems.stream()
                        .map(com.example.urgs_api.system.model.SysSystem::getClientId)
                        .collect(java.util.stream.Collectors.toList());

                if (clientIds.isEmpty()) {
                    wrapper.apply("1=0"); // 无权限，查空
                } else {
                    wrapper.in("system_code", clientIds);
                }
            }
        }

        return codeDirectoryService.list(wrapper);
    }

    /**
     * 新增代码目录
     *
     * @param codeDirectory 代码目录对象
     * @return 是否成功
     */
    @PostMapping
    public boolean save(@RequestBody CodeDirectory codeDirectory) {
        // Fetch old data for update
        CodeDirectory oldDir = null;
        if (codeDirectory.getId() != null) {
            oldDir = codeDirectoryService.getById(codeDirectory.getId());
        } else {
            codeDirectory.setCreateTime(LocalDateTime.now());
        }

        codeDirectory.setUpdateTime(LocalDateTime.now());
        boolean result = codeDirectoryService.saveOrUpdate(codeDirectory);

        if (result) {
            maintenanceLogManager.logChange(
                    com.example.urgs_api.metadata.component.MaintenanceLogManager.LogType.CODE_DIR,
                    oldDir,
                    codeDirectory,
                    getCurrentOperator());
        }
        return result;
    }

    /**
     * 更新代码目录
     *
     * @param codeDirectory 代码目录对象
     * @return 是否成功
     */
    @PutMapping
    public boolean update(@RequestBody CodeDirectory codeDirectory) {
        codeDirectory.setUpdateTime(LocalDateTime.now());
        return codeDirectoryService.updateById(codeDirectory);
    }

    /**
     * 删除代码目录
     *
     * @param id ID
     * @return 是否成功
     */
    /**
     * Delete code with reason
     */
    @PostMapping("/delete")
    public boolean deleteWithReason(@RequestBody com.example.urgs_api.metadata.dto.DeleteReqDTO req) {
        if (req.getIdStr() == null)
            return false;

        CodeDirectory oldCode = codeDirectoryService.getById(req.getIdStr()); // Verify getById takes String? Yes, ID is
                                                                              // String.
        boolean result = codeDirectoryService.removeById(req.getIdStr());

        if (result && oldCode != null) {
            com.example.urgs_api.metadata.component.MaintenanceLogManager.MaintenanceContext context = new com.example.urgs_api.metadata.component.MaintenanceLogManager.MaintenanceContext();
            context.setReqId(req.getReqId());
            context.setPlannedDate(req.getPlannedDate());
            context.setChangeDescription(req.getChangeDescription());

            maintenanceLogManager.logChange(
                    com.example.urgs_api.metadata.component.MaintenanceLogManager.LogType.CODE_DIR,
                    oldCode,
                    null,
                    getCurrentOperator(),
                    context);
        }
        return result;
    }

    /**
     * 删除代码目录
     */
    @DeleteMapping("/{id}")
    public boolean delete(@PathVariable String id) {
        CodeDirectory oldDir = codeDirectoryService.getById(id);
        boolean result = codeDirectoryService.removeById(id);

        if (result && oldDir != null) {
            maintenanceLogManager.logChange(
                    com.example.urgs_api.metadata.component.MaintenanceLogManager.LogType.CODE_DIR,
                    oldDir,
                    null,
                    getCurrentOperator());
        }
        return result;
    }

    /**
     * 导入代码目录数据
     *
     * @param file Excel文件
     * @return 是否成功
     */
    @PostMapping("/import")
    public com.example.urgs_api.metadata.dto.ImportResultDTO importData(
            @RequestParam("file") org.springframework.web.multipart.MultipartFile file) {
        return codeDirectoryService.importData(file);
    }

    /**
     * 导出代码目录数据
     *
     * @param response HTTP响应
     */
    @GetMapping("/export")
    public void exportData(jakarta.servlet.http.HttpServletResponse response) {
        codeDirectoryService.exportData(response);
    }
}
