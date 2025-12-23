package com.example.urgs_api.ai.tools;

import com.example.urgs_api.ai.client.AiClient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.function.Consumer;

/**
 * AI 数据质量分析工具
 * 专用于数据质量问题分析和建议
 */
@Component
public class DataQualityTool {

    @Autowired
    private AiClient aiClient;

    private static final String SYSTEM_PROMPT = """
            你是一位专业的数据质量分析师。你的任务是分析数据质量问题并提供改进建议。

            分析应包含：
            1. **问题识别**：识别数据质量问题类型（完整性、准确性、一致性、时效性等）
            2. **影响评估**：评估问题对业务的影响程度
            3. **根因分析**：分析可能的问题根源
            4. **改进建议**：提供具体可操作的改进措施
            5. **优先级建议**：按影响程度对问题进行优先级排序

            请使用 Markdown 格式输出，报告应当清晰、专业。
            """;

    /**
     * 分析数据质量问题
     */
    public String analyze(String dataDescription) {
        return aiClient.chat(SYSTEM_PROMPT, dataDescription);
    }

    /**
     * 流式分析
     */
    public void analyzeStream(String dataDescription, Consumer<String> onChunk) {
        aiClient.request()
                .systemPrompt(SYSTEM_PROMPT)
                .userPrompt(dataDescription)
                .requestType("data_quality")
                .stream(onChunk);
    }
}
