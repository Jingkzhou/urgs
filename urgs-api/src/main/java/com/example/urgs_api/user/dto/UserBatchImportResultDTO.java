package com.example.urgs_api.user.dto;

public class UserBatchImportResultDTO {
    private int inserted;
    private int updated;
    private int skipped;

    public int getInserted() {
        return inserted;
    }

    public void setInserted(int inserted) {
        this.inserted = inserted;
    }

    public int getUpdated() {
        return updated;
    }

    public void setUpdated(int updated) {
        this.updated = updated;
    }

    public int getSkipped() {
        return skipped;
    }

    public void setSkipped(int skipped) {
        this.skipped = skipped;
    }

    public int getProcessed() {
        return inserted + updated;
    }
}
