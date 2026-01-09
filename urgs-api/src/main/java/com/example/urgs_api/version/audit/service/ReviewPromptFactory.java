package com.example.urgs_api.version.audit.service;

import org.springframework.stereotype.Component;

/**
 * Review Prompt Factory
 * Generates context-aware prompts for different languages and review phases.
 */
@Component
public class ReviewPromptFactory {

    public String getMapPhasePrompt(String language, String chunkContent) {
        String checklist = getChecklist(language);

        return String.format(
                """
                        你是一位精通 %s 的资深代码审查专家。
                        请分析以下代码片段。注意这只是完整文件的一部分。

                        请重点关注基于以下检查清单的【严重】(CRITICAL) 和【主要】(MAJOR) 问题：
                        %s

                        忽略可能在其他片段中解决的问题（如缺少导入或未定义变量），除非你非常确定。

                        请严格按照 JSON 格式返回结果：
                        {
                            "issues": [
                                {
                                    "severity": "critical|major|minor",
                                    "title": "简短标题",
                                    "description": "详细解释",
                                    "line": <片段中的大致行号>,
                                    "recommendation": "修复建议",
                                    "codeSnippet": "问题代码片段"
                                }
                            ]
                        }

                        如果未发现问题，请返回 { "issues": [] }。

                        代码片段：
                        ```%s
                        %s
                        ```
                        """,
                language, checklist, language.toLowerCase(), chunkContent);
    }

    public String getReducePhasePrompt(String language, String aggregatedIssuesJson) {
        return String.format("""
                你是一位首席架构师。
                我们已经分块分析了一个文件（语言：%s），并发现了以下潜在问题。
                由于分块原因，可能存在重复或误报。

                请整合、去重并验证这些问题。
                过滤掉细枝末节的问题，除非它们非常普遍。
                根据严重程度和数量计算质量得分（0-100）。

                输入问题列表 (JSON):
                %s

                请严格按照 JSON 格式返回最终结果：
                {
                    "score": <0-100>,
                    "content": "代码质量和主要风险的高层执行摘要。",
                    "issues": [
                         // 整合后的有效问题列表
                        {
                            "severity": "critical|major|minor",
                            "title": "...",
                            "description": "...",
                            "line": <number>,
                            "recommendation": "...",
                            "codeSnippet": "..."
                        }
                    ],
                    "scoreBreakdown": {
                        "security": <0-100>,
                        "reliability": <0-100>,
                        "maintainability": <0-100>,
                        "performance": <0-100>
                    }
                }
                """, language, aggregatedIssuesJson);
    }

    private String getChecklist(String language) {
        return switch (language.toLowerCase()) {
            case "java" -> """
                    - 并发：线程安全、锁机制、竞态条件。
                    - 资源：流/连接未关闭（try-with-resources）。
                    - 空安全：Optional 使用、空指针检查。
                    - 性能：N+1 查询、低效循环、大对象创建。
                    - 安全：SQL 注入、XSS、敏感数据记录。
                    - 异常处理：空 catch 块、吞没异常。
                    """;
            case "python" -> """
                    - 类型安全：类型提示的使用。
                    - 性能：低效的列表推导、全局变量。
                    - 安全：依赖漏洞、输入验证。
                    - Pythonic：违反 PEP8（仅主要违规）。
                    """;
            case "sql" -> """
                    - 性能：索引使用、全表扫描、SELECT *。
                    - 安全：SQL 注入风险（动态 SQL）。
                    - 锁：死锁风险、长事务。
                    """;
            default -> """
                    - 通用整洁代码：可读性、命名规范。
                    - 逻辑 Bug：越界、无限循环。
                    - 安全：代码中的密钥、输入清理。
                    """;
        };
    }
}
