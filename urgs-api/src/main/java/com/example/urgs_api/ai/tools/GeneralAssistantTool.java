package com.example.urgs_api.ai.tools;

import com.example.urgs_api.ai.client.AiClient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.function.Consumer;

/**
 * AI 通用助手工具
 * 用于一般性的问答和文本处理
 */
@Component
public class GeneralAssistantTool {

    @Autowired
    private AiClient aiClient;

    private static final String SUMMARIZE_PROMPT = """
            你是一个专业的文本摘要专家。请对用户提供的内容进行简洁准确的总结。
            总结应保留关键信息，去除冗余内容，使用清晰的结构。
            """;

    private static final String TRANSLATE_PROMPT = """
            你是一个专业的翻译专家。请将用户提供的内容准确翻译。
            保持原文的语气和风格，专业术语需准确翻译。
            """;

    /**
     * 简单问答
     */
    public String ask(String question) {
        return aiClient.chat(question);
    }

    /**
     * 流式问答
     */
    public void askStream(String question, Consumer<String> onChunk) {
        aiClient.request()
                .userPrompt(question)
                .requestType("general")
                .stream(onChunk);
    }

    /**
     * 文本总结
     */
    public String summarize(String text) {
        return aiClient.chat(SUMMARIZE_PROMPT, "请总结以下内容：\n\n" + text);
    }

    /**
     * 翻译
     */
    public String translate(String text, String targetLanguage) {
        return aiClient.chat(TRANSLATE_PROMPT,
                "请将以下内容翻译成" + targetLanguage + "：\n\n" + text);
    }
}
