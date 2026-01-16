package com.example.urgs_api.metadata.dto;

import lombok.Data;

@Data
public class ImportResultDTO {
    private int deleted;
    private int inserted;
    private int failed;

    public ImportResultDTO() {
    }

    public ImportResultDTO(int deleted, int inserted, int failed) {
        this.deleted = deleted;
        this.inserted = inserted;
        this.failed = failed;
    }
}
