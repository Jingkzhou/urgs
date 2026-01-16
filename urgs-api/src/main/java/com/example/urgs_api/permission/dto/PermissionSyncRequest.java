package com.example.urgs_api.permission.dto;

import java.util.List;

public class PermissionSyncRequest {
    private List<PermissionDTO> items;
    private MetaDTO meta;

    public List<PermissionDTO> getItems() {
        return items;
    }

    public void setItems(List<PermissionDTO> items) {
        this.items = items;
    }

    public MetaDTO getMeta() {
        return meta;
    }

    public void setMeta(MetaDTO meta) {
        this.meta = meta;
    }

    public static class MetaDTO {
        private String version;
        private String generatedAt;
        private String source;

        public String getVersion() {
            return version;
        }

        public void setVersion(String version) {
            this.version = version;
        }

        public String getGeneratedAt() {
            return generatedAt;
        }

        public void setGeneratedAt(String generatedAt) {
            this.generatedAt = generatedAt;
        }

        public String getSource() {
            return source;
        }

        public void setSource(String source) {
            this.source = source;
        }
    }
}
