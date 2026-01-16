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

    private static final int DEFAULT_CHUNK_SIZE = 2500; // Increased for more context
    private static final int OVERLAP_LINES = 30; // Increased overlap for SQL context

    public List<String> chunkCode(String code, String language) {
        if (code == null || code.isEmpty()) {
            return new ArrayList<>();
        }

        language = language.toLowerCase();

        return switch (language) {
            case "java" -> splitJavaLike(code);
            case "python" -> splitPython(code);
            case "sql" -> splitSql(code);
            default -> splitByLines(code);
        };
    }

    private List<String> splitJavaLike(String code) {
        return splitSmartly(code, "\\n\\s*}\\s*\\n", DEFAULT_CHUNK_SIZE);
    }

    private List<String> splitPython(String code) {
        return splitSmartly(code, "\\n(def|class)\\s+", DEFAULT_CHUNK_SIZE);
    }

    private List<String> splitSql(String code) {
        // Split by semicolons or GO statements, or major block boundaries
        return splitSmartly(code, ";\\s*\\n|\\n\\s*/\\s*\\n|\\n\\s*GO\\s*\\n", DEFAULT_CHUNK_SIZE);
    }

    private List<String> splitByLines(String code) {
        return splitSmartly(code, null, DEFAULT_CHUNK_SIZE);
    }

    private List<String> splitSmartly(String text, String splitPattern, int maxChars) {
        List<String> chunks = new ArrayList<>();
        if (splitPattern != null && text.contains(splitPattern.replace("\\n", "\n").replace("\\s*", ""))) {
            // If pattern exists, try to split by it but keep size in check
            // This is complex for a simple regex, so we'll use a hybrid approach:
            // Split by lines, but only 'commit' a chunk when we hit a boundary or size
            // limit.
        }

        String[] lines = text.split("\\n");
        StringBuilder currentChunk = new StringBuilder();
        List<String> overlapBuffer = new ArrayList<>();
        int currentSize = 0;

        for (int i = 0; i < lines.length; i++) {
            String line = lines[i];
            currentChunk.append(line).append("\n");
            currentSize += line.length() + 1;

            // Update overlap buffer
            overlapBuffer.add(line);
            if (overlapBuffer.size() > OVERLAP_LINES) {
                overlapBuffer.remove(0);
            }

            boolean isBoundary = false;
            if (splitPattern != null) {
                // Check if this line ends a block based on pattern (simplified)
                if (line.matches(".*;\\s*") || line.trim().equals("/") || line.trim().equalsIgnoreCase("GO")) {
                    isBoundary = true;
                }
            }

            // If we hit a boundary and have enough size, or we are way over size
            if ((isBoundary && currentSize > maxChars * 0.7) || currentSize > maxChars) {
                chunks.add(currentChunk.toString());
                currentChunk = new StringBuilder();
                currentSize = 0;
                // Start next chunk with overlap
                for (String ol : overlapBuffer) {
                    currentChunk.append(ol).append("\n");
                    currentSize += ol.length() + 1;
                }
            }
        }

        if (currentSize > OVERLAP_LINES * 10) { // Only add if it's more than just the overlap
            chunks.add(currentChunk.toString());
        } else if (chunks.isEmpty() && currentChunk.length() > 0) {
            chunks.add(currentChunk.toString());
        }

        return chunks;
    }

}
