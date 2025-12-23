package com.example.urgs_api.system.dto;

import lombok.Data;

@Data
public class SystemRequest {
    private String name;
    private String protocol;
    private String clientId;
    private String callbackUrl;
    private String algorithm;
    private String network;
    private String status;
    private String icon;
}
