package com.example.urgs_api.metadata.dto;

import com.example.urgs_api.metadata.model.CodeDirectory;
import com.example.urgs_api.metadata.model.RegElement;
import lombok.Data;

import java.util.ArrayList;
import java.util.List;

@Data
public class RegElementMaintenanceDTO {

    private RegElement element;
    private List<CodeChangeDTO> codeChanges = new ArrayList<>();

    @Data
    public static class CodeChangeDTO {
        private String operation;
        private CodeDirectory data;
    }
}
