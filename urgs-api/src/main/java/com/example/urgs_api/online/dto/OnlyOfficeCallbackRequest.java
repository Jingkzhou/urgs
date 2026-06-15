package com.example.urgs_api.online.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

/**
 * ONLYOFFICE 回调请求
 */
@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class OnlyOfficeCallbackRequest {

    private Integer status;
    private String url;
    private String key;
    private Object users;
}
