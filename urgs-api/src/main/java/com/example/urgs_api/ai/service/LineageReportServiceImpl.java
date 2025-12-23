package com.example.urgs_api.ai.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.ai.client.AiClient;
import com.example.urgs_api.ai.entity.AiApiConfig;
import com.example.urgs_api.ai.entity.LineageReport;
import com.example.urgs_api.ai.repository.LineageReportMapper;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.ByteArrayOutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * 血缘报告服务实现
 */
@Service
public class LineageReportServiceImpl extends ServiceImpl<LineageReportMapper, LineageReport>
        implements LineageReportService {

    private static final Logger log = LoggerFactory.getLogger(LineageReportServiceImpl.class);
    private static final ObjectMapper objectMapper = new ObjectMapper();
    private static final ExecutorService executor = Executors.newCachedThreadPool();

    @Autowired
    private AiClient aiClient;

    @Autowired
    private AiApiConfigService aiApiConfigService;

    private static final String SYSTEM_PROMPT = """
            你是一位专业的数据治理专家和血缘分析师。你的任务是根据提供的数据血缘信息，生成一份专业的下游影响评估报告。

            ## 血缘数据结构说明
            - **节点(nodes)**: 分为 Table（表）和 Column（列）两种类型
            - **边(edges)**: 每条边有 source（源节点ID）和 target（目标节点ID），表示数据流向 source → target
            - **关系类型**: DERIVES_TO（数据派生）、JOINS（关联条件）、FILTERS（过滤条件）等

            ## 下游分析规则
            - **直接下游**: 边的 source 是目标字段，target 是直接下游节点
            - **间接下游**: 直接下游节点再往下延伸的节点（如 A→B→C，C 是 A 的间接下游）

            ## 报告结构（只需下游分析，不需要上游）
            1. **执行摘要**：概述影响范围和风险等级（高/中/低）
            2. **直接下游影响**：列出目标字段直接影响的表和字段（第一层）
            3. **间接下游影响**：列出通过中间表间接受影响的表和字段（第二层及以后）
            4. **风险评估**：分析变更可能带来的风险
            5. **建议措施**：提供变更前的建议

            请使用 Markdown 格式输出，清晰区分直接下游和间接下游。
            """;

    @Override
    public SseEmitter generateReportStream(String tableName, String columnName, Map<String, Object> lineageContext) {
        SseEmitter emitter = new SseEmitter(300000L); // 5 分钟超时

        executor.submit(() -> {
            StringBuilder fullContent = new StringBuilder();
            try {
                // 构建用户提示词
                String userPrompt = buildUserPrompt(tableName, columnName, lineageContext);
                log.info("Generating report for {}.{}", tableName, columnName);
                log.info("User prompt length: {}, context keys: {}", userPrompt.length(),
                        lineageContext != null ? lineageContext.keySet() : "null");
                log.debug("Full user prompt:\n{}", userPrompt);

                // 使用 AiClient 构建器模式流式调用
                aiClient.request()
                        .systemPrompt(SYSTEM_PROMPT)
                        .userPrompt(userPrompt)
                        .requestType("report")
                        .onChunk(chunk -> {
                            fullContent.append(chunk);
                            try {
                                emitter.send(SseEmitter.event()
                                        .data(objectMapper.writeValueAsString(Map.of("content", chunk))));
                            } catch (Exception e) {
                                log.error("Failed to send chunk", e);
                            }
                        })
                        .onComplete(() -> {
                            try {
                                // 自动保存报告
                                LineageReport report = new LineageReport();
                                report.setTableName(tableName);
                                report.setColumnName(columnName);
                                report.setReportContent(fullContent.toString());
                                report.setUpstreamCount(getCount(lineageContext, "upstreamCount"));
                                report.setDownstreamCount(getCount(lineageContext, "downstreamCount"));
                                report.setStatus("completed");
                                report.setCreateTime(LocalDateTime.now());

                                AiApiConfig config = aiApiConfigService.getDefaultConfig();
                                if (config != null) {
                                    report.setAiModel(config.getProvider() + "/" + config.getModel());
                                }

                                save(report);

                                emitter.send(SseEmitter.event()
                                        .data(objectMapper.writeValueAsString(Map.of(
                                                "done", true,
                                                "reportId", report.getId()))));
                                emitter.complete();
                            } catch (Exception e) {
                                log.error("Failed to save report", e);
                                emitter.completeWithError(e);
                            }
                        })
                        .onError(e -> {
                            try {
                                emitter.send(SseEmitter.event()
                                        .data(objectMapper.writeValueAsString(Map.of("error", e.getMessage()))));
                                emitter.completeWithError(e);
                            } catch (Exception ex) {
                                log.error("Failed to send error", ex);
                            }
                        })
                        .execute();
            } catch (Exception e) {
                log.error("Generate report failed", e);
                emitter.completeWithError(e);
            }
        });

        emitter.onTimeout(() -> log.warn("SSE timeout for {}.{}", tableName, columnName));
        emitter.onCompletion(() -> log.info("SSE completed for {}.{}", tableName, columnName));

        return emitter;
    }

    private String buildUserPrompt(String tableName, String columnName, Map<String, Object> context) {
        StringBuilder sb = new StringBuilder();
        sb.append("请分析以下字段的数据血缘影响：\n\n");
        sb.append("## 分析对象\n");
        sb.append("- **表名**: ").append(tableName).append("\n");
        sb.append("- **字段名**: ").append(columnName).append("\n\n");

        if (context != null) {
            // 统计信息
            Object totalNodes = context.get("totalNodes");
            Object totalEdges = context.get("totalEdges");
            if (totalNodes != null) {
                sb.append("## 血缘统计\n");
                sb.append("- **关联节点数**: ").append(totalNodes).append("\n");
                sb.append("- **关系边数**: ").append(totalEdges).append("\n\n");
            }

            // 关系类型信息
            Object relations = context.get("relations");
            if (relations != null && relations instanceof Map && !((Map<?, ?>) relations).isEmpty()) {
                sb.append("## 关系类型分布\n");
                sb.append("```json\n").append(formatJson(relations)).append("\n```\n\n");
            }

            // 完整血缘图数据
            Object graphData = context.get("graphData");
            if (graphData != null) {
                sb.append("## 血缘图数据\n");
                sb.append("```json\n").append(formatJson(graphData)).append("\n```\n\n");
            }
        }

        sb.append("请根据以上血缘信息，生成一份完整的影响评估报告。");
        return sb.toString();
    }

    private String formatJson(Object obj) {
        try {
            return objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(obj);
        } catch (Exception e) {
            return String.valueOf(obj);
        }
    }

    private Integer getCount(Map<String, Object> context, String key) {
        if (context == null || !context.containsKey(key))
            return 0;
        Object val = context.get(key);
        if (val instanceof Number) {
            return ((Number) val).intValue();
        }
        return 0;
    }

    @Override
    public LineageReport saveReport(LineageReport report) {
        if (report.getCreateTime() == null) {
            report.setCreateTime(LocalDateTime.now());
        }
        if (report.getStatus() == null) {
            report.setStatus("completed");
        }
        saveOrUpdate(report);
        return report;
    }

    @Override
    public List<LineageReport> getReportHistory(String tableName, String columnName) {
        LambdaQueryWrapper<LineageReport> query = new LambdaQueryWrapper<>();
        query.eq(LineageReport::getTableName, tableName);
        if (columnName != null && !columnName.isEmpty()) {
            query.eq(LineageReport::getColumnName, columnName);
        }
        query.orderByDesc(LineageReport::getCreateTime);
        query.last("LIMIT 20");
        return list(query);
    }

    @Override
    public byte[] exportToPdf(Long reportId) {
        LineageReport report = getById(reportId);
        if (report == null) {
            throw new RuntimeException("报告不存在");
        }

        // 简化实现：返回 Markdown 内容作为文本
        // 完整实现需要引入 flying-saucer 或 itext 依赖
        try {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            PrintWriter writer = new PrintWriter(new OutputStreamWriter(baos, StandardCharsets.UTF_8));
            writer.println("血缘影响分析报告");
            writer.println("================");
            writer.println();
            writer.println("表名: " + report.getTableName());
            writer.println("字段: " + report.getColumnName());
            writer.println("生成时间: " + report.getCreateTime());
            writer.println();
            writer.println("--- 报告内容 ---");
            writer.println();
            writer.println(report.getReportContent());
            writer.flush();
            return baos.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("导出 PDF 失败", e);
        }
    }

    @Override
    public byte[] exportToWord(Long reportId) {
        LineageReport report = getById(reportId);
        if (report == null) {
            throw new RuntimeException("报告不存在");
        }

        // 简化实现：返回 Markdown 内容作为文本
        // 完整实现需要引入 poi-ooxml 依赖
        try {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            PrintWriter writer = new PrintWriter(new OutputStreamWriter(baos, StandardCharsets.UTF_8));
            writer.println("血缘影响分析报告");
            writer.println();
            writer.println("表名: " + report.getTableName());
            writer.println("字段: " + report.getColumnName());
            writer.println("生成时间: " + report.getCreateTime());
            writer.println();
            writer.println(report.getReportContent());
            writer.flush();
            return baos.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("导出 Word 失败", e);
        }
    }
}
