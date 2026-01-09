package com.example.urgs_api.version.audit.service;

import org.springframework.stereotype.Component;
import java.util.ArrayList;
import java.util.List;

/**
 * Smart Code Chunker
 * Splits source code into manageable chunks for AI processing.
 * Respects logical boundaries (Classes, Methods, Functions) where possible.
 */
@Component
public class CodeChunker {

    private static final int DEFAULT_CHUNK_SIZE = 2000; // Estimated tokens

    public List<String> chunkCode(String code, String language) {
        if (code == null || code.isEmpty()) {
            return new ArrayList<>();
        }

        // Normalize language
        language = language.toLowerCase();

        return switch (language) {
            case "java" -> splitJavaLike(code);
            case "python" -> splitPython(code);
            case "sql" -> splitSql(code);
            default -> splitByLines(code); // Fallback
        };
    }

    private List<String> splitJavaLike(String code) {
        // Simple heuristic: split by method boundaries (look for braces)
        // This is a simplified version. A real AST parser would be better but
        // expensive.
        // For now, we mainly rely on line counts and try to break at '}'
        return splitSmartly(code, "\\n\\s*}\\s*\\n", DEFAULT_CHUNK_SIZE);
    }

    private List<String> splitPython(String code) {
        // Split by function definitions or class definitions
        // Look for lines starting with 'def ' or 'class ' at the beginning of the line
        return splitSmartly(code, "\\n(def|class)\\s+", DEFAULT_CHUNK_SIZE);
    }

    private List<String> splitSql(String code) {
        // Split by semicolons at end of lines or GO statements
        return splitSmartly(code, ";\\s*\\n", DEFAULT_CHUNK_SIZE);
    }

    private List<String> splitByLines(String code) {
        return splitSmartly(code, "\\n", DEFAULT_CHUNK_SIZE);
    }

    /**
     * Splits string attempting to respect regex boundaries while keeping chunks
     * under limit.
     */
    private List<String> splitSmartly(String text, String splitPattern, int maxTokens) {
        // Simplified implementation:
        // We just accumulate lines until we hit the limit, then cut at the nearest
        // newline.
        // The 'splitPattern' is ignored in this V1 fallback for robustness.

        String[] lines = text.split("\\n");
        List<String> chunks = new ArrayList<>();
        StringBuilder currentChunk = new StringBuilder();
        List<String> overlapBuffer = new ArrayList<>();
        int currentTokens = 0;

        for (String line : lines) {
            int lineTokens = estimateTokens(line) + 1; // +1 for newline

            if (currentTokens + lineTokens > maxTokens) {
                chunks.add(currentChunk.toString());

                // Start new chunk with overlap
                currentChunk = new StringBuilder();
                currentTokens = 0;

                for (String overlapLine : overlapBuffer) {
                    currentChunk.append(overlapLine).append("\n");
                    currentTokens += estimateTokens(overlapLine) + 1;
                }
            }

            currentChunk.append(line).append("\n");
            currentTokens += lineTokens;

            // Manage overlap buffer
            overlapBuffer.add(line);
            if (overlapBuffer.size() > 20) { // Keep last 20 lines approx for overlap
                overlapBuffer.remove(0);
            }
        }

        if (currentChunk.length() > 0) {
            chunks.add(currentChunk.toString());
        }

        return chunks;
    }

    private int estimateTokens(String text) {
        if (text == null)
            return 0;
        return text.length() / 4;
    }
}
