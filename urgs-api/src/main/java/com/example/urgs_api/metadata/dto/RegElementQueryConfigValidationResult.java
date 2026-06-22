package com.example.urgs_api.metadata.dto;

import lombok.Data;

import java.util.ArrayList;
import java.util.List;

@Data
public class RegElementQueryConfigValidationResult {
    private boolean valid;
    private List<String> errors = new ArrayList<>();
    private List<String> warnings = new ArrayList<>();

    public void addError(String message) {
        this.errors.add(message);
        this.valid = false;
    }

    public void addWarning(String message) {
        this.warnings.add(message);
    }

    public static RegElementQueryConfigValidationResult ok() {
        RegElementQueryConfigValidationResult result = new RegElementQueryConfigValidationResult();
        result.setValid(true);
        return result;
    }
}
