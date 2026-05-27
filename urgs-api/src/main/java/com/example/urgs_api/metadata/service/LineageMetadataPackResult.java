package com.example.urgs_api.metadata.service;

import java.nio.file.Path;
import java.time.LocalDateTime;

public record LineageMetadataPackResult(
        String status,
        Path path,
        String hash,
        int tableCount,
        int fieldCount,
        LocalDateTime generatedAt,
        String message) {

    public boolean hasFile() {
        return path != null;
    }
}
