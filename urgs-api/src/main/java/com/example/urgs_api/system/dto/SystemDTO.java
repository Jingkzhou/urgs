package com.example.urgs_api.system.dto;

import com.example.urgs_api.system.model.SysSystem;
import lombok.Data;

@Data
public class SystemDTO {
    private String id;
    private String name;
    private String protocol;
    private String clientId;
    private String callbackUrl;
    private String algorithm;
    private String network;
    private String status;
    private String icon;

    public SystemDTO() {
    }

    public SystemDTO(String id, String name, String protocol, String clientId, String callbackUrl, String algorithm,
            String network, String status, String icon) {
        this.id = id;
        this.name = name;
        this.protocol = protocol;
        this.clientId = clientId;
        this.callbackUrl = callbackUrl;
        this.algorithm = algorithm;
        this.network = network;
        this.status = status;
        this.icon = icon;
    }

    public static SystemDTO fromEntity(SysSystem e) {
        return new SystemDTO(
                e.getId() == null ? null : String.valueOf(e.getId()),
                e.getName(),
                e.getProtocol(),
                e.getClientId(),
                e.getCallbackUrl(),
                e.getAlgorithm(),
                e.getNetwork(),
                e.getStatus(),
                e.getIcon());
    }

    public SysSystem toEntity() {
        SysSystem c = new SysSystem();
        if (this.id != null) {
            try {
                c.setId(Long.parseLong(this.id));
            } catch (NumberFormatException ignored) {
                c.setId(null);
            }
        }
        c.setName(this.name);
        c.setProtocol(this.protocol);
        c.setClientId(this.clientId);
        c.setCallbackUrl(this.callbackUrl);
        c.setAlgorithm(this.algorithm);
        c.setNetwork(this.network);
        c.setStatus(this.status);
        c.setIcon(this.icon);
        return c;
    }
}
