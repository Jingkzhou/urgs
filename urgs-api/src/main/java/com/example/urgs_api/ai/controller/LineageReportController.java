package com.example.urgs_api.ai.controller;

import com.example.urgs_api.ai.entity.LineageReport;
import com.example.urgs_api.ai.service.LineageReportService;
import com.example.urgs_api.metadata.service.LineageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import jakarta.servlet.http.HttpServletResponse;
import java.io.OutputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 血缘报告 API 控制器
 */
@RestController
@RequestMapping("/api/lineage/report")
public class LineageReportController {

    @Autowired
    private LineageReportService lineageReportService;

    @Autowired
    private LineageService lineageService;

    /**
     * 生成血缘影响报告（SSE 流式输出）
     */
    @GetMapping(value = "/generate", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter generateReport(
            @RequestParam String tableName,
            @RequestParam String columnName,
            @RequestParam(required = false, defaultValue = "5") Integer depth) {

        // 获取血缘上下文数据
        Map<String, Object> lineageContext = buildLineageContext(tableName, columnName, depth);

        return lineageReportService.generateReportStream(tableName, columnName, lineageContext);
    }

    /**
     * 构建血缘上下文，用于 AI 分析
     * 只保留与目标字段直接相关的节点和边
     */
    private Map<String, Object> buildLineageContext(String tableName, String columnName, int depth) {
        Map<String, Object> context = new HashMap<>();

        try {
            Map<String, Object> graphData = lineageService.getGraphData(tableName, columnName, depth);

            if (graphData != null) {
                List<?> allNodes = (List<?>) graphData.get("nodes");
                List<?> allEdges = (List<?>) graphData.get("edges");

                // 1. 找到目标字段的节点 ID
                String targetColumnId = null;
                if (allNodes != null) {
                    for (Object node : allNodes) {
                        if (node instanceof Map) {
                            Map<?, ?> nodeMap = (Map<?, ?>) node;
                            List<?> labels = (List<?>) nodeMap.get("labels");
                            if (labels != null && labels.contains("Column")) {
                                Map<?, ?> props = (Map<?, ?>) nodeMap.get("properties");
                                if (props != null) {
                                    String name = (String) props.get("name");
                                    String table = (String) props.get("table");
                                    if (columnName.equalsIgnoreCase(name) &&
                                            tableName.equalsIgnoreCase(table)) {
                                        targetColumnId = (String) nodeMap.get("id");
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }

                // 2. 多轮遍历：收集所有下游依赖（包括间接下游）
                List<Map<String, Object>> relevantEdges = new ArrayList<>();
                Set<String> relevantNodeIds = new HashSet<>();
                Set<String> processedSources = new HashSet<>();

                if (targetColumnId != null) {
                    relevantNodeIds.add(targetColumnId);
                }

                Map<String, Integer> relationCounts = new HashMap<>();

                if (allEdges != null && targetColumnId != null) {
                    // 建立边的索引：source -> edges
                    Map<String, List<Map<?, ?>>> edgesBySource = new HashMap<>();
                    for (Object edge : allEdges) {
                        if (edge instanceof Map) {
                            Map<?, ?> edgeMap = (Map<?, ?>) edge;
                            String source = (String) edgeMap.get("source");
                            String type = (String) edgeMap.get("type");
                            if (!"BELONGS_TO".equals(type)) {
                                edgesBySource.computeIfAbsent(source, k -> new ArrayList<>()).add(edgeMap);
                            }
                        }
                    }

                    // BFS 遍历下游（source 是目标字段或其下游节点）
                    java.util.Queue<String> queue = new java.util.LinkedList<>();
                    queue.add(targetColumnId);

                    while (!queue.isEmpty()) {
                        String currentId = queue.poll();
                        if (processedSources.contains(currentId))
                            continue;
                        processedSources.add(currentId);

                        List<Map<?, ?>> outEdges = edgesBySource.get(currentId);
                        if (outEdges != null) {
                            for (Map<?, ?> edgeMap : outEdges) {
                                String target = (String) edgeMap.get("target");
                                String type = (String) edgeMap.get("type");

                                relevantEdges.add(new HashMap<>((Map<String, Object>) edgeMap));
                                relevantNodeIds.add(target);
                                relationCounts.put(type, relationCounts.getOrDefault(type, 0) + 1);

                                // 将下游节点加入队列继续遍历
                                if (!processedSources.contains(target)) {
                                    queue.add(target);
                                }
                            }
                        }
                    }
                }

                // 3. 过滤：只保留相关节点
                List<Map<String, Object>> relevantNodes = new ArrayList<>();
                if (allNodes != null) {
                    for (Object node : allNodes) {
                        if (node instanceof Map) {
                            Map<?, ?> nodeMap = (Map<?, ?>) node;
                            String nodeId = (String) nodeMap.get("id");
                            if (relevantNodeIds.contains(nodeId)) {
                                relevantNodes.add(new HashMap<>((Map<String, Object>) nodeMap));
                            }
                        }
                    }
                }

                // 4. 构建过滤后的血缘图
                Map<String, Object> filteredGraph = new HashMap<>();
                filteredGraph.put("nodes", relevantNodes);
                filteredGraph.put("edges", relevantEdges);

                context.put("graphData", filteredGraph);
                context.put("relations", relationCounts);
                context.put("totalNodes", relevantNodes.size());
                context.put("totalEdges", relevantEdges.size());
            }

        } catch (Exception e) {
            context.put("error", "获取血缘数据时发生错误: " + e.getMessage());
        }

        return context;
    }

    /**
     * 保存报告
     */
    @PostMapping("/save")
    public ResponseEntity<LineageReport> saveReport(@RequestBody LineageReport report) {
        LineageReport saved = lineageReportService.saveReport(report);
        return ResponseEntity.ok(saved);
    }

    /**
     * 获取历史报告列表
     */
    @GetMapping("/history")
    public ResponseEntity<List<LineageReport>> getHistory(
            @RequestParam String tableName,
            @RequestParam(required = false) String columnName) {
        List<LineageReport> reports = lineageReportService.getReportHistory(tableName, columnName);
        return ResponseEntity.ok(reports);
    }

    /**
     * 获取单个报告详情
     */
    @GetMapping("/{id}")
    public ResponseEntity<LineageReport> getReport(@PathVariable Long id) {
        LineageReport report = lineageReportService.getById(id);
        if (report == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(report);
    }

    /**
     * 删除报告
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, Object>> deleteReport(@PathVariable Long id) {
        boolean success = lineageReportService.removeById(id);
        return ResponseEntity.ok(Map.of("success", success));
    }

    /**
     * 导出报告为 PDF
     */
    @GetMapping("/export/pdf/{id}")
    public void exportPdf(@PathVariable Long id, HttpServletResponse response) {
        try {
            LineageReport report = lineageReportService.getById(id);
            if (report == null) {
                response.setStatus(404);
                return;
            }

            byte[] pdfBytes = lineageReportService.exportToPdf(id);

            String filename = String.format("血缘报告_%s_%s_%s.txt",
                    report.getTableName(),
                    report.getColumnName(),
                    report.getCreateTime().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss")));

            response.setContentType("text/plain; charset=utf-8");
            response.setHeader(HttpHeaders.CONTENT_DISPOSITION,
                    "attachment;filename*=utf-8''" + URLEncoder.encode(filename, StandardCharsets.UTF_8));

            try (OutputStream os = response.getOutputStream()) {
                os.write(pdfBytes);
            }
        } catch (Exception e) {
            response.setStatus(500);
        }
    }

    /**
     * 导出报告为 Word
     */
    @GetMapping("/export/word/{id}")
    public void exportWord(@PathVariable Long id, HttpServletResponse response) {
        try {
            LineageReport report = lineageReportService.getById(id);
            if (report == null) {
                response.setStatus(404);
                return;
            }

            byte[] wordBytes = lineageReportService.exportToWord(id);

            String filename = String.format("血缘报告_%s_%s_%s.txt",
                    report.getTableName(),
                    report.getColumnName(),
                    report.getCreateTime().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss")));

            response.setContentType("text/plain; charset=utf-8");
            response.setHeader(HttpHeaders.CONTENT_DISPOSITION,
                    "attachment;filename*=utf-8''" + URLEncoder.encode(filename, StandardCharsets.UTF_8));

            try (OutputStream os = response.getOutputStream()) {
                os.write(wordBytes);
            }
        } catch (Exception e) {
            response.setStatus(500);
        }
    }
}
