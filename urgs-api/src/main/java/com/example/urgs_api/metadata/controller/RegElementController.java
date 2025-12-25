package com.example.urgs_api.metadata.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.urgs_api.common.PageResult;
import com.example.urgs_api.metadata.model.RegElement;
import com.example.urgs_api.metadata.service.RegElementService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import com.alibaba.excel.EasyExcel;
import com.alibaba.excel.read.listener.PageReadListener;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.net.URLEncoder;
import java.util.List;
import java.time.LocalDateTime;

@RestController
@RequestMapping("/api/reg/element")
/**
 * 监管元素控制器
 * 管理监管报表的指标元素（RegElement）
 */
public class RegElementController {

    @Autowired
    private RegElementService regElementService;

    @Autowired
    private com.example.urgs_api.metadata.component.MaintenanceLogManager maintenanceLogManager;

    /**
     * 分页查询监管元素列表
     *
     * @param tableId 报表ID
     * @param keyword 搜索关键词
     * @param type    元素类型
     * @param page    页码
     * @param size    每页大小
     * @return 分页结果
     */
    @GetMapping("/list")
    public PageResult<RegElement> list(
            @RequestParam Long tableId,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String type,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {

        QueryWrapper<RegElement> query = new QueryWrapper<>();
        query.eq("table_id", tableId);

        if (type != null && !type.isEmpty()) {
            query.eq("type", type);
        }

        if (keyword != null && !keyword.isEmpty()) {
            String kw = keyword.toLowerCase();
            query.and(w -> w.like("LOWER(name)", kw)
                    .or().like("LOWER(cn_name)", kw)
                    .or().like("LOWER(code)", kw));
        }

        query.orderByAsc("sort_order", "id");

        com.baomidou.mybatisplus.extension.plugins.pagination.Page<RegElement> pageParam = new com.baomidou.mybatisplus.extension.plugins.pagination.Page<>(
                page, size);
        return PageResult.of(regElementService.page(pageParam, query));
    }

    /**
     * 获取元素详情
     *
     * @param id 元素ID
     * @return 元素对象
     */
    @GetMapping("/{id}")
    public RegElement get(@PathVariable Long id) {
        return regElementService.getById(id);
    }

    /**
     * 新增或更新元素
     *
     * @param regElement 元素对象
     * @return 是否成功
     */
    @PostMapping
    public boolean save(@RequestBody RegElement regElement) {
        // Fetch old data if update
        RegElement oldElement = null;
        if (regElement.getId() != null) {
            oldElement = regElementService.getById(regElement.getId());
        } else {
            regElement.setCreateTime(LocalDateTime.now());
        }

        boolean result = regElementService.saveOrUpdate(regElement);

        if (result) {
            maintenanceLogManager.logChange(
                    com.example.urgs_api.metadata.component.MaintenanceLogManager.LogType.ELEMENT,
                    oldElement,
                    regElement,
                    "admin");
        }
        return result;
    }

    /**
     * 删除元素
     *
     * @param id 元素ID
     * @return 是否成功
     */
    @DeleteMapping("/{id}")
    public boolean delete(@PathVariable Long id) {
        RegElement oldElement = regElementService.getById(id);
        boolean result = regElementService.removeById(id);

        if (result && oldElement != null) {
            maintenanceLogManager.logChange(
                    com.example.urgs_api.metadata.component.MaintenanceLogManager.LogType.ELEMENT,
                    oldElement,
                    null,
                    "admin");
        }
        return result;
    }

    /**
     * 导出监管元素
     *
     * @param tableId  报表ID
     * @param response HTTP响应
     * @throws IOException IO异常
     */
    @GetMapping("/export")
    public void export(@RequestParam Long tableId, HttpServletResponse response) throws IOException {
        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        response.setCharacterEncoding("utf-8");
        String fileName = URLEncoder.encode("RegulatoryElements", "UTF-8").replaceAll("\\+", "%20");
        response.setHeader("Content-disposition", "attachment;filename*=utf-8''" + fileName + ".xlsx");

        QueryWrapper<RegElement> query = new QueryWrapper<>();
        query.eq("table_id", tableId);
        query.orderByAsc("sort_order", "id");
        List<RegElement> list = regElementService.list(query);

        EasyExcel.write(response.getOutputStream(), RegElement.class)
                .sheet("Elements")
                .doWrite(list);
    }

    /**
     * 导入监管元素
     *
     * @param tableId 报表ID
     * @param file    Excel文件
     * @return 是否成功
     * @throws IOException IO异常
     */
    @PostMapping("/import")
    public boolean importData(@RequestParam Long tableId, @RequestParam("file") MultipartFile file) throws IOException {
        EasyExcel.read(file.getInputStream(), RegElement.class, new PageReadListener<RegElement>(dataList -> {
            for (RegElement element : dataList) {
                element.setTableId(tableId);
                if (element.getSortOrder() == null) {
                    element.setSortOrder(0);
                }
                if (element.getStatus() == null) {
                    element.setStatus(1);
                }
                // Optional: clear ID if you want to force insert, but keeping it allows update
                // element.setId(null);
            }
            regElementService.saveOrUpdateBatch(dataList);
        })).sheet().doRead();
        return true;
    }
}
