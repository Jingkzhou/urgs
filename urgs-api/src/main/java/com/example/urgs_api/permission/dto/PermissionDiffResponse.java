package com.example.urgs_api.permission.dto;

import java.util.List;

public class PermissionDiffResponse {
    private List<PermissionDTO> added;
    private List<PermissionDTO> modified;
    private List<PermissionDTO> removed;
    private boolean hasChanges;
    private List<PermissionDTO> current;

    public PermissionDiffResponse() {
    }

    public PermissionDiffResponse(List<PermissionDTO> added, List<PermissionDTO> modified,
            List<PermissionDTO> removed) {
        this.added = added;
        this.modified = modified;
        this.removed = removed;
        this.hasChanges = !added.isEmpty() || !modified.isEmpty() || !removed.isEmpty();
    }

    public PermissionDiffResponse(List<PermissionDTO> added, List<PermissionDTO> modified,
            List<PermissionDTO> removed, List<PermissionDTO> current) {
        this(added, modified, removed);
        this.current = current;
    }

    public List<PermissionDTO> getAdded() {
        return added;
    }

    public void setAdded(List<PermissionDTO> added) {
        this.added = added;
    }

    public List<PermissionDTO> getModified() {
        return modified;
    }

    public void setModified(List<PermissionDTO> modified) {
        this.modified = modified;
    }

    public List<PermissionDTO> getRemoved() {
        return removed;
    }

    public void setRemoved(List<PermissionDTO> removed) {
        this.removed = removed;
    }

    public boolean isHasChanges() {
        return hasChanges;
    }

    public void setHasChanges(boolean hasChanges) {
        this.hasChanges = hasChanges;
    }

    public List<PermissionDTO> getCurrent() {
        return current;
    }

    public void setCurrent(List<PermissionDTO> current) {
        this.current = current;
    }
}
