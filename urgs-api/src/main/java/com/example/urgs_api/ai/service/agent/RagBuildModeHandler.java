package com.example.urgs_api.ai.service.agent;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.ai.dto.RagQueryRequest;
import com.example.urgs_api.ai.dto.RagQueryResponse;
import com.example.urgs_api.ai.entity.Agent;
import com.example.urgs_api.ai.entity.KnowledgeBase;
import com.example.urgs_api.ai.repository.KnowledgeBaseRepository;
import com.example.urgs_api.ai.service.RagService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.List;
import java.util.Map;

@Component
public class RagBuildModeHandler {

    private static final Logger log = LoggerFactory.getLogger(RagBuildModeHandler.class);
    private static final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    private KnowledgeBaseRepository knowledgeBaseRepository;

    @Autowired
    private RagService ragService;

    public boolean supports(Agent agent) {
        return agent != null && "RAG".equalsIgnoreCase(agent.getBuildMode())
                && agent.getKnowledgeBase() != null && !agent.getKnowledgeBase().isBlank();
    }

    public RagPreparation prepare(Agent agent, String systemPrompt, String userPrompt, SseEmitter emitter) {
        String effectiveSystemPrompt = systemPrompt;
        if (agent.getSystemPrompt() != null && !agent.getSystemPrompt().isBlank()) {
            effectiveSystemPrompt = agent.getSystemPrompt();
        }

        String contextAugmentation = "";
        List<String> collectionNames = resolveCollectionNames(agent);
        if (collectionNames.isEmpty()) {
            log.warn("Agent has KB configured but no valid collections found.");
            return new RagPreparation(effectiveSystemPrompt, contextAugmentation);
        }

        log.info("Performing RAG Query for Agent {} on Collections: {}", agent.getName(), collectionNames);
        sendStatus(emitter, "searching");

        RagQueryRequest ragReq = new RagQueryRequest();
        ragReq.setQuery(userPrompt);
        ragReq.setCollectionNames(collectionNames);
        ragReq.setK(4);

        try {
            RagQueryResponse ragRes = ragService.query(ragReq);
            sendIntent(emitter, ragRes);
            contextAugmentation = buildContextAndSendSources(agent, ragRes, emitter);
        } catch (Exception e) {
            log.error("RAG Query Failed", e);
        }

        return new RagPreparation(effectiveSystemPrompt, contextAugmentation);
    }

    public void applyContextToMessages(Agent agent, List<Map<String, String>> messages, String contextAugmentation) {
        if (contextAugmentation == null || contextAugmentation.isEmpty() || messages.isEmpty()) {
            return;
        }

        Map<String, String> sysMsg = messages.get(0);
        if ("system".equals(sysMsg.get("role"))) {
            String ragInstructions = defaultRagInstructions();
            if (agent != null && agent.getRagInstruction() != null && !agent.getRagInstruction().isBlank()) {
                log.info("Applying Custom RAG Instructions for Agent: {}", agent.getName());
                ragInstructions = agent.getRagInstruction() + "\n\n";
            }
            messages.set(0, Map.of("role", "system", "content", ragInstructions + sysMsg.get("content")));
        }

        int lastIdx = messages.size() - 1;
        Map<String, String> lastMsg = messages.get(lastIdx);
        if ("user".equals(lastMsg.get("role"))) {
            String originalContent = lastMsg.get("content");
            String newContent = String.format("""
                    【用户问题 / User Question】:
                    %s

                    %s
                    """, originalContent, contextAugmentation);
            messages.set(lastIdx, Map.of("role", "user", "content", newContent));
        }
    }

    private List<String> resolveCollectionNames(Agent agent) {
        List<String> collectionNames = new java.util.ArrayList<>();
        String[] kbIds = agent.getKnowledgeBase().split(",");
        for (String kbIdStr : kbIds) {
            String target = kbIdStr.trim();
            if (target.isEmpty()) {
                continue;
            }

            KnowledgeBase kb = lookupKnowledgeBase(target);
            if (kb != null) {
                log.info("Found KnowledgeBase - ID: {}, Collection: {}", kb.getId(), kb.getCollectionName());
                if (kb.getCollectionName() != null) {
                    collectionNames.add(kb.getCollectionName());
                }
            } else {
                log.warn("KnowledgeBase not found for target: {}", target);
            }
        }
        return collectionNames;
    }

    private KnowledgeBase lookupKnowledgeBase(String target) {
        try {
            if (target.matches("\\d+")) {
                KnowledgeBase kb = knowledgeBaseRepository.selectById(Long.parseLong(target));
                if (kb != null) {
                    return kb;
                }
            }
        } catch (Exception e) {
            log.warn("Failed to parse KB ID: {}", target);
        }

        try {
            return knowledgeBaseRepository.selectOne(
                    new LambdaQueryWrapper<KnowledgeBase>()
                            .eq(KnowledgeBase::getName, target)
                            .or()
                            .eq(KnowledgeBase::getCollectionName, target));
        } catch (Exception e) {
            log.warn("KB lookup by name/collection failed for: {}", target);
            return null;
        }
    }

    private String buildContextAndSendSources(Agent agent, RagQueryResponse ragRes, SseEmitter emitter) {
        if (ragRes == null || ragRes.getEffectiveResults() == null || ragRes.getEffectiveResults().isEmpty()) {
            sendSources(emitter, List.of());
            log.info("RAG yielded no results for agent {}", agent.getName());
            return "";
        }

        final double scoreThreshold = 0.02;
        List<Map<String, Object>> filteredResults = ragRes.getEffectiveResults().stream()
                .filter(r -> {
                    Object scoreObj = r.get("score");
                    return scoreObj instanceof Number && ((Number) scoreObj).doubleValue() >= scoreThreshold;
                })
                .collect(java.util.stream.Collectors.toList());

        log.info("RAG Results: {} total, {} after threshold filter (>= {})",
                ragRes.getEffectiveResults().size(), filteredResults.size(), scoreThreshold);

        Map<String, List<Map<String, Object>>> groupedByFile = new java.util.LinkedHashMap<>();
        Map<String, Double> fileMaxScore = new java.util.HashMap<>();
        for (Map<String, Object> res : filteredResults) {
            String fileName = extractFileName(res);
            groupedByFile.computeIfAbsent(fileName, k -> new java.util.ArrayList<>()).add(res);

            Object scoreObj = res.get("score");
            double score = (scoreObj instanceof Number) ? ((Number) scoreObj).doubleValue() : 0;
            fileMaxScore.merge(fileName, score, Math::max);
        }

        List<String> sortedFiles = groupedByFile.keySet().stream()
                .sorted((a, b) -> Double.compare(fileMaxScore.getOrDefault(b, 0.0),
                        fileMaxScore.getOrDefault(a, 0.0)))
                .collect(java.util.stream.Collectors.toList());

        StringBuilder sourcesBuilder = new StringBuilder();
        List<Map<String, Object>> sourceList = new java.util.ArrayList<>();
        int docIndex = 1;
        for (String fileName : sortedFiles) {
            List<Map<String, Object>> chunks = groupedByFile.get(fileName);
            double maxScore = fileMaxScore.getOrDefault(fileName, 0.0);
            sourcesBuilder.append(String.format("\n【参考资料 %d - 来源: %s (相关度: %.0f%%)】\n",
                    docIndex++, fileName, maxScore * 100));

            for (Map<String, Object> res : chunks) {
                Object content = res.get("content");
                if (content == null) {
                    continue;
                }
                sourcesBuilder.append(content).append("\n");
                sourceList.add(Map.of(
                        "fileName", fileName,
                        "content", content.toString(),
                        "score", res.getOrDefault("score", 0)));
            }
        }

        sendSources(emitter, sourceList);
        if (sourcesBuilder.length() == 0) {
            return "";
        }
        return "\n\n【参考知识库 / Reference Context】\n" +
                "(注：资料按相关度从高到低排列，请优先参考排名靠前的来源)\n" +
                sourcesBuilder;
    }

    private String extractFileName(Map<String, Object> res) {
        Object metadata = res.get("metadata");
        if (metadata instanceof Map) {
            @SuppressWarnings("unchecked")
            Map<String, Object> metaMap = (Map<String, Object>) metadata;
            Object fileNameObj = metaMap.get("file_name");
            return fileNameObj != null ? String.valueOf(fileNameObj) : "Unknown";
        }
        return "Unknown";
    }

    private void sendStatus(SseEmitter emitter, String status) {
        try {
            emitter.send(SseEmitter.event().name("status").data(status));
        } catch (Exception e) {
            log.warn("Failed to send status SSE", e);
        }
    }

    private void sendIntent(SseEmitter emitter, RagQueryResponse ragRes) {
        if (ragRes == null || ragRes.getIntent() == null) {
            return;
        }
        try {
            emitter.send(SseEmitter.event().data(objectMapper.writeValueAsString(Map.of("intent", ragRes.getIntent()))));
            log.info("Sent intent: {}", ragRes.getIntent());
        } catch (Exception e) {
            log.warn("Failed to send intent SSE", e);
        }
    }

    private void sendSources(SseEmitter emitter, List<Map<String, Object>> sourceList) {
        try {
            emitter.send(SseEmitter.event().name("sources").data(objectMapper.writeValueAsString(sourceList)));
        } catch (Exception e) {
            log.warn("Failed to send sources SSE", e);
        }
    }

    private String defaultRagInstructions() {
        return """
                [RAG Mode Active]
                You are a knowledge-grounded AI assistant. Follow these rules STRICTLY:

                [CORE RULES]
                1. You MUST answer ONLY based on the provided Reference Context below.
                2. If the context does NOT contain relevant information, reply: "抱歉，知识库中未找到相关信息。"
                3. Do NOT use any knowledge outside of the provided context. No guessing or fabricating.
                4. If the context is UNRELATED to the user's question, reply: "检索到的内容与您的问题不相关，暂时无法回答。"

                [MULTI-SOURCE HANDLING - CRITICAL]
                5. Reference materials are sorted by relevance (highest first). PRIORITIZE the top-ranked source.
                6. Do NOT mix or combine information from multiple unrelated documents.
                7. If different sources discuss different topics, use ONLY the one most relevant to the question.
                8. When citing, always mention which source (参考资料 1, 参考资料 2, etc.) you are referencing.

                [ANSWER GUIDELINES]
                - Quote or summarize accurately from the source.
                - Keep answers professional and concise.
                - When context contradicts your internal knowledge, prioritize the context.

                [End of Instructions]

                """;
    }

    public record RagPreparation(String systemPrompt, String contextAugmentation) {
    }
}
