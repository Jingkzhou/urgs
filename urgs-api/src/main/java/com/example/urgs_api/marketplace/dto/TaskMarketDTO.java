package com.example.urgs_api.marketplace.dto;

import com.example.urgs_api.marketplace.model.WorkTask;
import lombok.Data;

@Data
public class TaskMarketDTO extends WorkTask {
    private String workTitle;
    private String publisherName;
    private String publisherAvatar;
    private Integer applicationCount;
}
