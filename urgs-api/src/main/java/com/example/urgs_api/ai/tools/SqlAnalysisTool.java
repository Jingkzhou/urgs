package com.example.urgs_api.ai.tools;

import com.example.urgs_api.ai.client.AiClient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.function.Consumer;

/**
 * AI SQL 分析工具
 * 专用于 SQL 解析、优化和解释
 */
@Component
public class SqlAnalysisTool {

    @Autowired
    private AiClient aiClient;

    private static final String EXPLAIN_PROMPT = """
            你是一位资深的数据库工程师。你的任务是解释 SQL 语句的逻辑和功能。

            请提供：
            1. **功能概述**：用一句话描述这个 SQL 的作用
            2. **详细解析**：逐步解释 SQL 的各个部分
            3. **关键表/字段**：列出涉及的表和重要字段
            4. **注意事项**：指出可能的性能或逻辑问题

            使用简洁清晰的中文回答。
            """;

    private static final String OPTIMIZE_PROMPT = """
            你是一位数据库性能优化专家。你的任务是优化 SQL 语句的执行效率。

            请提供：
            1. **当前 SQL 分析**：识别性能瓶颈
            2. **优化建议**：提供具体的优化方案
            3. **优化后 SQL**：给出优化后的完整 SQL
            4. **预期改进**：说明优化后的预期效果

            使用 Markdown 代码块展示 SQL。
            """;

    /**
     * 解释 SQL 语句
     */
    public String explain(String sql) {
        return aiClient.chat(EXPLAIN_PROMPT, "请解释以下 SQL：\n```sql\n" + sql + "\n```");
    }

    /**
     * 优化 SQL 语句
     */
    public String optimize(String sql) {
        return aiClient.chat(OPTIMIZE_PROMPT, "请优化以下 SQL：\n```sql\n" + sql + "\n```");
    }

    /**
     * 流式解释
     */
    public void explainStream(String sql, Consumer<String> onChunk) {
        aiClient.request()
                .systemPrompt(EXPLAIN_PROMPT)
                .userPrompt("请解释以下 SQL：\n```sql\n" + sql + "\n```")
                .requestType("sql_explain")
                .stream(onChunk);
    }
}
