package com.example.urgs_api.metadata.controller;

import com.example.urgs_api.metadata.service.LineageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/metadata/lineage")
/**
 * 血缘分析控制器
 * 提供血缘图谱、影响分析、血缘追溯等功能
 */
public class LineageController {

    @Autowired
    private LineageService lineageService;

    /**
     * 获取血缘图谱数据
     *
     * @param tableName  表名
     * @param columnName 字段名（可选）
     * @param depth      查询深度，默认2
     * @return 包含 nodes 和 edges 的图谱数据
     */
    @GetMapping("/graph")
    public Map<String, Object> getLineageGraph(
            @RequestParam(required = false) String tableName,
            @RequestParam(required = false) String columnName,
            @RequestParam(defaultValue = "2") int depth) {
        System.out.println("Received lineage request for table: " + tableName + ", column: " + columnName);

        // 如果没有表名，返回空结果
        if (tableName == null || tableName.trim().isEmpty()) {
            return Map.of("nodes", java.util.Collections.emptyList(), "edges", java.util.Collections.emptyList());
        }

        return lineageService.getGraphData(tableName, columnName, depth);
    }

    /**
     * 搜索表
     *
     * @param keyword 搜索关键词
     * @return 匹配的表列表
     */
    @GetMapping("/search")
    public Map<String, Object> searchTables(
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        if (keyword == null) {
            keyword = "";
        }
        return lineageService.searchTables(keyword, page, size);
    }

    /**
     * 影响分析 API - 返回所有类型的下游影响
     *
     * @param tableName  表名
     * @param columnName 字段名
     * @param version    版本
     * @param depth      深度，默认5
     * @param types      血缘类型列表
     * @return 影响分析结果
     */
    @GetMapping("/impact")
    public Map<String, Object> getImpactAnalysis(
            @RequestParam String tableName,
            @RequestParam String columnName,
            @RequestParam(required = false) String version,
            @RequestParam(defaultValue = "5") int depth,
            @RequestParam(required = false) List<String> types) {
        System.out.println("Impact analysis request for " + tableName + "." + columnName);
        return lineageService.getImpactAnalysis(tableName, columnName, version, depth, types);
    }

    /**
     * 血缘追溯 API - 只返回直接数据流 (fdd/DERIVES_TO)
     *
     * @param tableName  表名
     * @param columnName 字段名
     * @param direction  方向（upstream/downstream），默认upstream
     * @param version    版本
     * @param depth      深度，默认5
     * @return 血缘追溯结果
     */
    @GetMapping("/trace")
    public Map<String, Object> getLineageTrace(
            @RequestParam String tableName,
            @RequestParam String columnName,
            @RequestParam(defaultValue = "upstream") String direction,
            @RequestParam(required = false) String version,
            @RequestParam(defaultValue = "5") int depth) {
        System.out.println("Lineage trace request for " + tableName + "." + columnName);
        return lineageService.getLineageTrace(tableName, columnName, direction, version, depth);
    }

    /**
     * 获取所有血缘版本列表
     *
     * @return 版本列表
     */
    @GetMapping("/versions")
    public List<Map<String, Object>> getVersions() {
        return lineageService.getLineageVersions();
    }

    /**
     * 导出血缘Excel
     *
     * @param tableName  表名
     * @param columnName 字段名 (可选)
     * @param depth      深度 (-1表示全部)
     * @param response   HttpServletResponse
     * @throws IOException
     */
    @GetMapping("/export")
    public void exportLineage(@RequestParam String tableName,
            @RequestParam(required = false) String columnName,
            @RequestParam(defaultValue = "-1") int depth,
            HttpServletResponse response) throws IOException {
        lineageService.exportLineage(tableName, columnName, depth, response);
    }
}
