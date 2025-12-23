package com.example.urgs_api.ai.tools;

import com.example.urgs_api.ai.client.AiClient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.Map;
import java.util.function.Consumer;

/**
 * AI 血缘分析工具
 * 专用于血缘影响分析报告生成
 */
@Component
public class LineageAnalysisTool {

    @Autowired
    private AiClient aiClient;

    private static final String SYSTEM_PROMPT = """
            你是一位专业的数据治理专家和血缘分析师。你的任务是根据提供的数据血缘信息，生成一份专业、全面的影响评估报告。

            报告应包含以下部分：
            1. **执行摘要**：用简洁的语言概述该字段的整体影响范围和风险等级（高/中/低）
            2. **上游依赖分析**：分析数据来源，识别关键依赖
            3. **下游影响分析**：详细列出受影响的下游表和字段，评估影响范围
            4. **风险评估**：识别潜在风险点，如数据一致性、报表影响等
            5. **建议措施**：提供变更前的建议和注意事项

            请使用 Markdown 格式输出，使用清晰的标题结构。报告应当专业、准确、可操作。
            """;

    /**
     * 生成血缘影响报告（同步）
     */
    public String generateReport(String tableName, String columnName, Map<String, Object> context) {
        String userPrompt = buildPrompt(tableName, columnName, context);
        return aiClient.chat(SYSTEM_PROMPT, userPrompt);
    }

    /**
     * 生成血缘影响报告（流式）
     */
    public void generateReportStream(String tableName, String columnName,
            Map<String, Object> context,
            Consumer<String> onChunk,
            Runnable onComplete,
            Consumer<Exception> onError) {
        String userPrompt = buildPrompt(tableName, columnName, context);
        aiClient.request()
                .systemPrompt(SYSTEM_PROMPT)
                .userPrompt(userPrompt)
                .requestType("lineage_report")
                .onChunk(onChunk)
                .onComplete(onComplete)
                .onError(onError)
                .execute();
    }

    /**
     * 生成血缘影响报告（SSE）
     */
    public SseEmitter generateReportSse(String tableName, String columnName, Map<String, Object> context) {
        String userPrompt = buildPrompt(tableName, columnName, context);
        return aiClient.streamChat(SYSTEM_PROMPT, userPrompt, "lineage_report");
    }

    private String buildPrompt(String tableName, String columnName, Map<String, Object> context) {
        StringBuilder sb = new StringBuilder();
        sb.append("请分析以下字段的数据血缘影响：\n\n");
        sb.append("## 分析对象\n");
        sb.append("- **表名**: ").append(tableName).append("\n");
        sb.append("- **字段名**: ").append(columnName).append("\n\n");

        if (context != null) {
            if (context.containsKey("upstream")) {
                sb.append("## 上游依赖\n```json\n")
                        .append(context.get("upstream")).append("\n```\n\n");
            }
            if (context.containsKey("downstream")) {
                sb.append("## 下游影响\n```json\n")
                        .append(context.get("downstream")).append("\n```\n\n");
            }
            if (context.containsKey("relations")) {
                sb.append("## 关系类型\n```json\n")
                        .append(context.get("relations")).append("\n```\n\n");
            }
        }

        sb.append("请根据以上血缘信息，生成一份完整的影响评估报告。");
        return sb.toString();
    }
}
