package com.example.urgs_api.metadata.dto;

import lombok.Data;
import java.time.LocalDate;
import java.util.List;

@Data
public class DeleteReqDTO {
    private Long id;
    private String idStr; // For String IDs (CodeDirectory)
    private List<Long> ids; // For batch delete
    private List<String> idStrs; // For batch String IDs

    private String reqId;
    private LocalDate plannedDate;
    private String changeDescription;
}
